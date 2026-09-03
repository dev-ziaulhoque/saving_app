-- Promote the selected account to an active app admin.
-- Run this once in Supabase Dashboard -> SQL Editor.

update public.profiles as profile
set role = 'admin',
    status = 'active',
    updated_at = now()
from auth.users as auth_user
where profile.id = auth_user.id
  and lower(auth_user.email) = lower('mdziaulhoquesp94@gmail.com');

select auth_user.email, profile.id, profile.name, profile.role, profile.status
from public.profiles as profile
join auth.users as auth_user on auth_user.id = profile.id
where lower(auth_user.email) = lower('mdziaulhoquesp94@gmail.com');
