# Phase 2: Auth and team

## Objective
Two people can create accounts on two phones and end up in the same team, with sessions that survive closing the app.

## Prerequisites
Phase 1 approved and `env/staging.json` filled in.

## Tasks
1. Initialize `supabase_flutter` in `main.dart` using `AppConfig`. Keep all Supabase access in `lib/data/`.
2. Models and repositories: `AuthRepository` (sign up, sign in, sign out, current session), `TeamRepository` (create team, join with code, leave team, get my team and members).
3. Riverpod providers: auth state stream, current profile, current team.
4. Screens in `lib/features/auth/`: Welcome, Sign up (name, email, password min 8), Sign in, then "Create a team or join with a code".
5. Router redirects: not signed in goes to Welcome; signed in without a team goes to team setup; otherwise the 4-tab shell.
6. Friendly error mapping in one place (wrong password, email already used, wrong or used join code, no connection, unknown error). No raw exception text on screen.
7. In the Team tab (temporary), show the team name, invite code with copy button, Leave team and Sign out.
8. Forms: validation, disabled submit while loading, keyboard-safe layout, password show/hide, autofill hints.
9. Tests: error mapping, redirect logic, join code input formatting (uppercase, trims spaces).

## Do
- Make sign up and team setup feel quick, one clear action per screen.
- Keep the design system: Fraunces headings, accent only on the main button.

## Do not
- Do not add social login, magic links or phone login.
- Do not build features for Today, Outreach or Money yet.
- Do not store the password or tokens yourself; rely on the Supabase session persistence.

## Done when
- Account A creates a team and gets a code. Account B on another phone joins with it. Both see the same team name and members.
- Closing and reopening the app keeps me signed in.
- A wrong password and a wrong code each show a clear, friendly message.

## Report back, then stop

When the phase is finished, update `PROGRESS.md` and commit your work. Then reply with:
1. What you built, in a few lines.
2. Exactly how I test it on my phone (numbered steps).
3. Anything you were unsure about or chose a default for.
4. The result of `flutter analyze` and `flutter test`.

Then stop and wait for my "go". Do not start the next phase.
