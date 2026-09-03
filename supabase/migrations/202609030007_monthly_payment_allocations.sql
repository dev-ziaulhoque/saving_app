begin;

alter table public.profiles
  add column if not exists savings_start_date date;

update public.profiles
set savings_start_date = date_trunc('month', created_at)::date
where role = 'user' and savings_start_date is null;

create table if not exists public.payment_allocations (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.transactions(id) on delete restrict,
  user_id uuid not null references public.profiles(id) on delete restrict,
  allocation_month date not null,
  amount numeric(14,2) not null check (amount > 0),
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'rejected')),
  created_at timestamptz not null default now(),
  unique (transaction_id, allocation_month)
);

create index if not exists payment_allocations_user_month_idx
on public.payment_allocations(user_id, allocation_month);

alter table public.payment_allocations enable row level security;

drop policy if exists "users_read_own_payment_allocations" on public.payment_allocations;
create policy "users_read_own_payment_allocations"
on public.payment_allocations for select to authenticated
using (user_id = auth.uid() or public.is_admin());

-- Convert legacy single-month transactions into one allocation without
-- changing their balances or approval state.
insert into public.payment_allocations (
  transaction_id, user_id, allocation_month, amount, status, created_at
)
select
  t.id, t.user_id, date_trunc('month', t.month_year)::date,
  t.amount, t.status, t.created_at
from public.transactions t
where t.month_year is not null and t.amount > 0
on conflict (transaction_id, allocation_month) do nothing;

create or replace function public.create_payment_request(
  payment_phone text,
  receipt_path text,
  allocation_months date[],
  allocation_amounts numeric[]
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  transaction_id uuid;
  total_amount numeric;
  first_month date;
  last_month date;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'user' and status = 'active'
  ) then raise exception 'Only active members can submit payments'; end if;
  if cardinality(allocation_months) is null
     or cardinality(allocation_months) = 0
     or cardinality(allocation_months) > 24
     or cardinality(allocation_months) <> cardinality(allocation_amounts) then
    raise exception 'Select between 1 and 24 valid payment months';
  end if;
  if exists (select 1 from unnest(allocation_amounts) a where a <= 0) then
    raise exception 'Every allocation amount must be positive';
  end if;
  if (select count(*) from unnest(allocation_months)) <>
     (select count(distinct date_trunc('month', m)::date) from unnest(allocation_months) m) then
    raise exception 'Duplicate payment months are not allowed';
  end if;

  select sum(a), min(date_trunc('month', m)::date),
         max(date_trunc('month', m)::date)
  into total_amount, first_month, last_month
  from unnest(allocation_months, allocation_amounts) as x(m, a);

  insert into public.transactions (
    user_id, amount, month, month_year, phone_number,
    receipt_url, status, entry_source
  ) values (
    auth.uid(), total_amount,
    to_char(first_month, 'Mon YYYY') ||
      case when first_month <> last_month
        then ' - ' || to_char(last_month, 'Mon YYYY') else '' end,
    first_month, nullif(trim(payment_phone), ''),
    nullif(trim(receipt_path), ''), 'pending', 'user_request'
  ) returning id into transaction_id;

  insert into public.payment_allocations (
    transaction_id, user_id, allocation_month, amount, status
  )
  select transaction_id, auth.uid(), date_trunc('month', m)::date, a, 'pending'
  from unnest(allocation_months, allocation_amounts) as x(m, a);

  return transaction_id;
end;
$$;

revoke all on function public.create_payment_request(text, text, date[], numeric[])
from public, anon;
grant execute on function public.create_payment_request(text, text, date[], numeric[])
to authenticated;

create or replace function public.sync_payment_allocation_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status is distinct from old.status then
    update public.payment_allocations
    set status = new.status
    where transaction_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists sync_payment_allocation_status on public.transactions;
create trigger sync_payment_allocation_status
after update of status on public.transactions
for each row execute function public.sync_payment_allocation_status();

