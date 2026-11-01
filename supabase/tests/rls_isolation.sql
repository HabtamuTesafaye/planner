-- RLS isolation and rules test for the Planner backend.
--
-- Run against the linked project (safe on staging):
--   npx supabase@2.122.0 db query --linked -f supabase/tests/rls_isolation.sql
--
-- What it does:
-- * Creates three throwaway users: A and C share team A, B is alone in team
--   B. Also checks a logged-out (anon) caller.
-- * Acts as each user the same way the API does (role + JWT claims) and
--   records one row per check in a results table.
-- * Deletes every user and team it created, then prints the results.
--   The last row is a summary. Every row must have ok = true.

-- Setup (as postgres) -------------------------------------------------------
create temp table t_results (
  n serial primary key,
  test text not null,
  ok boolean not null,
  info text
);
create temp table t_kv (k text primary key, v text);
grant all on t_results, t_kv to anon, authenticated;
grant usage on sequence t_results_n_seq to anon, authenticated;

-- Remove leftovers from an earlier run that stopped half way.
delete from public.teams where name like 'rls-test-%';
delete from auth.users where email like 'rls-test-%@example.com';

insert into t_kv (k, v)
values ('A', gen_random_uuid()::text),
       ('B', gen_random_uuid()::text),
       ('C', gen_random_uuid()::text);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
select '00000000-0000-0000-0000-000000000000', v::uuid, 'authenticated',
       'authenticated', 'rls-test-' || lower(k) || '@example.com', '', now(),
       '{"provider":"email","providers":["email"]}'::jsonb,
       jsonb_build_object('display_name', 'Test ' || k), now(), now()
from t_kv
where k in ('A', 'B', 'C');

-- Helpers -----------------------------------------------------------------
create function pg_temp.val(p_k text) returns text
language sql as $$ select v from t_kv where k = p_k $$;

create function pg_temp.put(p_k text, p_v text) returns void
language sql as $$
  insert into t_kv (k, v) values (p_k, p_v)
  on conflict (k) do update set v = excluded.v
$$;

create function pg_temp.ok(p_test text, p_ok boolean, p_info text default null)
returns void
language sql as $$
  insert into t_results (test, ok, info) values (p_test, coalesce(p_ok, false), p_info)
$$;

-- Switch to a user exactly like PostgREST does: role + JWT claims.
create function pg_temp.act_as(p_user text) returns void
language plpgsql as $$
begin
  reset role;
  if p_user = 'postgres' then
    perform set_config('request.jwt.claims', '', false);
  elsif p_user = 'anon' then
    perform set_config('request.jwt.claims', '{"role":"anon"}', false);
    set role anon;
  else
    perform set_config(
      'request.jwt.claims',
      json_build_object('sub', pg_temp.val(p_user), 'role', 'authenticated')::text,
      false
    );
    set role authenticated;
  end if;
end;
$$;

-- The statement must fail, with a message matching p_like.
create function pg_temp.expect_error(p_test text, p_sql text, p_like text default '%')
returns void
language plpgsql as $$
begin
  execute p_sql;
  perform pg_temp.ok(p_test, false, 'expected an error, but it succeeded');
exception when others then
  perform pg_temp.ok(p_test, sqlerrm like p_like, sqlerrm);
end;
$$;

-- The query must return exactly p_expected rows.
create function pg_temp.expect_count(p_test text, p_sql text, p_expected bigint)
returns void
language plpgsql as $$
declare
  n bigint;
begin
  execute 'select count(*) from (' || p_sql || ') q' into n;
  perform pg_temp.ok(p_test, n = p_expected, format('got %s, expected %s', n, p_expected));
exception when others then
  perform pg_temp.ok(p_test, false, sqlerrm);
end;
$$;

-- The insert/update/delete must affect exactly p_expected rows.
create function pg_temp.expect_affected(p_test text, p_sql text, p_expected int)
returns void
language plpgsql as $$
declare
  n int;
begin
  execute p_sql;
  get diagnostics n = row_count;
  perform pg_temp.ok(p_test, n = p_expected, format('affected %s, expected %s', n, p_expected));
exception when others then
  perform pg_temp.ok(p_test, false, sqlerrm);
end;
$$;

-- Logged-out access must return nothing: either permission denied or 0 rows.
create function pg_temp.expect_no_access(p_test text, p_sql text)
returns void
language plpgsql as $$
declare
  n bigint;
begin
  execute 'select count(*) from (' || p_sql || ') q' into n;
  perform pg_temp.ok(p_test, n = 0, format('%s rows visible', n));
