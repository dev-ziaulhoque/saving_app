begin;

-- SaveSmart's canonical support account. Keeping this server-side prevents a
-- second active admin from silently becoming the user chat destination.
create or replace function public.get_admin_id()
returns uuid language sql stable security definer set search_path = '' as $$
  select p.id
  from public.profiles p
  where p.id = '2bdd64d6-e1a9-4b73-9c47-e62b7cbcba2a'::uuid
    and p.role = 'admin' and p.status = 'active'
  limit 1;
$$;
revoke all on function public.get_admin_id() from public, anon;
grant execute on function public.get_admin_id() to authenticated;

-- Repair messages that were routed to another active admin by the former
-- "oldest active admin" lookup. They remain the same support conversation.
update public.messages m
set receiver_id = '2bdd64d6-e1a9-4b73-9c47-e62b7cbcba2a'::uuid
where m.receiver_id in (
  select id from public.profiles
  where role = 'admin'
    and id <> '2bdd64d6-e1a9-4b73-9c47-e62b7cbcba2a'::uuid
)
and m.sender_id in (select id from public.profiles where role = 'user')
and exists (
  select 1 from public.profiles
  where id = '2bdd64d6-e1a9-4b73-9c47-e62b7cbcba2a'::uuid
    and role = 'admin' and status = 'active'
);

update public.messages m
set sender_id = '2bdd64d6-e1a9-4b73-9c47-e62b7cbcba2a'::uuid
where m.sender_id in (
  select id from public.profiles
  where role = 'admin'
    and id <> '2bdd64d6-e1a9-4b73-9c47-e62b7cbcba2a'::uuid
)
and m.receiver_id in (select id from public.profiles where role = 'user')
and exists (
  select 1 from public.profiles
  where id = '2bdd64d6-e1a9-4b73-9c47-e62b7cbcba2a'::uuid
    and role = 'admin' and status = 'active'
);

create or replace function public.get_admin_chat_list()
returns table (
  user_id uuid, user_name text, last_msg text,
  last_time timestamptz, unread_count bigint
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then raise exception 'Only admin can view the chat list'; end if;
  if auth.uid() <> public.get_admin_id() then
    raise exception 'This account is not the configured support admin';
  end if;

  return query
  select p.id, p.name,
    coalesce(nullif(last_message.text, ''),
      case last_message.attachment_type
        when 'image' then 'Photo'
        when 'document' then coalesce(last_message.attachment_name, 'Document')
        else 'Attachment' end),
    last_message.created_at,
    (select count(*) from public.messages unread
      where unread.sender_id = p.id and unread.receiver_id = auth.uid()
        and not coalesce(unread.is_read, false))::bigint
  from public.profiles p
  join lateral (
    select msg.text, msg.attachment_type, msg.attachment_name, msg.created_at
    from public.messages msg
    where (msg.sender_id = p.id and msg.receiver_id = auth.uid())
       or (msg.sender_id = auth.uid() and msg.receiver_id = p.id)
    order by msg.created_at desc limit 1
  ) last_message on true
  where p.role = 'user'
  order by last_message.created_at desc;
end;
$$;
revoke all on function public.get_admin_chat_list() from public, anon;
grant execute on function public.get_admin_chat_list() to authenticated;

-- Participants can only read their own messages. The receiver alone can mark
-- an incoming message as read.
drop policy if exists "chat_participants_read_messages" on public.messages;
create policy "chat_participants_read_messages" on public.messages
for select to authenticated
using (sender_id = auth.uid() or receiver_id = auth.uid());

drop policy if exists "chat_receiver_marks_messages_read" on public.messages;
create policy "chat_receiver_marks_messages_read" on public.messages
for update to authenticated
using (receiver_id = auth.uid())
with check (receiver_id = auth.uid());

commit;
notify pgrst, 'reload schema';
