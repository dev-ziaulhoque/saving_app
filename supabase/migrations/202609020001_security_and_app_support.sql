begin;

-- RLS may evaluate this helper before signup has produced a session.
-- For anon callers auth.uid() is null, so the helper safely returns false.
grant execute on function public.is_admin() to anon, authenticated;

-- Keep client-supplied signup metadata from creating privileged users.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, name, phone, role, status)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', 'Unknown'),
    new.raw_user_meta_data ->> 'phone',
    'user',
    'pending'
  );
  return new;
end;
$$;

-- A regular user may edit profile fields, but never privilege or balances.
create or replace function public.protect_profile_sensitive_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if current_user in ('postgres', 'supabase_admin')
     or auth.role() = 'service_role'
     or public.is_admin() then
    return new;
  end if;

  if new.role is distinct from old.role
     or new.status is distinct from old.status
     or new.monthly_amount is distinct from old.monthly_amount
     or new.total_saved is distinct from old.total_saved
     or new.dues is distinct from old.dues then
    raise exception 'You cannot update protected profile fields';
  end if;
  return new;
end;
$$;

drop trigger if exists protect_profile_sensitive_fields
  on public.profiles;
create trigger protect_profile_sensitive_fields
before update on public.profiles
for each row execute function public.protect_profile_sensitive_fields();

-- Add fields used by the payment-request flow.
alter table public.transactions
  add column if not exists phone_number text,
  add column if not exists receipt_url text;

-- A user can create only a pending payment request for their own account.
drop policy if exists "users_insert_own_payment_requests"
  on public.transactions;
create policy "users_insert_own_payment_requests"
on public.transactions
for insert
to authenticated
with check (
  auth.uid() = user_id
  and status = 'pending'
  and confirmed_by is null
  and confirmed_at is null
);

-- Private receipts: owner uploads; owner and admin can read.
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do update set public = false;

drop policy if exists "users_upload_own_receipts" on storage.objects;
create policy "users_upload_own_receipts"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'receipts'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "owners_and_admins_read_receipts" on storage.objects;
create policy "owners_and_admins_read_receipts"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'receipts'
  and (
    auth.uid()::text = (storage.foldername(name))[1]
    or public.is_admin()
  )
);

-- Return only the active admin id needed to start a user-to-admin chat.
create or replace function public.get_admin_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id
  from public.profiles
  where role = 'admin' and status = 'active'
  order by created_at
  limit 1;
$$;
revoke all on function public.get_admin_id() from public, anon;
grant execute on function public.get_admin_id() to authenticated;

-- Per-user read state also works correctly for broadcast notifications.
create table if not exists public.notification_reads (
  notification_id uuid not null
    references public.notifications(id) on delete cascade,
  user_id uuid not null
    references public.profiles(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (notification_id, user_id)
);
alter table public.notification_reads enable row level security;

drop policy if exists "users_read_own_notification_state"
  on public.notification_reads;
create policy "users_read_own_notification_state"
on public.notification_reads
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "users_create_own_notification_state"
  on public.notification_reads;
create policy "users_create_own_notification_state"
on public.notification_reads
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "users_update_own_notification_state"
  on public.notification_reads;
create policy "users_update_own_notification_state"
on public.notification_reads
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Do not expose the admin chat list RPC to non-admin callers.
create or replace function public.get_admin_chat_list()
returns table (
  user_id uuid,
  user_name text,
  last_msg text,
  last_time timestamptz,
  unread_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Only admin can view the chat list';
  end if;

  return query
  select
    p.id,
    p.name,
    m.text,
    m.created_at,
    count(*) filter (
      where not m2.is_read and m2.receiver_id = auth.uid()
    )::bigint
  from public.profiles p
  join lateral (
    select msg.text, msg.created_at
    from public.messages msg
    where msg.sender_id = p.id or msg.receiver_id = p.id
    order by msg.created_at desc
    limit 1
  ) m on true
  left join public.messages m2
    on m2.sender_id = p.id
   and m2.receiver_id = auth.uid()
   and not m2.is_read
  where p.role = 'user'
  group by p.id, p.name, m.text, m.created_at
  order by m.created_at desc;
end;
$$;
revoke all on function public.get_admin_chat_list() from public, anon;
grant execute on function public.get_admin_chat_list() to authenticated;

commit;