exception
  when insufficient_privilege then
    perform pg_temp.ok(p_test, true, 'permission denied');
  when others then
    perform pg_temp.ok(p_test, false, sqlerrm);
end;
$$;

-- 1. Teams: create, join, wrong code ---------------------------------------
select pg_temp.act_as('A');
do $$
declare t public.teams;
begin
  t := public.create_team('rls-test-A');
  perform pg_temp.put('teamA', t.id::text);
  perform pg_temp.put('codeA', t.join_code);
  perform pg_temp.ok('A creates a team with a valid 8-char code',
    t.join_code ~ '^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{8}$', t.join_code);
exception when others then
  perform pg_temp.ok('A creates a team with a valid 8-char code', false, sqlerrm);
end $$;
select pg_temp.expect_error('A cannot create a second team',
  $q$ select public.create_team('rls-test-A2') $q$, 'already_in_team');

select pg_temp.act_as('B');
do $$
declare t public.teams;
begin
  t := public.create_team('rls-test-B');
  perform pg_temp.put('teamB', t.id::text);
  perform pg_temp.ok('B creates a separate team', true, null);
exception when others then
  perform pg_temp.ok('B creates a separate team', false, sqlerrm);
end $$;

select pg_temp.act_as('C');
select pg_temp.expect_error('Blank team name is rejected',
  $q$ select public.create_team('   ') $q$, 'invalid_team_name');
select pg_temp.expect_error('Joining with a wrong code fails',
  $q$ select public.join_team('ZZZZZZZZ') $q$, 'invalid_code');
select pg_temp.expect_error('Joining with an empty code fails',
  $q$ select public.join_team('') $q$, 'invalid_code');
do $$
declare
  code text := pg_temp.val('codeA');
  t public.teams;
begin
  -- Lowercase with a space in the middle: input should be forgiving.
  t := public.join_team(lower(left(code, 4)) || ' ' || lower(right(code, 4)));
  perform pg_temp.ok('C joins team A with the code (any case, spaces ok)',
    t.id::text = pg_temp.val('teamA'), null);
exception when others then
  perform pg_temp.ok('C joins team A with the code (any case, spaces ok)', false, sqlerrm);
end $$;

select pg_temp.act_as('B');
select pg_temp.expect_error('B (already in a team) cannot join team A',
  format('select public.join_team(%L)', pg_temp.val('codeA')), 'already_in_team');

-- 2. A's data and database rules -------------------------------------------
select pg_temp.act_as('A');
select pg_temp.expect_affected('A adds 3 tasks for today',
  format($q$ insert into public.tasks (team_id, title, day)
             values (%1$L, 'task 1', current_date),
                    (%1$L, 'task 2', current_date),
                    (%1$L, 'task 3', current_date) $q$, pg_temp.val('teamA')), 3);
select pg_temp.expect_error('A 4th task for the same day is rejected',
  format($q$ insert into public.tasks (team_id, title, day)
             values (%L, 'task 4', current_date) $q$, pg_temp.val('teamA')),
  'task_limit_reached');
select pg_temp.expect_error('Inserting 4 tasks at once is rejected',
  format($q$ insert into public.tasks (team_id, title, day)
             select %L, 'bulk ' || g, current_date + 1 from generate_series(1, 4) g $q$,
         pg_temp.val('teamA')),
  'task_limit_reached');
select pg_temp.expect_count('Rejected bulk insert left nothing behind',
  'select 1 from public.tasks where day = current_date + 1', 0);
select pg_temp.expect_affected('A adds a task on another day',
  format($q$ insert into public.tasks (team_id, title, day)
             values (%L, 'other day', current_date + 2) $q$, pg_temp.val('teamA')), 1);
select pg_temp.expect_error('Moving a task onto a full day is rejected',
  $q$ update public.tasks set day = current_date where title = 'other day' $q$,
  'task_limit_reached');
select pg_temp.expect_affected('A removes the other-day task',
  $q$ delete from public.tasks where title = 'other day' $q$, 1);
select pg_temp.expect_error('A cannot rewrite a task''s created_at',
  $q$ update public.tasks set created_at = now() - interval '1 year' $q$,
  '%permission denied%');
select pg_temp.expect_error('A cannot rewrite done_at directly',
  $q$ update public.tasks set done_at = now() - interval '1 year' $q$,
  '%permission denied%');
select pg_temp.expect_affected('A completes a task',
  $q$ update public.tasks set done = true where title = 'task 1' $q$, 1);
