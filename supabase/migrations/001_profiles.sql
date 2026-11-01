-- 001_profiles: one profile per user, created automatically on sign-up.
--
-- Security notes for every migration in this project:
-- * This project grants new tables and functions to anon and authenticated
--   by default. Each migration revokes those and grants back only what the
--   app needs.
-- * RLS is enabled in the same migration that creates a table, so no table
--   ever exists without it. Policies live in 007_rls.

-- Private schema for helper functions. It is not exposed through the Data
-- API, so nothing in it can be called as an RPC. authenticated needs USAGE
-- so RLS policies can call the helpers.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null
    check (char_length(btrim(display_name)) between 1 and 60),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
revoke all on table public.profiles from anon, authenticated;
-- Users may read profiles (filtered by RLS) and change only their name.
grant select, update (display_name) on table public.profiles to authenticated;

-- Creates the profile when a user signs up. The name comes from the sign-up
-- form (user metadata). It is only used as a display label, never for
-- authorization.
create function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text := btrim(coalesce(new.raw_user_meta_data ->> 'display_name', ''));
begin
  if v_name = '' then
    v_name := split_part(coalesce(new.email, 'Member'), '@', 1);
  end if;
  insert into public.profiles (id, display_name)
  values (new.id, left(v_name, 60));
  return new;
end;
$$;

revoke all on function private.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();
