begin;

alter table public.messages
  add column if not exists attachment_path text,
  add column if not exists attachment_type text
    check (attachment_type is null or attachment_type in ('image', 'document')),
  add column if not exists attachment_name text,
  add column if not exists attachment_size bigint
    check (attachment_size is null or attachment_size between 1 and 10485760);

-- Existing text messages remain valid; a new message must contain text or a file.
alter table public.messages
  drop constraint if exists messages_content_required;
alter table public.messages
  add constraint messages_content_required check (
    nullif(trim(coalesce(text, '')), '') is not null
    or attachment_path is not null
  );

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
) values (
  'chat-attachments', 'chat-attachments', false, 10485760,
  array[
    'image/jpeg', 'image/png', 'image/webp', 'image/gif',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain'
  ]
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "chat_participants_upload_attachments" on storage.objects;
create policy "chat_participants_upload_attachments"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'chat-attachments'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "chat_participants_read_attachments" on storage.objects;
create policy "chat_participants_read_attachments"
on storage.objects for select to authenticated
using (
  bucket_id = 'chat-attachments'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or (storage.foldername(name))[2] = auth.uid()::text
  )
);

-- Message inserts are limited to the authenticated sender and valid attachment
-- paths. Existing select/update policies continue controlling conversation data.
drop policy if exists "users_send_chat_messages" on public.messages;
create policy "users_send_chat_messages"
on public.messages for insert to authenticated
with check (
  sender_id = auth.uid()
  and receiver_id <> auth.uid()
  and (
    attachment_path is null
    or attachment_path like auth.uid()::text || '/' || receiver_id::text || '/%'
  )
);

-- Attachment-only messages get a useful preview in the admin inbox.
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
    coalesce(nullif(m.text, ''),
      case m.attachment_type
        when 'image' then '📷 Photo'
        when 'document' then '📄 ' || coalesce(m.attachment_name, 'Document')
        else 'Attachment'
      end),
    m.created_at,
    count(*) filter (
      where not coalesce(m2.is_read, false) and m2.receiver_id = auth.uid()
    )::bigint
  from public.profiles p
  join lateral (
    select msg.text, msg.attachment_type, msg.attachment_name, msg.created_at
    from public.messages msg
    where msg.sender_id = p.id or msg.receiver_id = p.id
    order by msg.created_at desc
    limit 1
  ) m on true
  left join public.messages m2
    on m2.sender_id = p.id
   and m2.receiver_id = auth.uid()
   and not coalesce(m2.is_read, false)
  where p.role = 'user'
  group by p.id, p.name, m.text, m.attachment_type,
           m.attachment_name, m.created_at
  order by m.created_at desc;
end;
$$;

revoke all on function public.get_admin_chat_list() from public, anon;
grant execute on function public.get_admin_chat_list() to authenticated;

commit;

notify pgrst, 'reload schema';
