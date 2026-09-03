begin;

-- Remove the abandoned manual-ledger table if an earlier draft was executed.
drop table if exists public.member_monthly_accounts cascade;

create table if not exists public.investments (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  amount numeric(14,2) not null check (amount > 0),
  invested_at date not null,
  status text not null default 'active' check (status in ('active', 'closed')),
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.investment_profits (
  id uuid primary key default gen_random_uuid(),
  investment_id uuid not null references public.investments(id) on delete cascade,
  amount numeric(14,2) not null check (amount >= 0),
  profit_month date not null,
  received_at date not null default current_date,
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  unique (investment_id, profit_month)
);

create table if not exists public.foundation_expenses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  amount numeric(14,2) not null check (amount > 0),
  expense_date date not null,
  category text not null default 'general',
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.foundation_report_snapshots (
  report_month date primary key,
  report_data jsonb not null,
  is_published boolean not null default false,
  published_at timestamptz,
  published_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.investments enable row level security;
alter table public.investment_profits enable row level security;
alter table public.foundation_expenses enable row level security;
alter table public.foundation_report_snapshots enable row level security;

drop policy if exists "authenticated_read_investments" on public.investments;
create policy "authenticated_read_investments" on public.investments
for select to authenticated using (true);
drop policy if exists "admin_manage_investments" on public.investments;
create policy "admin_manage_investments" on public.investments
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "authenticated_read_profits" on public.investment_profits;
create policy "authenticated_read_profits" on public.investment_profits
for select to authenticated using (true);
drop policy if exists "admin_manage_profits" on public.investment_profits;
create policy "admin_manage_profits" on public.investment_profits
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "authenticated_read_expenses" on public.foundation_expenses;
create policy "authenticated_read_expenses" on public.foundation_expenses
for select to authenticated using (true);
drop policy if exists "admin_manage_expenses" on public.foundation_expenses;
create policy "admin_manage_expenses" on public.foundation_expenses
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "users_read_published_reports" on public.foundation_report_snapshots;
create policy "users_read_published_reports" on public.foundation_report_snapshots
for select to authenticated
using (is_published or public.is_admin());
drop policy if exists "admins_manage_reports" on public.foundation_report_snapshots;
create policy "admins_manage_reports" on public.foundation_report_snapshots
for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Clean only the deterministic demo rows from the earlier draft, if present.
delete from public.investment_profits
where id in ('00000000-0000-0000-0000-000000002061', '00000000-0000-0000-0000-000000002071');
delete from public.foundation_expenses
where id = '00000000-0000-0000-0000-000000002072';
delete from public.investments
where id = '00000000-0000-0000-0000-000000002026';
delete from public.foundation_report_snapshots
where report_month = '2026-07-01'
  and report_data -> 'members' @> '[{"name":"মো ফয়সাল ইসলাম"}]'::jsonb;

create or replace function public.publish_foundation_report(target_month date)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  month_start date := date_trunc('month', target_month)::date;
  month_end date := (date_trunc('month', target_month) + interval '1 month - 1 day')::date;
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
  report jsonb;
begin
  if not public.is_admin() then
    raise exception 'Only admin can publish foundation reports';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
           'user_id', id, 'name', name, 'phone', phone,
           'required', total_saved + dues,
           'paid', total_saved, 'due', dues
         ) order by name), '[]'::jsonb),
         coalesce(sum(total_saved + dues), 0),
         coalesce(sum(total_saved), 0),
         coalesce(sum(dues), 0)
  into members, total_required, total_collected, total_due
  from public.profiles
  where role = 'user' and status = 'active';

  select coalesce(jsonb_agg(to_jsonb(i) - array['created_by','created_at','updated_at']
         order by i.invested_at), '[]'::jsonb),
         coalesce(sum(i.amount) filter (where i.status = 'active'), 0)
  into investments_data, total_invested
  from public.investments i where i.invested_at <= month_end;

  select coalesce(jsonb_agg(jsonb_build_object(
           'id', p.id, 'investment_id', p.investment_id,
           'investment_title', i.title, 'amount', p.amount,
           'profit_month', p.profit_month, 'received_at', p.received_at,
           'notes', p.notes
         ) order by p.profit_month), '[]'::jsonb), coalesce(sum(p.amount), 0)
  into profits_data, total_profit
  from public.investment_profits p
  join public.investments i on i.id = p.investment_id
  where p.profit_month <= month_start;

  select coalesce(jsonb_agg(to_jsonb(e) - array['created_by','created_at']
         order by e.expense_date), '[]'::jsonb), coalesce(sum(e.amount), 0)
  into expenses_data, total_expenses
  from public.foundation_expenses e where e.expense_date <= month_end;

  report := jsonb_build_object(
    'report_month', month_start, 'members', members,
    'investments', investments_data, 'profits', profits_data,
    'expenses', expenses_data,
    'summary', jsonb_build_object(
      'total_required', total_required, 'total_collected', total_collected,
      'total_due', total_due, 'total_invested', total_invested,
      'total_profit', total_profit, 'total_expenses', total_expenses,
      'foundation_total', total_collected + total_profit - total_expenses,
      'available_cash', total_collected + total_profit - total_expenses - total_invested
    )
  );

  insert into public.foundation_report_snapshots (
    report_month, report_data, is_published, published_at, published_by, updated_at
  ) values (month_start, report, true, now(), auth.uid(), now())
  on conflict (report_month) do update set
    report_data = excluded.report_data, is_published = true,
    published_at = now(), published_by = auth.uid(), updated_at = now();
  return report;
end;
$$;

revoke all on function public.publish_foundation_report(date) from public, anon;
grant execute on function public.publish_foundation_report(date) to authenticated;

-- Extend audit coverage to the accounting module.
do $$
declare table_name text;
begin
  if to_regprocedure('public.capture_audit_log()') is not null then
    foreach table_name in array array['investments','investment_profits','foundation_expenses','foundation_report_snapshots'] loop
      execute format('drop trigger if exists audit_%I on public.%I', table_name, table_name);
      execute format('create trigger audit_%I after insert or update or delete on public.%I for each row execute function public.capture_audit_log()', table_name, table_name);
    end loop;
  else
    raise notice 'capture_audit_log() is unavailable; accounting audit triggers were skipped. Run migration 202609020002 first to enable them.';
  end if;
end;
$$;

commit;