create or replace function public.add_manual_multi_month_payment_admin(
  target_user_id uuid,
  amount_per_month numeric,
  first_payment_month date,
  payment_month_count integer,
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
  total_amount numeric := amount_per_month * payment_month_count;
  last_month date := (date_trunc('month', first_payment_month) +
                      make_interval(months => payment_month_count - 1))::date;
begin
  if not public.is_admin() then raise exception 'Only admin can add manual payments'; end if;
  if amount_per_month <= 0 or payment_month_count not between 1 and 24 then
    raise exception 'Use a positive monthly amount and 1-24 months';
  end if;
  if nullif(trim(proof_path), '') is null or length(trim(payment_note)) < 5 then
    raise exception 'Proof and a meaningful note are required';
  end if;

  insert into public.transactions (
    user_id, amount, month, month_year, status, confirmed_by, confirmed_at,
    note, receipt_url, entry_source, manual_proof_url
  ) values (
    target_user_id, total_amount,
    to_char(first_payment_month, 'Mon YYYY') ||
      case when payment_month_count > 1 then ' - ' || to_char(last_month, 'Mon YYYY') else '' end,
    date_trunc('month', first_payment_month)::date, 'confirmed', auth.uid(), now(),
    '[ADMIN MANUAL] ' || trim(payment_note), trim(proof_path),
    'admin_manual', trim(proof_path)
  ) returning id into transaction_id;

  insert into public.payment_allocations (
    transaction_id, user_id, allocation_month, amount, status
  )
  select transaction_id, target_user_id, month::date, amount_per_month, 'confirmed'
  from generate_series(
    date_trunc('month', first_payment_month), last_month, interval '1 month'
  ) month;

  update public.profiles
  set total_saved = coalesce(total_saved, 0) + total_amount,
      dues = greatest(coalesce(dues, 0) - total_amount, 0),
      updated_at = now()
  where id = target_user_id and role = 'user';
  return transaction_id;
end;
$$;

revoke all on function public.add_manual_multi_month_payment_admin(uuid, numeric, date, integer, text, text)
from public, anon;
grant execute on function public.add_manual_multi_month_payment_admin(uuid, numeric, date, integer, text, text)
to authenticated;

create or replace function public.get_user_payment_calendar(
  target_user_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  requested_user uuid := coalesce(target_user_id, auth.uid());
  start_month date;
  end_month date;
  monthly numeric;
  result jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if requested_user <> auth.uid() and not public.is_admin() then
    raise exception 'Not allowed';
  end if;

  select coalesce(savings_start_date, date_trunc('month', created_at)::date),
         coalesce(monthly_amount, 0)
  into start_month, monthly
  from public.profiles where id = requested_user;
  end_month := greatest(date_trunc('month', current_date)::date,
    coalesce((select max(allocation_month) from public.payment_allocations
              where user_id = requested_user), current_date));

  select coalesce(jsonb_agg(jsonb_build_object(
    'month', series.month,
    'required', monthly,
    'confirmed', coalesce(a.confirmed, 0),
    'pending', coalesce(a.pending, 0),
    'status', case
      when coalesce(a.confirmed, 0) >= monthly and monthly > 0 then 'paid'
      when coalesce(a.confirmed, 0) > 0 then 'partial'
      when coalesce(a.pending, 0) > 0 then 'pending'
      when series.month > date_trunc('month', current_date)::date then 'future'
      else 'due' end
  ) order by series.month), '[]'::jsonb)
  into result
  from generate_series(start_month, end_month, interval '1 month') series(month)
  left join (
    select allocation_month,
      sum(amount) filter (where status = 'confirmed') confirmed,
      sum(amount) filter (where status = 'pending') pending
    from public.payment_allocations
    where user_id = requested_user
    group by allocation_month
  ) a on a.allocation_month = series.month::date;

  return result;
end;
$$;

revoke all on function public.get_user_payment_calendar(uuid) from public, anon;
grant execute on function public.get_user_payment_calendar(uuid) to authenticated;

create or replace function public.set_user_savings_start_admin(
  target_user_id uuid,
  start_date date
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then raise exception 'Only admin can update start date'; end if;
  update public.profiles
  set savings_start_date = date_trunc('month', start_date)::date,
      updated_at = now()
  where id = target_user_id and role = 'user';
end;
$$;

revoke all on function public.set_user_savings_start_admin(uuid, date)
from public, anon;
grant execute on function public.set_user_savings_start_admin(uuid, date)
to authenticated;

-- Upgrade the existing live report so member dues are calculated from the
-- month ledger while investment/profit/expense logic remains centralized.
do $$
begin
  if to_regprocedure('public.get_live_foundation_report_base()') is null
     and to_regprocedure('public.get_live_foundation_report()') is not null then
    execute 'alter function public.get_live_foundation_report() rename to get_live_foundation_report_base';
  end if;
end;
$$;

create or replace function public.get_live_foundation_report()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  report jsonb;
  members jsonb;
  required_total numeric;
  collected_total numeric;
  due_total numeric;
  profit_total numeric;
  expense_total numeric;
  invested_total numeric;
begin
  report := public.get_live_foundation_report_base();

  with member_totals as (
    select p.id, p.name, coalesce(p.monthly_amount, 0) monthly_amount,
      coalesce(p.total_saved, 0) paid,
      greatest(
        coalesce(p.dues, 0),
        greatest(
          ((extract(year from age(date_trunc('month', current_date),
              coalesce(p.savings_start_date, date_trunc('month', p.created_at)::date))) * 12
            + extract(month from age(date_trunc('month', current_date),
              coalesce(p.savings_start_date, date_trunc('month', p.created_at)::date))) + 1)
            * coalesce(p.monthly_amount, 0)) - coalesce(a.confirmed, 0), 0
        )
      ) calculated_due
    from public.profiles p
    left join (
      select user_id, sum(amount) confirmed
      from public.payment_allocations
      where status = 'confirmed'
        and allocation_month <= date_trunc('month', current_date)::date
      group by user_id
    ) a on a.user_id = p.id
    where p.role = 'user' and p.status = 'active'
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'user_id', id, 'name', name, 'monthly_amount', monthly_amount,
           'paid', paid, 'due', calculated_due,
           'required', paid + calculated_due,
           'payments', coalesce((
             select jsonb_agg(jsonb_build_object(
               'month', pa.allocation_month, 'amount', pa.amount,
               'status', pa.status
             ) order by pa.allocation_month)
             from public.payment_allocations pa where pa.user_id = member_totals.id
           ), '[]'::jsonb)
         ) order by name), '[]'::jsonb),
         coalesce(sum(paid + calculated_due), 0),
         coalesce(sum(paid), 0), coalesce(sum(calculated_due), 0)
  into members, required_total, collected_total, due_total
  from member_totals;

  profit_total := coalesce((report #>> '{summary,total_profit}')::numeric, 0);
  expense_total := coalesce((report #>> '{summary,total_expenses}')::numeric, 0);
  invested_total := coalesce((report #>> '{summary,total_invested}')::numeric, 0);
  report := jsonb_set(report, '{members}', members);
  report := jsonb_set(report, '{summary,total_required}', to_jsonb(required_total));
  report := jsonb_set(report, '{summary,total_collected}', to_jsonb(collected_total));
  report := jsonb_set(report, '{summary,total_due}', to_jsonb(due_total));
  report := jsonb_set(report, '{summary,foundation_total}',
    to_jsonb(collected_total + profit_total - expense_total));
  report := jsonb_set(report, '{summary,available_cash}',
    to_jsonb(collected_total + profit_total - expense_total - invested_total));
  return report;
end;
$$;

revoke all on function public.get_live_foundation_report() from public, anon;
grant execute on function public.get_live_foundation_report() to authenticated;

commit;

notify pgrst, 'reload schema';