select pg_temp.expect_count('done_at is set by the database',
  $q$ select 1 from public.tasks where title = 'task 1' and done_at is not null $q$, 1);
select pg_temp.expect_error('Task title over 120 characters is rejected',
  format($q$ insert into public.tasks (team_id, title, day)
             values (%L, repeat('x', 121), current_date + 3) $q$, pg_temp.val('teamA')),
  '%check constraint%');
select pg_temp.expect_error('Blank task title is rejected',
  format($q$ insert into public.tasks (team_id, title, day)
             values (%L, '   ', current_date + 3) $q$, pg_temp.val('teamA')),
  '%check constraint%');

select pg_temp.expect_affected('A sets a weekly goal (Monday week start)',
  format($q$ insert into public.weekly_goals (team_id, week_start, goal)
             values (%L, date_trunc('week', current_date)::date, 'Ship v1') $q$,
         pg_temp.val('teamA')), 1);
select pg_temp.expect_error('Weekly goal on a non-Monday is rejected',
  format($q$ insert into public.weekly_goals (team_id, week_start, goal)
             values (%L, date_trunc('week', current_date)::date + 1, 'x') $q$,
         pg_temp.val('teamA')),
  '%check constraint%');
select pg_temp.expect_affected('A writes a weekly review',
  format($q$ insert into public.weekly_reviews (team_id, week_start, did, blocked, next_goal)
             values (%L, date_trunc('week', current_date)::date, 'did', 'none', 'next') $q$,
         pg_temp.val('teamA')), 1);
select pg_temp.expect_affected('A adds a contact',
  format($q$ insert into public.contacts (team_id, name, business, status)
             values (%L, 'Abebe', 'Cafe', 'contacted') $q$, pg_temp.val('teamA')), 1);
select pg_temp.expect_error('Unknown contact status is rejected',
  format($q$ insert into public.contacts (team_id, name, status)
             values (%L, 'X', 'won') $q$, pg_temp.val('teamA')),
  '%check constraint%');
select pg_temp.expect_affected('A adds an income entry',
  format($q$ insert into public.income_entries (team_id, month, amount, note)
             values (%L, date_trunc('month', current_date)::date, 12500, 'First client') $q$,
         pg_temp.val('teamA')), 1);
select pg_temp.expect_error('Income of 0 is rejected',
  format($q$ insert into public.income_entries (team_id, month, amount)
             values (%L, date_trunc('month', current_date)::date, 0) $q$,
         pg_temp.val('teamA')),
  '%check constraint%');
select pg_temp.expect_error('Income month must be the first day',
  format($q$ insert into public.income_entries (team_id, month, amount)
             values (%L, date_trunc('month', current_date)::date + 1, 10) $q$,
         pg_temp.val('teamA')),
  '%check constraint%');
select pg_temp.expect_affected('A sets the monthly target',
  format($q$ insert into public.monthly_targets (team_id, month, target)
             values (%L, date_trunc('month', current_date)::date, 50000) $q$,
         pg_temp.val('teamA')), 1);
select pg_temp.expect_affected('A (owner) renames the team',
  format($q$ update public.teams set name = 'rls-test-A renamed' where id = %L $q$,
         pg_temp.val('teamA')), 1);

-- 3. B (other team) can neither read nor write team A ----------------------
select pg_temp.act_as('B');
select pg_temp.expect_count('B cannot read team A: ' || tbl,
  format('select 1 from public.%I where team_id = %L', tbl, pg_temp.val('teamA')), 0)
from unnest(array['tasks', 'weekly_goals', 'weekly_reviews', 'contacts',
                  'income_entries', 'monthly_targets', 'team_members']) tbl;
select pg_temp.expect_count('B cannot read team A: teams',
  format('select 1 from public.teams where id = %L', pg_temp.val('teamA')), 0);
select pg_temp.expect_count('B cannot read A''s or C''s profile',
  format('select 1 from public.profiles where id in (%L, %L)',
         pg_temp.val('A'), pg_temp.val('C')), 0);
select pg_temp.expect_count('B sees no rows outside team B: ' || tbl,
  format('select 1 from public.%I where team_id <> %L', tbl, pg_temp.val('teamB')), 0)
from unnest(array['tasks', 'weekly_goals', 'weekly_reviews', 'contacts',
                  'income_entries', 'monthly_targets', 'team_members']) tbl;

select pg_temp.expect_error('B cannot insert a task into team A',
  format($q$ insert into public.tasks (team_id, title, day)
             values (%L, 'intruder', current_date) $q$, pg_temp.val('teamA')),
  '%row-level security%');
