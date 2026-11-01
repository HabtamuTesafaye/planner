-- 011_spaces: from "exactly one team" to spaces.
--
-- * Every user has one Personal space (kind 'personal'), created on sign-up.
--   It has no join code, cannot be joined and cannot be left.
-- * Users can belong to any number of team spaces (kind 'team'), up to 20.
-- * The profile remembers the selected space and the user's settings.
-- Table and function names keep "team" to avoid churn; "team" = space.

-- teams -> spaces ------------------------------------------------------------
alter table public.teams
  add column kind text not null default 'team' check (kind in ('personal', 'team'));

alter table public.teams alter column join_code drop not null;

-- Personal spaces never have a code; team spaces always do.
alter table public.teams
  add constraint teams_code_matches_kind check ((kind = 'personal') = (join_code is null));

-- One personal space per user.
create unique index teams_one_personal_per_user
  on public.teams (created_by) where kind = 'personal';

-- Many spaces per user.
alter table public.team_members drop constraint team_members_user_id_key;
create index team_members_user_id_idx on public.team_members (user_id);

-- profiles: selected space and settings ---------------------------------------
alter table public.profiles
  add column last_team_id uuid references public.teams (id) on delete set null,
  add column theme text not null default 'system'
    check (theme in ('system', 'light', 'dark')),
  -- Daily reminder time (device local time). Null means off.
  add column reminder_time time;

create index profiles_last_team_id_idx on public.profiles (last_team_id);

revoke update on table public.profiles from authenticated;
grant update (display_name, last_team_id, theme, reminder_time)
  on table public.profiles to authenticated;

-- last_team_id may only point at a space the user belongs to; anything else
-- is quietly cleared (the app then falls back to the personal space).
create function private.check_last_team()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.last_team_id is not null and not exists (
    select 1 from public.team_members m
    where m.team_id = new.last_team_id and m.user_id = new.id
  ) then
    new.last_team_id := null;
  end if;
  return new;
end;
$$;

revoke all on function private.check_last_team() from public, anon, authenticated;

create trigger profiles_check_last_team
  before update of last_team_id on public.profiles
  for each row execute function private.check_last_team();

-- Personal space for a user. Used on sign-up and for the backfill below.
create function private.create_personal_space(p_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_team_id uuid;
begin
  insert into public.teams (name, kind, join_code, created_by)
  values ('Personal', 'personal', null, p_user_id)
  returning id into v_team_id;
  insert into public.team_members (team_id, user_id, role)
  values (v_team_id, p_user_id, 'owner');
  update public.profiles set last_team_id = v_team_id where id = p_user_id;
  return v_team_id;
end;
$$;

revoke all on function private.create_personal_space(uuid) from public, anon, authenticated;

-- Sign-up now creates the profile and the personal space.
create or replace function private.handle_new_user()
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
  perform private.create_personal_space(new.id);
  return new;
end;
$$;

-- When a profile is deleted (account removed), its personal space goes too.
create function private.delete_personal_space()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.teams where created_by = old.id and kind = 'personal';
  return old;
end;
$$;

revoke all on function private.delete_personal_space() from public, anon, authenticated;

create trigger profiles_delete_personal_space
  before delete on public.profiles
  for each row execute function private.delete_personal_space();

-- Backfill: existing users get their personal space.
do $$
declare
  p record;
begin
  for p in
    select pr.id from public.profiles pr
    where not exists (
      select 1 from public.teams t where t.created_by = pr.id and t.kind = 'personal'
    )
  loop
    perform private.create_personal_space(p.id);
  end loop;
end;
$$;

-- RPCs ------------------------------------------------------------------------
-- Error codes: not_authenticated, invalid_team_name, invalid_code,
-- already_member, too_many_spaces, not_in_team, cannot_leave_personal.

create or replace function public.create_team(p_name text)
returns public.teams
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_name text := btrim(coalesce(p_name, ''));
  v_team public.teams;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;
  if char_length(v_name) not between 1 and 60 then
    raise exception 'invalid_team_name' using errcode = 'P0001';
  end if;
  if (select count(*) from public.team_members where user_id = v_uid) >= 20 then
    raise exception 'too_many_spaces' using errcode = 'P0001';
  end if;

  for attempt in 1..10 loop
    begin
      insert into public.teams (name, kind, join_code, created_by)
      values (v_name, 'team', private.generate_join_code(), v_uid)
      returning * into v_team;
      exit;
    exception when unique_violation then
      if attempt = 10 then
        raise;
      end if;
    end;
  end loop;

  insert into public.team_members (team_id, user_id, role)
  values (v_team.id, v_uid, 'owner');
  update public.profiles set last_team_id = v_team.id where id = v_uid;
  return v_team;
end;
$$;

create or replace function public.join_team(p_code text)
returns public.teams
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_code text := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  v_team public.teams;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;

  select * into v_team
  from public.teams
  where join_code = v_code and kind = 'team';
  if not found then
    raise exception 'invalid_code' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.team_members where team_id = v_team.id and user_id = v_uid
  ) then
    raise exception 'already_member' using errcode = 'P0001';
  end if;
  if (select count(*) from public.team_members where user_id = v_uid) >= 20 then
    raise exception 'too_many_spaces' using errcode = 'P0001';
  end if;

  begin
    insert into public.team_members (team_id, user_id, role)
    values (v_team.id, v_uid, 'member');
  exception when unique_violation then
    raise exception 'already_member' using errcode = 'P0001';
  end;
  update public.profiles set last_team_id = v_team.id where id = v_uid;
  return v_team;
end;
$$;

-- leave_team now takes the space to leave.
drop function public.leave_team();

create function public.leave_team(p_team_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_role text;
  v_kind text;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;

  select m.role, t.kind into v_role, v_kind
  from public.team_members m
  join public.teams t on t.id = m.team_id
  where m.team_id = p_team_id and m.user_id = v_uid;
  if not found then
    raise exception 'not_in_team' using errcode = 'P0001';
  end if;
  if v_kind = 'personal' then
    raise exception 'cannot_leave_personal' using errcode = 'P0001';
  end if;

  -- Serialize concurrent leaves for the same space.
  perform 1 from public.teams where id = p_team_id for update;

  delete from public.team_members where team_id = p_team_id and user_id = v_uid;

  if not exists (select 1 from public.team_members where team_id = p_team_id) then
    delete from public.teams where id = p_team_id;
  elsif v_role = 'owner' then
    update public.team_members
    set role = 'owner'
    where (team_id, user_id) = (
      select m.team_id, m.user_id
      from public.team_members m
      where m.team_id = p_team_id
      order by m.joined_at, m.user_id
      limit 1
    );
  end if;

  -- Go back to the personal space if the left space was selected.
  update public.profiles p
  set last_team_id = (
    select t.id from public.teams t where t.created_by = v_uid and t.kind = 'personal'
  )
  where p.id = v_uid and (p.last_team_id is null or p.last_team_id = p_team_id);
end;
$$;

revoke all on function public.leave_team(uuid) from public, anon;
grant execute on function public.leave_team(uuid) to authenticated;
