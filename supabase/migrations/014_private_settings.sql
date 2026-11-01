-- 014_private_settings: teammates see each other's name, nothing else.
--
-- Since 011 the profile row also holds personal settings (reminder time,
-- theme, last selected space). The RLS policy lets teammates read the row,
-- so these columns were visible to them. A reminder time reveals a daily
-- routine, so:
-- * authenticated may SELECT only id, display_name and created_at;
-- * each user reads their own full profile through get_my_profile().
-- Updates are unchanged (own row only, settings columns only).

revoke select on table public.profiles from authenticated;
grant select (id, display_name, created_at) on table public.profiles to authenticated;

-- The caller's own profile, including settings. Definer rights are needed
-- because the settings columns are no longer selectable directly; it only
-- ever returns the caller's row.
create function public.get_my_profile()
returns table (
  id uuid,
  display_name text,
  last_team_id uuid,
  theme text,
  reminder_time time
)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.display_name, p.last_team_id, p.theme, p.reminder_time
  from public.profiles p
  where p.id = (select auth.uid());
$$;

revoke all on function public.get_my_profile() from public, anon;
grant execute on function public.get_my_profile() to authenticated;