select pg_temp.expect_error('B cannot insert a contact into team A',
  format($q$ insert into public.contacts (team_id, name) values (%L, 'intruder') $q$,
         pg_temp.val('teamA')),
  '%row-level security%');
select pg_temp.expect_error('B cannot insert income into team A',
  format($q$ insert into public.income_entries (team_id, month, amount)
             values (%L, date_trunc('month', current_date)::date, 1) $q$,
         pg_temp.val('teamA')),
  '%row-level security%');
select pg_temp.expect_error('B cannot set team A''s target',
  format($q$ insert into public.monthly_targets (team_id, month, target)
             values (%L, date_trunc('month', current_date)::date + interval '1 month', 1) $q$,
         pg_temp.val('teamA')),
  '%row-level security%');
select pg_temp.expect_error('B cannot add a weekly goal to team A',
  format($q$ insert into public.weekly_goals (team_id, week_start, goal)
             values (%L, date_trunc('week', current_date)::date, 'x') $q$,
         pg_temp.val('teamA')),
  '%row-level security%');
select pg_temp.expect_affected('B cannot update team A contacts',
  format('update public.contacts set notes = %L where team_id = %L',
         'hacked', pg_temp.val('teamA')), 0);
select pg_temp.expect_affected('B cannot update team A tasks',
  format('update public.tasks set title = %L where team_id = %L',
         'hacked', pg_temp.val('teamA')), 0);
select pg_temp.expect_affected('B cannot delete team A tasks',
  format('delete from public.tasks where team_id = %L', pg_temp.val('teamA')), 0);
select pg_temp.expect_affected('B cannot delete team A income',
  format('delete from public.income_entries where team_id = %L', pg_temp.val('teamA')), 0);
select pg_temp.expect_affected('B cannot rename team A',
  format('update public.teams set name = %L where id = %L', 'hacked', pg_temp.val('teamA')), 0);
select pg_temp.expect_error('B cannot add itself to team A directly',
  format($q$ insert into public.team_members (team_id, user_id) values (%L, %L) $q$,
         pg_temp.val('teamA'), pg_temp.val('B')),
  '%permission denied%');
select pg_temp.expect_error('B cannot promote itself',
  $q$ update public.team_members set role = 'owner' $q$, '%permission denied%');

