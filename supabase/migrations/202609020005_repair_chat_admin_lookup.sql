begin;

-- User chat needs one active admin profile as the conversation target.
create or replace function public.get_admin_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select profile.id
  from public.profiles as profile
  where profile.role = 'admin'
    and profile.status = 'active'
  order by profile.created_at asc
  limit 1;
$$;

revoke all on function public.get_admin_id() from public, anon;
grant execute on function public.get_admin_id() to authenticated;

commit;

-- Ask PostgREST to discover the repaired RPC immediately.
notify pgrst, 'reload schema';
