begin;

create or replace function public.is_active_profile()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active');
$$;

create table if not exists public.group_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete restrict,
  text text not null check (length(trim(text)) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index if not exists group_messages_created_idx on public.group_messages(created_at desc);

create table if not exists public.group_message_reads (
  message_id uuid not null references public.group_messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key(message_id,user_id)
);
alter table public.group_messages enable row level security;
alter table public.group_message_reads enable row level security;

drop policy if exists "active_profiles_read_group" on public.group_messages;
create policy "active_profiles_read_group" on public.group_messages for select to authenticated using(public.is_active_profile());
drop policy if exists "active_profiles_send_group" on public.group_messages;
create policy "active_profiles_send_group" on public.group_messages for insert to authenticated with check(public.is_active_profile() and sender_id=auth.uid());
drop policy if exists "users_read_own_group_state" on public.group_message_reads;
create policy "users_read_own_group_state" on public.group_message_reads for select to authenticated using(user_id=auth.uid());
drop policy if exists "users_create_own_group_state" on public.group_message_reads;
create policy "users_create_own_group_state" on public.group_message_reads for insert to authenticated with check(user_id=auth.uid());

drop function if exists public.get_community_members();
create function public.get_community_members()
returns table(id uuid,name text,role text,avatar_url text,joined_at timestamptz,unread_count bigint)
language plpgsql stable security definer set search_path='' as $$
begin
  if not public.is_active_profile() then raise exception 'Only active members can view the community'; end if;
  return query select p.id,p.name,p.role,p.avatar_url,p.created_at,
    (select count(*) from public.messages m where m.sender_id=p.id and m.receiver_id=auth.uid() and not coalesce(m.is_read,false))::bigint
  from public.profiles p where p.status='active' order by (p.role='admin') desc,p.name;
end; $$;
revoke all on function public.get_community_members() from public,anon;
grant execute on function public.get_community_members() to authenticated;

create or replace function public.mark_group_messages_read()
returns void language sql security definer set search_path='' as $$
  insert into public.group_message_reads(message_id,user_id)
  select gm.id,auth.uid() from public.group_messages gm where gm.sender_id<>auth.uid()
  on conflict(message_id,user_id) do nothing;
$$;
revoke all on function public.mark_group_messages_read() from public,anon;
grant execute on function public.mark_group_messages_read() to authenticated;

create or replace function public.get_unread_badge_counts()
returns jsonb language sql stable security definer set search_path='' as $$
  select case when auth.uid() is null then jsonb_build_object('chats',0,'notifications',0)
  else jsonb_build_object(
    'chats',
      (select count(*) from public.messages m where m.receiver_id=auth.uid() and not coalesce(m.is_read,false))
      + (select count(*) from public.group_messages gm where gm.sender_id<>auth.uid() and not exists(select 1 from public.group_message_reads gr where gr.message_id=gm.id and gr.user_id=auth.uid())),
    'notifications',(select count(*) from public.notifications n where (n.user_id=auth.uid() or n.user_id is null) and not exists(select 1 from public.notification_reads nr where nr.notification_id=n.id and nr.user_id=auth.uid()))
  ) end;
$$;

drop policy if exists "users_send_chat_messages" on public.messages;
create policy "users_send_chat_messages" on public.messages for insert to authenticated
with check(sender_id=auth.uid() and receiver_id<>auth.uid() and public.is_active_profile()
  and exists(select 1 from public.profiles receiver where receiver.id=receiver_id and receiver.status='active')
  and (attachment_path is null or attachment_path like auth.uid()::text||'/'||receiver_id::text||'/%'));

-- RLS policies are combined with OR, so a table constraint is the definitive
-- protection against any legacy policy accidentally allowing self-messages.
do $$ begin
  if not exists (
    select 1 from pg_constraint
    where conrelid='public.messages'::regclass
      and conname='messages_no_self_chat'
  ) then
    alter table public.messages
      add constraint messages_no_self_chat
      check (sender_id <> receiver_id) not valid;
  end if;
end $$;

do $$ begin
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='group_messages') then
    alter publication supabase_realtime add table public.group_messages;
  end if;
end $$;

commit;
notify pgrst,'reload schema';
