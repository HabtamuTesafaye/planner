# HANDOFF: start here if you are a new agent

You are picking up **Planner**, an Android app (Flutter + Supabase). This file tells you what exists, what is finished, what is open, and how to work without breaking anything. Read it fully, then `AGENTS.md` (the rules), then `PROGRESS.md` (the detailed log).

Repo: https://github.com/HabtamuTesafaye/planner (public). Default branch `main`.

---

## 1. State right now (2026-11-01)

- **All planned phases are built:** 0–7, plus 2b (spaces) and 3b (projects). Tags `phase-0` … `phase-7`.
- **Open PR:** `feature/insights-dashboard` adds the Insights dashboard (activity heatmap, weekly bars, stat tiles, income per month, outreach breakdown). Review and merge it first.
- **Owner status:** the owner is testing on a Redmi phone (Android 16) and will send comments. Nothing is blocked on code.
- **Checks on `main` + the PR:** `flutter analyze` clean; `flutter test` 235 passing; DB isolation test 139/139.

## 2. What the app does

Everyone has a private **Personal space** and can create or join any number of **team spaces** (switcher at the top of each tab). Tabs:

| Tab | Purpose |
|---|---|
| Today | Max **3 tasks per day across all spaces**, goal of the week, review prompt on Sun/Mon, Insights button |
| Projects | Projects from templates, checklists, "Plan for today" |
| Outreach | Leads, status, overdue-first follow-ups |
| Money | ETB income vs monthly target, history |
| Space | Member progress, weekly review, invite, settings |

Product rules, design tokens, motion rules, security rules: **`AGENTS.md`** (it overrides any skill or habit).

## 3. Where things are

```
lib/core/        theme (tokens, motion), widgets (PageBody, SheetFrame, PrimaryButton, …), utils (dates, money, ids, validators)
lib/data/        Supabase client, AppException (all error → message mapping), models, repositories, connectivity, reminders
lib/features/    auth, today, projects, outreach, money, space, review, insights  (screens / widgets / providers / *_logic.dart)
lib/router.dart  routes;  lib/router_redirect.dart  pure redirect logic
supabase/migrations/001–014   schema, RLS, RPCs (apply in order)
supabase/tests/rls_isolation.sql   the security test (must stay green)
test/            unit + widget tests (mirror lib/)
docs/            security-audit.md, qa-checklist.md, TOOLS.md
```

Patterns to keep:
- UI → Riverpod providers → repositories → Supabase. UI never calls Supabase.
- Pure logic lives in `*_logic.dart` and is unit-tested.
- Optimistic UI uses an overlay notifier (`TodayController`, `ProjectsController`) that is pruned when the live stream agrees.
- **No raw numbers in widgets.** Every size, colour and duration comes from tokens (`AppSpacing`, `AppSizes`, `AppRadius`, `AppDurations`, `AppColors`).
- Motion ≤ 250 ms per movement via `FadeSlideIn` / `AppMotion`; respects "Remove animations".

## 4. How to run, test and ship

```
flutter pub get
flutter run --dart-define-from-file=env/staging.json          # needs env/staging.json (git-ignored)
flutter analyze && flutter test                               # must be clean / green
npx supabase@2.122.0 db query --linked -f supabase/tests/rls_isolation.sql   # last row: all passed
SUPABASE_DB_PASSWORD="$(cat env/staging.db-password)" npx supabase@2.122.0 db push --linked   # new migrations
flutter build apk --release --split-per-abi --dart-define-from-file=env/staging.json
```
Release builds need `android/key.properties` (git-ignored) pointing at `~/keys/planner-release.jks`. They fail on purpose without it.

Secrets that are **never** in git: `env/staging.json`, `env/staging.db-password`, `android/key.properties`, the keystore. Never use the Supabase `service_role` key anywhere.

Device: Xiaomi blocks automated taps and asks the user to tap Install for every `adb install`. Screenshots work (`adb exec-out screencap -p`); don't capture when the notification shade is focused (private notifications).

## 5. Open items

| Item | Owner | Where |
|---|---|---|
| Back up `~/keys/planner-release.jks` + `android/key.properties` | Owner | GitHub issue |
| Supabase: Redirect URL `com.elvaris.planner://login-callback`, min password length 8, leaked-password protection | Owner | GitHub issue |
| Revoke the Gmail app password that was pasted in chat | Owner | GitHub issue |
| Device checks not automatable here: TalkBack walk-through, reminder arrives, airplane mode, Android 7 phone | Owner | `docs/qa-checklist.md` (👤 rows), GitHub issue |
| AI features (optional, proposed): weekly review summary, plan-my-day, outreach follow-up drafts via a Supabase Edge Function | Next agent, after owner says go | GitHub issue |

## 6. Working rules (from AGENTS.md and the owner)

- Work on a branch, open a PR with `gh`, keep commits small; update `PROGRESS.md` and this file before you stop.
- Ask before adding packages, skills or services that aren't in `AGENTS.md` / `docs/TOOLS.md`.
- Database changes: new numbered migration (never edit applied ones), extend `rls_isolation.sql`, run `db advisors`, update `docs/security-audit.md`.
- Test every screen at 360×640 dp with 1.5× text in both themes (`test/helpers.dart` → `useSmallPhone`).
- The owner prefers plain explanations, a working build on the phone, and being told clearly what still needs their action.
