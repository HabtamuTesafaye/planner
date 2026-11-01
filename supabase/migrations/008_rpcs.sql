-- 008_rpcs: team lifecycle. These are the only way to create, join or leave
-- a team. They run as definer (team_members has no write policies), always
-- act on the calling user only, and raise short, stable error codes the app
-- maps to friendly messages:
--   not_authenticated, invalid_team_name, already_in_team, invalid_code,
--   not_in_team

-- create_team(name): creates the team, a unique join code and the owner
-- membership in one transaction.
create function public.create_team(p_name text)
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
  if exists (select 1 from public.team_members where user_id = v_uid) then
    raise exception 'already_in_team' using errcode = 'P0001';
  end if;

  -- Retry on the (very unlikely) join code collision.
  for attempt in 1..10 loop
    begin
      insert into public.teams (name, join_code, created_by)
      values (v_name, private.generate_join_code(), v_uid)
      returning * into v_team;
      exit;
    exception when unique_violation then
      if attempt = 10 then
        raise;
      end if;
    end;
  end loop;

  begin
    insert into public.team_members (team_id, user_id, role)
    values (v_team.id, v_uid, 'owner');
  exception when unique_violation then
    -- Another create or join for this user won the race.
    raise exception 'already_in_team' using errcode = 'P0001';
  end;

  return v_team;
end;
$$;

-- join_team(code): adds the caller as a member. A wrong code fails with
-- invalid_code and reveals nothing else. Input is forgiving: case and
-- spaces or dashes are ignored.
create function public.join_team(p_code text)
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
  if exists (select 1 from public.team_members where user_id = v_uid) then
    raise exception 'already_in_team' using errcode = 'P0001';
  end if;

  select * into v_team from public.teams where join_code = v_code;
  if not found then
    raise exception 'invalid_code' using errcode = 'P0001';
  end if;

  begin
    insert into public.team_members (team_id, user_id, role)
    values (v_team.id, v_uid, 'member');
  exception when unique_violation then
    raise exception 'already_in_team' using errcode = 'P0001';
  end;

  return v_team;
end;
$$;

-- leave_team(): removes the caller. If the owner leaves and others remain,
-- the oldest remaining member becomes owner. If nobody remains, the team
-- and all its data are deleted (cascade).
create function public.leave_team()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_team_id uuid;
  v_role text;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;

  select team_id, role into v_team_id, v_role
  from public.team_members
  where user_id = v_uid;
  if not found then
    raise exception 'not_in_team' using errcode = 'P0001';
  end if;

  -- Serialize concurrent leaves for the same team.
  perform 1 from public.teams where id = v_team_id for update;

  delete from public.team_members
  where team_id = v_team_id and user_id = v_uid;

  if not exists (select 1 from public.team_members where team_id = v_team_id) then
    delete from public.teams where id = v_team_id;
  elsif v_role = 'owner' then
    update public.team_members
    set role = 'owner'
    where (team_id, user_id) = (
      select m.team_id, m.user_id
      from public.team_members m
      where m.team_id = v_team_id
      order by m.joined_at, m.user_id
      limit 1
    );
  end if;
end;
$$;

revoke all on function public.create_team(text) from public, anon;
revoke all on function public.join_team(text) from public, anon;
revoke all on function public.leave_team() from public, anon;
grant execute on function public.create_team(text) to authenticated;
grant execute on function public.join_team(text) to authenticated;
grant execute on function public.leave_team() to authenticated;
