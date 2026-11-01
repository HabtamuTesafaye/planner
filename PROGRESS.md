# PROGRESS

This file lets any agent (Claude Code or Codex) pick up exactly where the last one stopped. Keep it short and always current.

## Current state
- Current phase: building 3 (Today) → 3b → 4 → 5 → 6 → 7 without stopping (owner's decision); report at the end
- Last completed phase: 2b (Spaces and projects backend + app spaces)
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

## Phase 3b (Projects) done
- `Project`, `ProjectItem` models, `projectProgress`; `ProjectsRepository` (realtime projects + steps per space, create with template steps, rename, status, delete with permission check, add/toggle/delete/restore steps).
- Templates in code (`lib/features/projects/templates.dart`): Blank, Client project, Product launch, Content plan, Event.
- `ProjectsController` + `ItemOverlay` (optimistic step toggles/deletes). Projects tab: cards with thin progress bar, Done section, FAB New project (sheet with template options), empty/error/skeleton. Project screen `/projects/:id`: checklist, Plan for today (uses Today's controller; respects the 3 limit; shows "Today" when planned), add step inline, swipe delete + Undo, menu (rename, mark done/active, delete with confirm).
- `core/widgets/thin_progress_bar.dart` (reused by Money). New error kind `notAllowed`.
- Tests: 178 passing.

## Phase 3 (Today) done
- `Task`, `WeeklyGoal` models; `TasksRepository` (realtime stream of my tasks, add/toggle/delete/restore), `GoalsRepository` (fetch, upsert, clear).
- `lib/core/utils/dates.dart` (week starts Monday, months, daysBetween, db date), `ids.dart` (uuid v4 for optimistic inserts).
- `TodayController` + `TaskOverlay`: optimistic add/toggle/delete/undo, pruned when the live list agrees, rolled back with a friendly message on failure. 4th task blocked in the app (no request) and by the database (same message).
- Today screen: weekday in Fraunces + date, goal card for the current space (sheet to edit/clear), "Today's three" with a 3-ring progress, task rows (CircleCheck, strike-through, space tag when >1 space, swipe right = done, left = delete + Undo, haptic at threshold), FAB "Add task" with a space picker, empty/error/skeleton states, re-reads the date on resume.
- Shared: `core/widgets/sheet_frame.dart` (`SheetFrame`, `showAppSheet`), FAB theme, PageBody `largeTitle`/`subtitle`/`bottomPadding`, all sizes as tokens.
- Tests: 168 passing (dates, ids, merge/prune, controller limit/rollback/undo, Today screen at 1.5x both themes).

## Phase 2b (spaces) done
- Owner decided: Personal space for everyone plus any number of team spaces; 3 tasks a day across ALL spaces; projects with templates inside spaces. AGENTS.md sections 1, 5.3, 6 and 9 updated; new phase files 02b and 03b.
- Migrations 011 (spaces, profile settings, new RPCs incl. leave_team(id)), 012 (projects, project_items, tasks.project_item_id, sync triggers), 013 (last_team_id not an FK; fixes account deletion). Isolation test: 132/132.
- App: Team renamed to Space throughout (`lib/features/space/`, `SpaceRepository`, `Space` model). No forced team setup: signed in → Personal. Space switcher (`SpaceSwitcher` + sheet) on Projects/Outreach/Money/Space tabs; selected space stored on the profile (`selectedSpaceIdProvider`, `currentSpaceProvider`, `pickSpace`). New space screen at `/spaces/new?mode=create|join`. 5 tabs: Today, Projects, Outreach, Money, Space. Theme follows the profile setting.
- Tests: 144 passing.

## Motion and launch polish (user request, after Phase 2)
- Native splash and launcher icon generated now (pulled forward from Phase 7): `flutter_native_splash.yaml`, `flutter_launcher_icons.yaml`. Adaptive icon with monochrome; Android 12+ splash in light and dark. The Android 12+ window background was fixed back to `@color/app_background`.
- Predictive back on (`android:enableOnBackInvokedCallback`, theme `PredictiveBackPageTransitionsBuilder`).
- `lib/core/theme/app_motion.dart` (`AppMotion`, `FadeSlideIn`), `lib/core/widgets/brand_mark.dart` (drawn mark, optional 700 ms reveal), `lib/core/widgets/fade_through_stack.dart` (tab fade-through).
- Welcome: mark draws itself, then a staggered heading, 3 points and buttons. Auth pages ease in. Team setup cross-fades between forms. Splash: centered mark matching the native splash, "Getting your team ready…" after 1.5 s, error with retry.
- Motion rules written into AGENTS.md section 7 ("Motion"). Tests in `test/core/widgets/motion_test.dart` (reduce motion, ≤250 ms, hidden tabs not tappable or readable).
- Notification icon (`assets/icon/notification.png`) still to wire in Phase 7.
- Bug fixed: tabs overlapped after switching, because TickerMode wrapped the fade and froze it. TickerMode now wraps only the tab content; a regression test checks old tab opacity reaches 0.
- Welcome: the 3-point list was replaced with `TodayPreview`, a live example card (first task ticks itself after 1.4 s; circles tappable) to fill the empty space on tall phones.

## Phase 2 (auth and team) done
- `lib/data/`: `supabase_client.dart` (init + client provider), `app_exception.dart` (the ONE place errors become friendly messages), models `Profile`, `Team`, `TeamMember`, repositories `AuthRepository`, `TeamRepository`, `ProfileRepository`.
- Providers: `currentUserIdProvider`, `authStatusProvider`, `currentProfileProvider` (auth); `currentTeamProvider`, `teamMembersProvider`, `teamStatusProvider` (team). `teamStatusProvider` treats `isReloading` (user changed) as loading, so a previous user's team is never shown.
- Router: pure `resolveRedirect` in `lib/router_redirect.dart` (splash / welcome / team setup / tabs), re-run on auth or team changes.
- Screens: Welcome, Sign up, Sign in (with "send the email again" when unconfirmed), Check email, Splash (loading, or error with retry), Team setup (new team / join with code). Temporary Team tab: name, invite code + copy, members (pull to refresh), sign out, leave team (with a confirmation that says what will happen).
- Tests: 124 passing at the end of Phase 2 (129 after the motion work) (error mapping, redirects, join code formatter, validators, models, all auth screens at 360x640 and 1.5x in both themes, wrong password and wrong code messages).
- Verified against the live backend with temporary users (since deleted): wrong password, create team, wrong code, join with lowercase and spaced code, both see the same team and members, leave.

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

- Email confirmation links open the app: `emailRedirectTo = com.elvaris.planner://login-callback` (AppConfig.authRedirectUrl), intent filter in the manifest, Flutter deep linking off. NEEDS the Redirect URL added in the Supabase dashboard.

## Open questions for the user
- Add `com.elvaris.planner://login-callback` to Supabase Redirect URLs (and set it as the Site URL).
- Set Minimum password length = 8 in Supabase Auth (the server default is 6).
- Supabase Site URL is still the default `http://localhost:3000`, so the confirmation link ends on an error page after confirming. Set a real URL, or handle it in Phase 2.
- Confirm SMTP uses a NEW Gmail app password (the old one was pasted in chat and should be revoked).

## Next step
Wait for the user's two-phone test and approval of Phase 2, then `phases/03-today.md`. Email confirmation is ON, so sign-up shows "check your email". After restarting Claude Code, optionally run `/security-review` and `/insecure-defaults:audit` (Trail of Bits) as a second opinion on Phase 1.

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
