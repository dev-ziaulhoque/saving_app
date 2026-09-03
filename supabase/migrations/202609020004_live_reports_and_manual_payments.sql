begin;

-- Manual admin entries are distinguished from user-submitted requests and
-- always carry a private proof file path.
alter table public.transactions
  add column if not exists entry_source text not null default 'user_request'
    check (entry_source in ('user_request', 'admin_manual')),
  add column if not exists manual_proof_url text;

drop policy if exists "admins_upload_manual_payment_proofs" on storage.objects;
create policy "admins_upload_manual_payment_proofs"
on storage.objects for insert to authenticated
with check (bucket_id = 'receipts' and public.is_admin());

create or replace function public.add_manual_payment_admin(
  target_user_id uuid,
  payment_amount numeric,
  payment_month date,
  proof_path text,
  payment_note text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  transaction_id uuid;
begin
  if not public.is_admin() then
    raise exception 'Only admin can add a manual payment';
  end if;
  if payment_amount <= 0 then
    raise exception 'Payment amount must be positive';
  end if;
  if nullif(trim(proof_path), '') is null or length(trim(payment_note)) < 5 then
    raise exception 'Proof and a meaningful note are required';
  end if;
  if not exists (
    select 1 from public.profiles
    where id = target_user_id and role = 'user' and status = 'active'
  ) then
    raise exception 'Active user was not found';
  end if;

  insert into public.transactions (
    user_id, amount, month, month_year, status,
    confirmed_by, confirmed_at, note, receipt_url,
    entry_source, manual_proof_url
  ) values (
    target_user_id, payment_amount,
    to_char(payment_month, 'FMMonth YYYY'),
    date_trunc('month', payment_month)::date, 'confirmed',
    auth.uid(), now(), '[ADMIN MANUAL] ' || trim(payment_note), trim(proof_path),
    'admin_manual', trim(proof_path)
  ) returning id into transaction_id;

  update public.profiles
  set total_saved = coalesce(total_saved, 0) + payment_amount,
      dues = greatest(coalesce(dues, 0) - payment_amount, 0),
      updated_at = now()
  where id = target_user_id;

  return transaction_id;
end;
$$;

revoke all on function public.add_manual_payment_admin(uuid, numeric, date, text, text)
from public, anon;
grant execute on function public.add_manual_payment_admin(uuid, numeric, date, text, text)
to authenticated;

-- App users, including admins, cannot quietly alter/delete a confirmed manual
-- entry. Database owners can still perform an explicit audited correction.
create or replace function public.protect_manual_payment_evidence()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('postgres', 'supabase_admin') or auth.role() = 'service_role' then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  if old.entry_source = 'admin_manual' then
    raise exception 'Confirmed manual payments are immutable; create a correction entry';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

drop trigger if exists protect_manual_payment_evidence on public.transactions;
create trigger protect_manual_payment_evidence
before update or delete on public.transactions
for each row execute function public.protect_manual_payment_evidence();

-- Always-current all-time report. There is no publish step and no snapshot
-- dependency: every refresh reflects the latest approved balances/accounting.
create or replace function public.get_live_foundation_report()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  members jsonb;
  investments_data jsonb;
  profits_data jsonb;
  expenses_data jsonb;
  total_required numeric;
  total_collected numeric;
  total_due numeric;
  total_invested numeric;
  total_profit numeric;
  total_expenses numeric;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
           'user_id', id, 'name', name,
           'required', coalesce(total_saved, 0) + coalesce(dues, 0),
           'paid', coalesce(total_saved, 0), 'due', coalesce(dues, 0),
           'monthly_amount', coalesce(monthly_amount, 0)
         ) order by name), '[]'::jsonb),
         coalesce(sum(coalesce(total_saved, 0) + coalesce(dues, 0)), 0),
         coalesce(sum(coalesce(total_saved, 0)), 0),
         coalesce(sum(coalesce(dues, 0)), 0)
  into members, total_required, total_collected, total_due
  from public.profiles
  where role = 'user' and status = 'active';

  select coalesce(jsonb_agg(jsonb_build_object(
           'id', i.id, 'title', i.title, 'amount', i.amount,
           'invested_at', i.invested_at, 'status', i.status, 'notes', i.notes,
           'profit_total', coalesce(p.total, 0),
           'profits', coalesce(p.items, '[]'::jsonb)
         ) order by i.invested_at desc), '[]'::jsonb),
         coalesce(sum(i.amount) filter (where i.status = 'active'), 0)
  into investments_data, total_invested
  from public.investments i
  left join lateral (
    select sum(ip.amount) as total,
           jsonb_agg(jsonb_build_object(
             'id', ip.id, 'amount', ip.amount, 'profit_month', ip.profit_month,
             'received_at', ip.received_at, 'notes', ip.notes
           ) order by ip.profit_month desc) as items
    from public.investment_profits ip where ip.investment_id = i.id
  ) p on true;

  select coalesce(jsonb_agg(jsonb_build_object(
           'id', ip.id, 'investment_id', ip.investment_id,
           'investment_title', i.title, 'amount', ip.amount,
           'profit_month', ip.profit_month, 'received_at', ip.received_at,
           'notes', ip.notes
         ) order by ip.profit_month desc), '[]'::jsonb), coalesce(sum(ip.amount), 0)
  into profits_data, total_profit
  from public.investment_profits ip
  join public.investments i on i.id = ip.investment_id;

  select coalesce(jsonb_agg(to_jsonb(e) - array['created_by','created_at']
           order by e.expense_date desc), '[]'::jsonb), coalesce(sum(e.amount), 0)
  into expenses_data, total_expenses
  from public.foundation_expenses e;

  return jsonb_build_object(
    'report_month', date_trunc('month', current_date)::date,
    'generated_at', now(), 'scope', 'all_time',
    'members', members, 'investments', investments_data,
    'profits', profits_data, 'expenses', expenses_data,
    'summary', jsonb_build_object(
      'total_required', total_required, 'total_collected', total_collected,
      'total_due', total_due, 'total_invested', total_invested,
      'total_profit', total_profit, 'total_expenses', total_expenses,
      'foundation_total', total_collected + total_profit - total_expenses,
      'available_cash', total_collected + total_profit - total_expenses - total_invested
    )
  );
end;
$$;

revoke all on function public.get_live_foundation_report() from public, anon;
grant execute on function public.get_live_foundation_report() to authenticated;

commit;
