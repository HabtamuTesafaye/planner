# Phase 2b: Spaces and projects backend

## Objective
Move from "exactly one team" to spaces: every user has a private Personal space and can belong to any number of team spaces. Add the projects data model. Nobody is forced to create a team.

## Tasks
1. Migration `011_spaces`: `teams.kind` (personal or team), nullable join code for personal spaces, drop one-team-per-user, personal space created on sign-up (and backfilled for existing users), `profiles.last_team_id`, `theme`, `reminder_time`. Update `create_team`, `join_team`, `leave_team(team_id)`: personal spaces cannot be joined or left; `already_member` replaces `already_in_team`; at most 20 spaces per user.
2. Migration `012_projects`: `projects`, `project_items`, `tasks.project_item_id`, RLS (shared inside the space), realtime publication, triggers (step team_id copied from its project; completing a linked task completes the step).
3. Extend `supabase/tests/rls_isolation.sql` for spaces and projects; all checks pass.
4. App: remove forced team setup; space switcher at the top; create and join spaces from it; selected space stored on the profile; Team tab becomes Space.
5. Update README and the security audit.

## Done when
- A new account lands in its Personal space without any setup step.
- It can create a team space, join another with a code, and switch between them.
- The isolation test passes, including projects.
