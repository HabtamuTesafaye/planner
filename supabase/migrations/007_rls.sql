-- 007_rls: membership helpers and every Row Level Security policy.
--
-- Access model (AGENTS.md section 5.4):
-- * Read: a team member can read all rows of their team.
-- * Write own rows only: tasks, weekly_goals, weekly_reviews.
-- * Shared rows any member can add and edit: contacts, income_entries,
--   monthly_targets. Delete only by the creator or the team owner.
-- * Anonymous users: no access to anything (no grants, no policies).
-- Every policy is TO authenticated and also checks team membership, so
-- being logged in alone never grants access to rows.

-- Re-assert RLS on every table (already enabled when each was created).
alter table public.profiles enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.tasks enable row level security;
alter table public.weekly_goals enable row level security;
alter table public.weekly_reviews enable row level security;
alter table public.contacts enable row level security;
alter table public.income_entries enable row level security;
alter table public.monthly_targets enable row level security;

-- Helpers. SECURITY DEFINER so they can read team_members without
-- recursing into its own RLS policy. They only ever answer about the
-- calling user (auth.uid()), live in the unexposed private schema, and have
-- a fixed empty search_path.
create function private.is_team_member(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.team_members m
    where m.team_id = p_team_id
      and m.user_id = (select auth.uid())
  );
$$;

create function private.is_team_owner(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.team_members m
    where m.team_id = p_team_id
      and m.user_id = (select auth.uid())
      and m.role = 'owner'
  );
$$;

-- True when the caller and p_user_id are in the same team (or are the same
-- person). Used so teammates can see each other's names.
create function private.shares_team_with(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user_id = (select auth.uid())
    or exists (
      select 1
      from public.team_members me
      join public.team_members other on other.team_id = me.team_id
      where me.user_id = (select auth.uid())
        and other.user_id = p_user_id
    );
$$;

revoke all on function private.is_team_member(uuid) from public, anon;
revoke all on function private.is_team_owner(uuid) from public, anon;
revoke all on function private.shares_team_with(uuid) from public, anon;
grant execute on function private.is_team_member(uuid) to authenticated;
grant execute on function private.is_team_owner(uuid) to authenticated;
grant execute on function private.shares_team_with(uuid) to authenticated;

-- profiles ------------------------------------------------------------------
create policy "profiles: read self and teammates" on public.profiles
  for select to authenticated
  using ((select private.shares_team_with(id)));

create policy "profiles: update self" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- teams ---------------------------------------------------------------------
create policy "teams: members read" on public.teams
  for select to authenticated
  using ((select private.is_team_member(id)));

create policy "teams: owner renames" on public.teams
  for update to authenticated
  using ((select private.is_team_owner(id)))
  with check ((select private.is_team_owner(id)));

-- team_members (changes only through the RPCs) -------------------------------
create policy "team_members: members read" on public.team_members
  for select to authenticated
  using ((select private.is_team_member(team_id)));

-- Own-row tables: tasks, weekly_goals, weekly_reviews -------------------------
create policy "tasks: members read" on public.tasks
  for select to authenticated
  using ((select private.is_team_member(team_id)));

create policy "tasks: insert own" on public.tasks
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

create policy "tasks: update own" on public.tasks
  for update to authenticated
  using (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  )
  with check (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

create policy "tasks: delete own" on public.tasks
  for delete to authenticated
  using (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

create policy "weekly_goals: members read" on public.weekly_goals
  for select to authenticated
  using ((select private.is_team_member(team_id)));

create policy "weekly_goals: insert own" on public.weekly_goals
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

create policy "weekly_goals: update own" on public.weekly_goals
  for update to authenticated
  using (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  )
  with check (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

create policy "weekly_goals: delete own" on public.weekly_goals
  for delete to authenticated
  using (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

create policy "weekly_reviews: members read" on public.weekly_reviews
  for select to authenticated
  using ((select private.is_team_member(team_id)));

create policy "weekly_reviews: insert own" on public.weekly_reviews
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

create policy "weekly_reviews: update own" on public.weekly_reviews
  for update to authenticated
  using (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  )
  with check (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

create policy "weekly_reviews: delete own" on public.weekly_reviews
  for delete to authenticated
  using (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

-- Shared tables: contacts, income_entries, monthly_targets -------------------
create policy "contacts: members read" on public.contacts
  for select to authenticated
  using ((select private.is_team_member(team_id)));

create policy "contacts: members add as themselves" on public.contacts
  for insert to authenticated
  with check (
    owner_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

create policy "contacts: members edit" on public.contacts
  for update to authenticated
  using ((select private.is_team_member(team_id)))
  with check ((select private.is_team_member(team_id)));

create policy "contacts: creator or owner deletes" on public.contacts
  for delete to authenticated
  using (
    (select private.is_team_member(team_id))
    and (
      owner_id = (select auth.uid())
      or (select private.is_team_owner(team_id))
    )
  );

create policy "income: members read" on public.income_entries
  for select to authenticated
  using ((select private.is_team_member(team_id)));

create policy "income: members add as themselves" on public.income_entries
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

create policy "income: members edit" on public.income_entries
  for update to authenticated
  using ((select private.is_team_member(team_id)))
  with check ((select private.is_team_member(team_id)));

create policy "income: creator or owner deletes" on public.income_entries
  for delete to authenticated
  using (
    (select private.is_team_member(team_id))
    and (
      user_id = (select auth.uid())
      or (select private.is_team_owner(team_id))
    )
  );

create policy "targets: members read" on public.monthly_targets
  for select to authenticated
  using ((select private.is_team_member(team_id)));

create policy "targets: members add" on public.monthly_targets
  for insert to authenticated
  with check ((select private.is_team_member(team_id)));

create policy "targets: members edit" on public.monthly_targets
  for update to authenticated
  using ((select private.is_team_member(team_id)))
  with check ((select private.is_team_member(team_id)));

-- monthly_targets has no creator column, so only the team owner deletes.
create policy "targets: owner deletes" on public.monthly_targets
  for delete to authenticated
  using ((select private.is_team_owner(team_id)));

-- Defense in depth: tables and functions created later in public are no
-- longer granted to anon automatically, and functions are no longer
-- executable by PUBLIC by default.
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on sequences from anon;
alter default privileges in schema public revoke execute on functions from public, anon;
