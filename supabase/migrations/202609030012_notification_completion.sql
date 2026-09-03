begin;

alter table public.notification_reads
  add column if not exists completed_at timestamptz;

create or replace function public.complete_notification(target_notification_id uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not exists (
    select 1 from public.notifications n
    where n.id=target_notification_id
      and (n.user_id=auth.uid() or n.user_id is null)
  ) then raise exception 'Notification not found or not allowed'; end if;
  insert into public.notification_reads(notification_id,user_id,read_at,completed_at)
  values(target_notification_id,auth.uid(),now(),now())
  on conflict(notification_id,user_id) do update
    set read_at=excluded.read_at,completed_at=excluded.completed_at;
end; $$;
revoke all on function public.complete_notification(uuid) from public,anon;
grant execute on function public.complete_notification(uuid) to authenticated;

do $$
declare table_name text;
begin
  foreach table_name in array array['notifications','notification_reads'] loop
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=table_name) then
      execute format('alter publication supabase_realtime add table public.%I',table_name);
    end if;
  end loop;
end $$;

commit;
notify pgrst,'reload schema';
