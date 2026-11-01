# PROGRESS

This file lets any agent (Claude Code or Codex) pick up exactly where the last one stopped. Keep it short and always current.

## Current state
- Current phase: 1 (Backend): DONE, waiting for the user's approval before Phase 2
- Last completed phase: 0 (approved: the user said go)
- Tool used last: Claude Code

## Done
- Git repo, brief committed first. Skills from `docs/TOOLS.md` installed (`.agents/skills`, symlinked in `.claude/skills`).
- Flutter project, Android only, `com.elvaris.planner`, app label "Planner", minSdk 24, edge-to-edge, window colors match theme.
- Packages from AGENTS.md section 3 added and pinned (plus `share_plus`). Strict lints. Core library desugaring on (required by `flutter_local_notifications`).
- Folder structure from AGENTS.md section 8.
- `AppConfig` reads `SUPABASE_URL` / `SUPABASE_ANON_KEY` via dart-define; "Setup needed" screen when missing. `env/example.json` committed; `env/*.json` and `env/*.db-password` git-ignored.
- Theme system in `lib/core/theme/` (tokens as `AppColors` ThemeExtension, spacing, radius, text styles, component themes). Fonts Fraunces + Manrope bundled (static TTFs, OFL).
- Shared widgets: `CircleCheck`, `Skeleton`/`SkeletonList`, `EmptyState`, `SectionHeader`, `OfflineBanner` (visual only), `PageBody`, `AppShell`, `SetupNeededScreen`.
- go_router shell with 4 tabs (Today, Outreach, Money, Team), each with a title and empty state.
- Tests: contrast (all token pairs, both themes), theme smoke, config, CircleCheck semantics and 48 dp target, 4 tabs at 360x640 and 1.5x font in both themes, setup screen. 67 passing; `flutter analyze` clean.
- App icon set drawn in `assets/icon/` by `assets/icon/src/make_icons.py` (not wired yet: Phase 7).
- Supabase project `planner-staging` created via CLI (ref `jhdzewceymvxpdbxcpbd`, eu-central-1). `env/staging.json` holds URL + anon key only. DB password in `env/staging.db-password` (git-ignored, chmod 600).

## Phase 1 (backend) done
- Migrations 001–010 in `supabase/migrations/`, pushed to `planner-staging` cleanly in order. 010 adds column-level UPDATE grants (hardening found in the audit).
- Helpers in the `private` schema (not exposed): `is_team_member`, `is_team_owner`, `shares_team_with`, `generate_join_code`, triggers. RPCs in public: `create_team`, `join_team`, `leave_team` (error codes listed in README).
- `supabase/tests/rls_isolation.sql`: 98/98 pass (run with `npx supabase@2.122.0 db query --linked -f ...`).
- Advisors: 3 expected warnings (the RPCs, accepted by design), no performance issues. Anon key probes: everything denied.
- README backend section and `docs/security-audit.md` Phase 1 section written.
- The CLI is linked (`supabase/.temp` is git-ignored). Push with `SUPABASE_DB_PASSWORD="$(cat env/staging.db-password)" npx supabase@2.122.0 db push --linked`.

## Phase 0 notes
- Verified on the Redmi phone (adb `VCXG7LF6ROVOCUKV`, Android 16): app launches, edge-to-edge, light and dark themes correct, no Flutter errors in logcat. adb input injection is blocked on this Xiaomi, so tab taps were checked by the user and by widget tests.
- Phase 0 security audit in `docs/security-audit.md`. Fixed: INTERNET permission for release builds, backups disabled.
- Trail of Bits security plugins installed (see `docs/TOOLS.md`).
- Xiaomi needs "Install via USB" on, and the user taps Install on each adb install.

## Decisions made (and why)
- Package id `com.elvaris.planner`, app name "Planner" (user). Assumptions 1, 2, 3, 5 confirmed.
- Palette changed by the user to stormy blue + soft beige-gray (AGENTS.md section 7 updated). Added an `attention` token (warm clay) for overdue items and errors, because blue does not signal urgency. Every pair is checked by `contrast_test.dart`.
- `accentText` token kept (equals `accent` now) so the brand color can change without breaking text contrast.
- Text scale is clamped at 1.5x (AGENTS.md section 4).
- Email confirmation is ON in staging (user enabled it), using custom Gmail SMTP set in the Supabase dashboard. Phase 2 sign-up must show "check your email" and then sign in; no deep links in v1 unless the user asks.
- Icon: user picked an AI concept (circle with check above three rings); redrawn as clean vector-style PNGs with exact brand colors.

- Mobile-design skill (vudovn/antigravity-kit) installed; haptics added to CircleCheck and tab change. AGENTS.md section 7 has the haptics rule.
- Phase 1 created 10 migrations (spec listed 9): 010 is a security hardening, kept separate so it never rewrites an applied migration.
- RLS is enabled in each table's own migration (stricter than the spec's "in 007"), so no table ever existed without RLS.

## Open questions for the user
- Set Minimum password length = 8 in Supabase Auth (the server default is 6).
- Supabase Site URL is still the default `http://localhost:3000`, so the confirmation link ends on an error page after confirming. Set a real URL, or handle it in Phase 2.
- Confirm SMTP uses a NEW Gmail app password (the old one was pasted in chat and should be revoked).

## Next step
Wait for the user's approval of Phase 1, then `phases/02-auth-and-team.md`. Email confirmation is ON, so sign-up shows "check your email". After restarting Claude Code, optionally run `/security-review` and `/insecure-defaults:audit` (Trail of Bits) as a second opinion on Phase 1.

## How to test the latest work
Phase 1:
1. `npx supabase@2.122.0 db query --linked -f supabase/tests/rls_isolation.sql`: the last row must read "SUMMARY: 98 passed, 0 failed".
2. Dashboard → Table Editor: 9 tables, each with "RLS enabled".

Phase 0:
1. `flutter pub get`
2. Phone connected with USB debugging on.
3. `flutter run --dart-define-from-file=env/example.json` (or `env/staging.json`).
4. Check 4 tabs, switch the phone between light and dark mode, set the font size to the largest.
5. `flutter run` without the define shows the "Setup needed" screen.
