# Phase 1: Backend (Supabase)

## Objective
Build the complete, secure Supabase backend and prove it works before the app touches it. At the end, a stranger or another team must not be able to read or change data they do not own.

## Prerequisites
Phase 0 approved. I will create a free Supabase project called `planner-staging` and give you the URL and anon key through `env/staging.json` (never in chat logs or git).

## Tasks
Create SQL migrations in `supabase/migrations/`, one file per step, numbered:
1. `001_profiles`: `profiles` table, and a trigger that creates a profile on signup.
2. `002_teams`: `teams`, `team_members` (one team per user), join code generator (8 characters, no 0/O/1/I).
3. `003_tasks`: `tasks` table, indexes, and a trigger that rejects a 4th task for the same `user_id` and `day` with a clear error message.
4. `004_goals_reviews`: `weekly_goals`, `weekly_reviews`.
5. `005_contacts`: `contacts` with status check and an `updated_at` trigger.
6. `006_income`: `income_entries`, `monthly_targets`.
7. `007_rls`: enable RLS on every table, helper `is_team_member(team_id)` as `security definer` with fixed `search_path`, and all policies exactly as described in AGENTS.md section 5.4.
8. `008_rpcs`: `create_team(name)`, `join_team(code)`, `leave_team()`. Revoke execute from `anon`.
9. `009_realtime`: enable replication for `tasks`, `contacts`, `income_entries`.
10. Tests: `supabase/tests/rls_isolation.sql` (or a documented script) with two test users in two teams proving: no cross-team reads, no cross-team writes, a user cannot edit another user's tasks, anonymous users read nothing, the 4th task is rejected, joining with a wrong code fails.
11. Extend `README.md` with Supabase setup: create project, run migrations, turn email confirmation off for staging, where to find URL and anon key, the 7-day pause note, and how to restore a paused project.

## Do
- Use `uuid` primary keys with `gen_random_uuid()`.
- Add `check` constraints for lengths and positive amounts.
- Make every migration safe to read top to bottom with short comments.

## Do not
- Do not disable RLS on any table, even temporarily.
- Do not use or mention the `service_role` key in the app or repo.
- Do not write any Flutter code in this phase.
- Do not rely on client-side checks for anything security related.

## Done when
- All migrations run cleanly on a fresh project, in order.
- The isolation tests pass, and I can see the results.
- Querying any table with only the anon key and no login returns nothing.

## Report back, then stop

When the phase is finished, update `PROGRESS.md` and commit your work. Then reply with:
1. What you built, in a few lines.
2. Exactly how I test it on my phone (numbered steps).
3. Anything you were unsure about or chose a default for.
4. The result of `flutter analyze` and `flutter test`.

Then stop and wait for my "go". Do not start the next phase.
