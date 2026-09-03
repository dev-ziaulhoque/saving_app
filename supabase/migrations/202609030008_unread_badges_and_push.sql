begin;

-- Some projects were created before notification read-state was added.
-- Keep this migration runnable even when migration 001 was only partially run.
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
on public.notification_reads for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "users_create_own_notification_state"
  on public.notification_reads;
create policy "users_create_own_notification_state"
on public.notification_reads for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "users_update_own_notification_state"
  on public.notification_reads;
create policy "users_update_own_notification_state"
on public.notification_reads for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create or replace function public.get_unread_badge_counts()
returns jsonb language sql stable security definer set search_path = '' as $$
  select case when auth.uid() is null then jsonb_build_object('chats', 0, 'notifications', 0)
  else jsonb_build_object(
    'chats', (select count(*) from public.messages m where m.receiver_id = auth.uid() and not coalesce(m.is_read, false)),
    'notifications', (
      select count(*) from public.notifications n
      where (n.user_id = auth.uid() or n.user_id is null)
        and not exists (select 1 from public.notification_reads nr where nr.notification_id = n.id and nr.user_id = auth.uid())
    )
  ) end;
$$;

revoke all on function public.get_unread_badge_counts() from public, anon;
grant execute on function public.get_unread_badge_counts() to authenticated;

do $$
declare table_name text;
begin
  foreach table_name in array array['messages', 'notifications', 'notification_reads'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = table_name) then
      execute format('alter publication supabase_realtime add table public.%I', table_name);
    end if;
  end loop;
end;
$$;

commit;
notify pgrst, 'reload schema';