-- 4. C (A's teammate): reads everything, writes only what the rules allow --
select pg_temp.act_as('C');
select pg_temp.expect_count('C can read A''s tasks (same team)',
  format('select 1 from public.tasks where team_id = %L', pg_temp.val('teamA')), 3);
select pg_temp.expect_count('C can read A''s profile',
  format('select 1 from public.profiles where id = %L', pg_temp.val('A')), 1);
select pg_temp.expect_count('C can read A''s review',
  format('select 1 from public.weekly_reviews where user_id = %L', pg_temp.val('A')), 1);
select pg_temp.expect_affected('C cannot edit A''s tasks',
  format('update public.tasks set title = %L where user_id = %L', 'edited', pg_temp.val('A')), 0);
select pg_temp.expect_affected('C cannot delete A''s tasks',
  format('delete from public.tasks where user_id = %L', pg_temp.val('A')), 0);
select pg_temp.expect_affected('C cannot edit A''s weekly goal',
  format('update public.weekly_goals set goal = %L where user_id = %L', 'edited', pg_temp.val('A')), 0);
select pg_temp.expect_error('C cannot add a task as A',
  format($q$ insert into public.tasks (team_id, user_id, title, day)
             values (%L, %L, 'fake', current_date + 5) $q$,
         pg_temp.val('teamA'), pg_temp.val('A')),
  '%row-level security%');
select pg_temp.expect_error('C cannot add a contact as A',
  format($q$ insert into public.contacts (team_id, owner_id, name) values (%L, %L, 'fake') $q$,
         pg_temp.val('teamA'), pg_temp.val('A')),
  '%row-level security%');
select pg_temp.expect_affected('C can edit a shared contact',
  format('update public.contacts set notes = %L where team_id = %L',
         'edited by C', pg_temp.val('teamA')), 1);
select pg_temp.expect_error('C cannot take over a contact''s creator',
  format('update public.contacts set owner_id = %L where team_id = %L',
         pg_temp.val('C'), pg_temp.val('teamA')),
  '%permission denied%');
select pg_temp.expect_error('C cannot move a contact to another team',
  format('update public.contacts set team_id = %L where team_id = %L',
         pg_temp.val('teamB'), pg_temp.val('teamA')),
  '%');
select pg_temp.expect_error('C cannot change who added an income entry',
  format('update public.income_entries set user_id = %L where team_id = %L',
         pg_temp.val('C'), pg_temp.val('teamA')),
  '%permission denied%');
select pg_temp.expect_affected('C cannot delete A''s contact',
  format('delete from public.contacts where owner_id = %L', pg_temp.val('A')), 0);
select pg_temp.expect_affected('C cannot delete A''s income entry',
  format('delete from public.income_entries where user_id = %L', pg_temp.val('A')), 0);
select pg_temp.expect_affected('C cannot delete the monthly target (owner only)',
  format('delete from public.monthly_targets where team_id = %L', pg_temp.val('teamA')), 0);
select pg_temp.expect_affected('C (member) cannot rename the team',
  format('update public.teams set name = %L where id = %L', 'by C', pg_temp.val('teamA')), 0);
select pg_temp.expect_affected('C adds two contacts',
  format($q$ insert into public.contacts (team_id, name)
             values (%1$L, 'C lead 1'), (%1$L, 'C lead 2') $q$, pg_temp.val('teamA')), 2);
select pg_temp.expect_affected('C deletes its own contact',
  $q$ delete from public.contacts where name = 'C lead 1' $q$, 1);

select pg_temp.act_as('A');
select pg_temp.expect_affected('A (owner) can delete C''s contact',
  $q$ delete from public.contacts where name = 'C lead 2' $q$, 1);

-- 5. Logged-out (anon) callers get nothing ---------------------------------
select pg_temp.act_as('anon');
select pg_temp.expect_no_access('anon reads nothing: ' || tbl,
  format('select 1 from public.%I', tbl))
from unnest(array['profiles', 'teams', 'team_members', 'tasks', 'weekly_goals',
                  'weekly_reviews', 'contacts', 'income_entries', 'monthly_targets']) tbl;
select pg_temp.expect_error('anon cannot call create_team',
  $q$ select public.create_team('anon team') $q$, '%permission denied%');
select pg_temp.expect_error('anon cannot call join_team',
  format('select public.join_team(%L)', pg_temp.val('codeA')), '%permission denied%');
select pg_temp.expect_error('anon cannot insert a task',
  format($q$ insert into public.tasks (team_id, title, day) values (%L, 'x', current_date) $q$,
         pg_temp.val('teamA')),
  '%permission denied%');

-- 6. Leaving: owner hand-over and team deletion ----------------------------
select pg_temp.act_as('A');
select pg_temp.expect_affected('A (owner) leaves the team',
  'select public.leave_team()', 1);
select pg_temp.expect_count('A can no longer read team A tasks',
  format('select 1 from public.tasks where team_id = %L', pg_temp.val('teamA')), 0);
select pg_temp.expect_error('A cannot leave twice',
  'select public.leave_team()', 'not_in_team');

select pg_temp.act_as('postgres');
select pg_temp.ok('C (oldest remaining) became owner',
  exists (select 1 from public.team_members
          where team_id = pg_temp.val('teamA')::uuid
            and user_id = pg_temp.val('C')::uuid and role = 'owner'));

select pg_temp.act_as('C');
select pg_temp.expect_affected('C (last member) leaves', 'select public.leave_team()', 1);

select pg_temp.act_as('postgres');
select pg_temp.ok('Team A and all its data were deleted with the last member',
  not exists (select 1 from public.teams where id = pg_temp.val('teamA')::uuid)
  and not exists (select 1 from public.tasks where team_id = pg_temp.val('teamA')::uuid)
  and not exists (select 1 from public.contacts where team_id = pg_temp.val('teamA')::uuid)
  and not exists (select 1 from public.income_entries where team_id = pg_temp.val('teamA')::uuid));

select pg_temp.act_as('B');
select pg_temp.expect_affected('B leaves', 'select public.leave_team()', 1);

-- Cleanup and results (as postgres) ---------------------------------------
select pg_temp.act_as('postgres');
delete from public.teams where name like 'rls-test-%';
delete from auth.users where email like 'rls-test-%@example.com';
select pg_temp.ok('Cleanup removed all test users and teams',
  not exists (select 1 from auth.users where email like 'rls-test-%@example.com')
  and not exists (select 1 from public.teams where name like 'rls-test-%'));

select n, test, ok, info
from t_results
union all
select 100000,
       format('SUMMARY: %s passed, %s failed',
              count(*) filter (where ok), count(*) filter (where not ok)),
       bool_and(ok),
       null
from t_results
order by 1;
