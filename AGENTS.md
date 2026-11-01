# AGENTS.md: Planner (Flutter + Supabase)

You are the lead developer for a small Android app. This file is the permanent reference: product, stack, design system, security and rules. Read it fully once.

The work is split into phase files in `phases/`. Only work on the phase file you are told to work on. Stop at the end of each phase, report back, and wait for approval.

---

## 1. Objective

A calm, polished planner for people and small teams. Everyone has a private **Personal space** and can create or join any number of **team spaces**. Inside each space you keep **projects** (started from templates, each with a checklist), a business **outreach** pipeline, and a monthly **income** number against a target. Across all spaces, each person plans **one focused day: at most 3 tasks**, pulled from any space or project.

The app is successful if people open it every day because it is fast, clear and pleasant. Simplicity beats features.

### What makes it different (keep these sharp)
1. **One focused day.** Today shows at most 3 tasks across *all* your spaces, each tagged with its space. Other planners let lists grow forever.
2. **Backlog lives in projects, focus lives in Today.** Any project step can be "planned for today" in one tap, which uses one of the 3 slots.
3. **Templates** start a project with sensible steps (client project, product launch, content plan, event), so nothing starts blank.
4. **Outreach and income next to the plan**, in the same space, for freelancers and small teams.
5. **Weekly review** feeds next week's goal for the space.

### In scope (v1)
- Email + password accounts
- Spaces: an automatic Personal space for every user (private, cannot be left or joined), plus any number of team spaces (create, join with an invite code, leave). A space switcher at the top of the app.
- Today: max 3 tasks per person per day **across all spaces**, plus one "goal of the week" for the current space
- Projects: per space, created from a template or blank, each with a checklist; plan a step for today
- Outreach: pipeline of contacts per space with status and follow-up dates
- Money: monthly income entries (ETB) per space against a monthly target
- Space: members' progress, invite code, leave space, settings
- Weekly review: 3 short questions per person per space, visible to the space
- Light and dark theme, daily reminder notification

### Out of scope (do NOT build)
- Chat, comments, file uploads, avatars, push notifications from the server
- Offline editing and sync (see section 5.5, handle offline gracefully only)
- Social login, phone login, magic links, analytics, ads, in-app purchases
- iOS, web, desktop. Android phones only
- Admin panels, roles beyond owner and member, nested projects, due-date calendars, Gantt charts, custom templates created by users (built-in templates only in v1)

---

## 2. Assumptions (confirm before Phase 0)

Before writing any code, send ONE message asking me to confirm or correct these. Ask at most 5 questions total and then continue with these defaults if I do not answer.

1. Team members can see everything inside their team: each other's tasks, goal, reviews, contacts and income.
2. Currency is Ethiopian Birr (ETB), shown as `12,500 ETB`.
3. Email confirmation is OFF in staging (Supabase default email sending is rate limited). We turn it on later with custom SMTP.
4. App name: "Planner" (placeholder). Package id: `com.example.planner` (placeholder).
5. The week starts on Monday.

---

## 3. Tech stack and libraries

Use the latest stable Flutter and Dart. After adding packages, pin the resolved versions in `pubspec.yaml` and do not upgrade them casually. If a package below is discontinued or incompatible, pick the closest maintained alternative and tell me why.

| Purpose | Package | Notes |
|---|---|---|
| State management | `flutter_riverpod` | No code generation. Plain `Notifier`, `AsyncNotifier`, `StreamProvider`. |
| Navigation | `go_router` | Shell route with 4 bottom tabs, auth redirect. |
| Backend client | `supabase_flutter` | Auth, Postgres, Realtime. |
| Dates and numbers | `intl` | ETB formatting, date formats. |
| Connectivity | `connectivity_plus` | Only to show an offline banner. |
| Local notifications | `flutter_local_notifications`, `timezone`, `flutter_timezone` | One daily reminder. Use inexact scheduling, do NOT request exact-alarm permission. |
| Icons | `material_symbols_icons` | Outlined style, weight 300. |
| App icon / splash | `flutter_launcher_icons`, `flutter_native_splash` | Dev dependencies. |
| Lints | `flutter_lints` | Plus `very strict` analysis: no warnings allowed. |
| Tests | `flutter_test`, `mocktail` | |

Do NOT add: `google_fonts` (fonts are bundled), Firebase, GetX, Bloc, `freezed`, `json_serializable`, `build_runner`, UI kits (no GetWidget, no flutter_screenutil). Write small immutable model classes by hand with `fromJson` and `toJson`.

### Fonts (bundled, not downloaded at runtime)
- **Fraunces**: headings, the date, big numbers
- **Manrope**: everything else
Declare both in `pubspec.yaml` under `assets/fonts/`. I will place the font files there. Until then, fall back to the system serif and sans and do not crash.

### UI components (use Flutter Material 3, heavily themed)
Use `useMaterial3: true` and build the `ColorScheme` by hand from the tokens below, not `fromSeed`. Style these through `ThemeData` component themes so screens stay clean:

| Need | Use |
|---|---|
| Bottom navigation | `NavigationBar` (themed, no indicator pill color clash) |
| Primary / secondary buttons | `FilledButton`, `OutlinedButton`, `TextButton` |
| Task checkbox | Custom circular animated check widget (not the default `Checkbox`) |
| Status and filters | `FilterChip`, `SegmentedButton` |
| Add and edit forms | `showModalBottomSheet` (scroll controlled, drag handle, keyboard-safe) |
| Dates | `showDatePicker`, themed |
| Text input | `TextFormField` with one shared `InputDecorationTheme` |
| Feedback | Floating `SnackBar`, with Undo where it makes sense |
| Swipe actions | `Dismissible` (complete, delete) |
| Pull to refresh | `RefreshIndicator` |
| Loading | Simple custom skeleton boxes (no shimmer package) |
| Progress | Custom thin progress bar (no `CircularProgressIndicator` except for tiny inline loading) |
| Animation | Implicit animations only (`AnimatedContainer`, `AnimatedSwitcher`, `AnimatedOpacity`, `TweenAnimationBuilder`). Each movement max 200 to 250 ms. See "Motion" in section 7. |

---

## 4. Compatibility (must work on any Android device)

- `minSdk` 24 (Android 7.0). `targetSdk` and `compileSdk`: the latest Flutter supports.
- Test mentally and with emulators: small phone (360 x 640 dp), normal phone, large phone, foldable, tablet.
- On wide screens, center content with a max width of 600 dp.
- Respect system font scaling up to 1.5x with no overflow or clipped text. Use `Flexible`, `Expanded`, `Wrap`, and scrollable bodies.
- Support edge-to-edge (Android 15) with correct `SafeArea` and system bar icon colors in light and dark.
- Support gesture navigation and 3-button navigation.
- Android 13+ notification permission must be requested politely, with a clear explanation, and the app must work if denied.
- Low-end devices (2 GB RAM): use `ListView.builder` for lists, `const` constructors, no heavy images, no blur, no large shadows.
- Release build: R8/minify enabled, `flutter build apk --release --split-per-abi`. APK per ABI should stay small.
- Locale: English UI. Dates and numbers via `intl`. Do not hardcode date formats.

---

## 5. Backend: Supabase

I have (or will create) a Supabase project named `planner-staging`. Use the free plan.

### 5.1 Free plan facts to respect
- 500 MB database, 50,000 monthly active users, 2 free projects, no daily backups.
- Free projects are paused after 7 days of inactivity. Daily use keeps it awake. If it pauses, the dashboard restore button fixes it. Mention this in the README.

### 5.2 Config
- Read the Supabase URL and anon key from `--dart-define-from-file=env/staging.json`.
- Commit `env/example.json`. Add `env/*.json` (except example) and `*.jks`, `key.properties` to `.gitignore`.
- The anon key is public by design. Security comes from Row Level Security (RLS), not from hiding the key. NEVER put the `service_role` key in the app or the repo.

### 5.3 Schema (create as SQL migrations in `supabase/migrations/`)

| Table | Columns |
|---|---|
| `profiles` | `id uuid pk references auth.users`, `display_name text not null`, `created_at` |
| `teams` | `id uuid pk`, `name text`, `join_code text unique` (8 chars, no ambiguous characters like 0/O/1/I), `created_by uuid`, `created_at` |
| `team_members` | `team_id`, `user_id`, `role text check in ('owner','member')`, `joined_at`; pk `(team_id, user_id)`; unique `user_id` (one team per user in v1) |
| `tasks` | `id`, `team_id`, `user_id`, `title text (1..120)`, `day date`, `done bool`, `done_at`, `created_at` |
| `weekly_goals` | `team_id`, `user_id`, `week_start date`, `goal text`; pk `(team_id, user_id, week_start)` |
| `contacts` | `id`, `team_id`, `owner_id`, `name`, `business`, `channel`, `status` (contacted, replied, meeting, proposal, paid, dead), `next_follow_up date null`, `price numeric null`, `notes`, `created_at`, `updated_at` |
| `income_entries` | `id`, `team_id`, `user_id`, `month date` (first day of month), `amount numeric(12,2) > 0`, `note`, `created_at` |
| `monthly_targets` | `team_id`, `month date`, `target numeric(12,2)`; pk `(team_id, month)` |
| `weekly_reviews` | `id`, `team_id`, `user_id`, `week_start`, `did text`, `blocked text`, `next_goal text`; unique `(team_id, user_id, week_start)` |

**Spaces update (2026-11-01).** "Team" in table and function names means *space*:
- `teams.kind text check in ('personal','team')`. Each user has exactly one personal space, created by the sign-up trigger; it has no join code, cannot be joined and cannot be left. `team_members` no longer has `unique (user_id)`.
- `profiles.last_team_id` remembers the selected space; `profiles.theme` and `profiles.reminder_time` hold settings (so no extra local-storage package is needed).
- `projects`: `id`, `team_id`, `name (1..80)`, `template`, `status ('active','done')`, `created_by`, `created_at`, `updated_at`.
- `project_items`: `id`, `project_id`, `team_id` (copied from the project, for RLS and realtime filters), `title (1..200)`, `done`, `done_at`, `position`, `created_by`, `created_at`.
- `tasks.project_item_id uuid null` links a Today task to the project step it came from.
- Projects and steps are shared inside the space: members read and write; delete by creator or space owner.

Rules:
- A database trigger must reject a 4th task for the same `user_id` and `day` (across all spaces). The app also enforces it, but the database is the source of truth.
- Auto-create a `profiles` row on signup with a trigger.
- Add indexes for `team_id`, `(user_id, day)` and `(team_id, next_follow_up)`.

### 5.4 Security (RLS) and RPCs
- Enable RLS on EVERY table. No table may be readable by anonymous users.
- Create a `security definer` helper `is_team_member(team_id uuid)` with a fixed `search_path`, and use it in policies.
- Read: any team member can read all rows of their team.
- Write: `tasks`, `weekly_goals`, `weekly_reviews` only for the row owner (`user_id = auth.uid()`). `contacts` and `income_entries` and `monthly_targets` insertable and editable by any team member. Delete on shared tables only by the creator or the team owner.
- RPC `create_team(name)`: creates the team, a unique join code and the owner membership in one transaction.
- RPC `join_team(code)`: adds the caller as member, fails clearly if the code is wrong or the user is already in a team. Do not reveal whether a code exists beyond success or failure.
- RPC `leave_team()`: removes the caller. If the owner leaves and others remain, promote the oldest member. If no members remain, delete the team.
- Write SQL tests (or a documented manual test script) with two test users proving: user A cannot read or write team B's data, and a user cannot see another team's rows through any table.

### 5.5 Realtime and offline
- Use Supabase Realtime streams filtered by `team_id` for `tasks`, `contacts`, `income_entries` so teammates see changes within seconds. Enable replication for those tables in a migration.
- v1 is online-first. Do not build offline editing. When there is no connection: show a clear banner, disable save buttons with a short reason, keep the last loaded data on screen, retry automatically when the connection returns, and never crash or lose what the user typed in an open form.

---

## 6. Screens and behavior

Bottom tabs: **Today, Projects, Outreach, Money, Space**. A **space switcher** sits at the top of every tab except Today: tap it to switch space, create a team space or join one with a code. The selected space is remembered (stored on the profile).

**Auth**: welcome screen, sign up (name, email, password), sign in. No team is required: after sign-in you land in your Personal space. Session persists. Friendly error messages (wrong password, no connection, email in use).

**Projects**
- List of the current space's projects with a thin progress bar (steps done / total) and status (active, done).
- New project: name plus a template (Blank, Client project, Product launch, Content plan, Event). Templates pre-fill checklist steps; built into the app, not stored.
- Project detail: checklist steps (add, check off, delete with Undo), rename, mark done, delete (creator or space owner). Each step has "Plan for today", which creates a Today task linked to it (respects the 3-task limit). Completing the task completes the step.

**Today**
- Big date in Fraunces, then the "Goal of the week" for the current space (tap to edit).
- My tasks for today from every space, each tagged with its space name. Up to 3 tasks in total. Adding a 4th shows a clear, kind message ("Three is the limit. Finish or remove one first."). Completing a task animates the check and strikes through the title. Swipe to delete with Undo.
- Link to "Weekly review". Shows a gentle prompt on Sunday and Monday only.
- Empty state: one short line and one button.

**Outreach**
- Filter by status (`SegmentedButton` or chips) and "Mine / Everyone".
- Sorted with overdue follow-ups first, shown in the attention color with "3 days overdue".
- Add and edit in a bottom sheet. Quick status change from the list. Mark "followed up today" in one tap (sets next follow-up with a date picker).

**Money**
- Large this-month total vs target with a thin progress bar, big numbers in Fraunces.
- Add income entry (amount, note). List of entries with who added them. Previous months list.
- Set or edit the monthly target.

**Space** (was "Team")
- Personal space: create a team space, join with a code, settings.
- Team space: one card per member: name, today's tasks done out of 3, tasks completed this week, contacts added this week, current weekly goal, last review date. Derived from existing tables, no extra tables.
- Invite code with a copy button and a share sheet (`share_plus` is allowed for this single use).
- Settings: daily reminder time, theme (system, light, dark), sign out, leave space (team spaces only).

**Weekly review**: 3 text fields (what I did, what is blocked, next week's goal). One per user per week, editable. Teammates' reviews are readable in a list.

---

## 7. Design system

Feel: a calm, reliable planner. Stormy blue on soft beige-gray: trustworthy, secure, quiet. Editorial and spacious. Not a startup dashboard.

### Tokens (define once in `lib/core/theme/`)

| Token | Light | Dark |
|---|---|---|
| Background (soft beige-gray) | `#F3F1EC` | `#121519` |
| Surface | `#FFFFFF` | `#1A1E24` |
| Sunken surface (skeletons, tracks) | `#E9E6DF` | `#232830` |
| Text | `#1B2430` | `#ECEEF1` |
| Muted text | `#5D6570` | `#9BA4AF` |
| Divider | `#E2DFD8` | `#272C34` |
| Border (inputs, outlined buttons) | `#828993` | `#6B7380` |
| Accent, stormy blue (primary actions, active tab, links) | `#2E4A6B` | `#8EB0D6` |
| Accent soft (selected chip, nav indicator) | `#E1E8F0` | `#1F2C3C` |
| Attention, warm clay (overdue, errors) | `#A9431A` | `#F0905F` |
| Success (completed) | `#2A7046` | `#5BB27F` |

Text on the accent uses white in light mode and `#121519` in dark mode.

Check text contrast (WCAG AA, 4.5:1) for every text and background pair, including the accent and attention colors on both themes, and 3:1 for borders and icons. `test/core/theme/contrast_test.dart` enforces this.

- Spacing scale: 4, 8, 12, 16, 24, 32. Corner radius: 12 for inputs and buttons, 16 for sheets. No heavy shadows; use dividers and surface color instead.
- Type scale: Fraunces for display (date, big numbers, screen titles). Manrope for body 15 to 16, labels 13, with real hierarchy. Numbers use tabular figures.
- Icons: outlined, consistent size 22 to 24. No emoji as icons.
- Touch targets at least 48 x 48 dp. Primary actions in the bottom half of the screen (thumb zone); destructive actions never in the easiest-to-reach spot.
- Haptics: light haptic when completing a task, selection tick on tab change and filter change, and at a swipe-action threshold. Use Flutter's built-in `HapticFeedback` only (no package). Never on every scroll or keystroke.
- Every screen has designed loading (skeleton), empty and error states with short, human copy. No lorem ipsum, no "Something went wrong" alone.
- Accessibility: semantic labels on icon buttons and the custom checkbox, correct focus order, works with TalkBack.

### Motion (calm, quick, never in the way)
Helpers live in `lib/core/theme/app_motion.dart` (`AppMotion`, `FadeSlideIn`). Use them instead of ad hoc animations.
- Each movement lasts 250 ms or less. Entrances may be staggered (`FadeSlideIn(index: n)`, 60 ms apart), but every element still moves for at most 250 ms.
- Material 3 easing: `AppMotion.enter` (emphasized decelerate) for arriving, `AppMotion.exit` for leaving.
- Page transitions: Android predictive back (`PredictiveBackPageTransitionsBuilder`, enabled in the manifest). Tabs: 200 ms fade-through (`FadeThroughStack`), keeping every tab's state.
- Launch: native splash (icon mark on the page color, light and dark), then the in-app splash with the same mark in the same place. The Welcome screen draws the mark (`BrandMark(animate: true)`) and staggers the content in.
- Use motion to explain change (something arrived, was completed, moved), never as decoration on every element.
- Respect the system "Remove animations" setting: `AppMotion.reduced(context)` makes everything appear at once.
- Performance: no blur, no shadows, no looping animations on screen (except loading skeletons), animate only small subtrees, pass static children through `child:`.

### Avoid (this is what makes apps look AI-generated)
Purple gradients, glassmorphism, identical rounded cards stacked everywhere, default Material blue, centered stock illustrations, shadows on everything, big colored headers, "Welcome back!" style filler copy, emoji decoration.

---

## 8. Architecture

```
lib/
  main.dart
  app.dart                  # MaterialApp.router, theme, router
  core/
    theme/                  # tokens, light/dark ThemeData, text styles
    config/                 # env, constants
    widgets/                # shared small widgets (CircleCheck, Skeleton, EmptyState, OfflineBanner)
    utils/                  # date and currency helpers
  data/
    supabase_client.dart
    repositories/           # one repository per table group, no widgets here
    models/                 # plain immutable classes
  features/
    auth/  today/  outreach/  money/  team/  review/
      (each: screens/, widgets/, providers/)
supabase/migrations/
test/
```
Rules: UI never calls Supabase directly, only repositories through Riverpod providers. Keep files under about 250 lines. Small widgets, `const` where possible.

---

## 9. Phases (one file each, stop after each one)

Each phase has its own file in `phases/` with its objective, tasks, do and do-not lists, and a done-when test. Follow that file exactly and do not start the next one early.

After each phase: summarize what changed, tell me exactly how to test it on my phone, list anything you were unsure about, and wait for my "go".

**Update (owner's decision, 2026-11-01):** from Phase 2b on, build the remaining phases one after another without stopping, committing after each and keeping `PROGRESS.md` current. Report once at the end; the owner reviews everything together.

| Phase | Work | Done when |
|---|---|---|
| **0. Foundation** (`phases/00-foundation.md`) | Questions from section 2. Flutter project, lints, folder structure, env config, theme tokens, fonts, 4-tab shell with empty states, light and dark. | App runs on my phone, 4 tabs look right in both themes, `flutter analyze` is clean. |
| **1. Backend** (`phases/01-backend.md`) | All migrations, triggers, RLS, RPCs, SQL tests or manual test script, README setup steps for Supabase. | I can run the migrations on a fresh project and the two-user isolation test passes. |
| **2. Auth and team** (`phases/02-auth-and-team.md`) | Sign up, sign in, session persistence, create team, join with code, leave team, sign out, router redirects. | Two accounts on two phones end up in the same team. |
| **2b. Spaces and projects backend** (`phases/02b-spaces-and-projects.md`) | Personal space per user, many team spaces, space switcher, projects and steps tables, RLS, tests. | A new account lands in its Personal space; it can create and join team spaces and switch between them. |
| **3. Today** (`phases/03-today.md`) | Tasks, 3-task limit (app and database), weekly goal, realtime updates, animations, Undo. | A task added on one phone appears within seconds on a second phone signed in to the same account, and a 4th task is blocked in both the app and the database. |
| **3b. Projects** (`phases/03b-projects.md`) | Projects list, templates, checklist, plan a step for today, realtime. | A project from a template shows its steps; planning a step adds it to Today and respects the limit. |
| **4. Outreach** (`phases/04-outreach.md`) | Contacts CRUD, filters, overdue sorting, quick status and follow-up actions, realtime. | I can log 10 contacts and see them on my teammate's phone. |
| **5. Money** (`phases/05-money.md`) | Entries, target, progress bar, month history. | Totals are correct across month boundaries. |
| **6. Space and review** (`phases/06-team-and-review.md`) | Team progress cards, invite code share, settings, weekly review. | Both founders see each other's progress and reviews. |
| **7. Polish and release** (`phases/07-polish-and-release.md`) | Offline banner and handling, daily reminder, accessibility pass, small-screen and large-font pass, performance pass, app icon and splash, signed release APK, README. | Works on a small old Android device and a large one, release APK installs. |

---

## 10. Do and Do not

**Do**
- Keep every screen simple and fast. One main thing per screen.
- Ask when something important is unclear, and otherwise pick the simplest reasonable option and tell me.
- Handle every async state: loading, empty, error, offline.
- Validate input (lengths, empty values, amounts above zero) on the client and in the database.
- Write tests for: the 3-task limit, date and week helpers, ETB formatting, repository mapping, and the RLS isolation.
- Keep secrets out of git.
- Commit in small steps with clear messages, one phase per branch or tag.

**Do not**
- Do not add features, packages or screens I did not ask for.
- Do not use `setState` for shared or server state, global mutable singletons, or `print` in committed code (use a tiny logger).
- Do not disable RLS, use the `service_role` key in the app, or write security logic only on the client.
- Do not swallow errors silently or show raw exception text to the user.
- Do not hardcode colors, sizes or fonts inside screens; use the theme tokens.
- No raw numbers in widgets: every size, gap, radius, stroke and duration comes from a named token (`AppSpacing`, `AppSizes`, `AppRadius`, `AppDurations`, `AppTextStyles`). If a new size is needed, add a token first. Sizes are in dp (density-independent); layouts stay flexible (`Expanded`, `Flexible`, `Wrap`, `FractionallySizedBox`, max width 600 dp). Fixed dp is right for touch targets (min 48 dp) and icons; proportions are right for layout.
- Do not use deprecated APIs. Fix analyzer warnings instead of ignoring them.
- Do not start the next phase before I approve the current one.

---

## 11. Quality gates (every phase)

1. `flutter analyze` has zero issues.
2. `flutter test` passes.
3. No overflow errors at font scale 1.5 on a 360 x 640 screen.
4. Both themes checked for contrast and readability.
5. Works with the network turned off after login (banner shown, no crash).
6. The README is updated with any new setup step.

Start with `phases/00-foundation.md`.

---

## 12. Skills and tools

- Follow `docs/TOOLS.md` for which skills to install and how. Installed skills trigger automatically when relevant.
- `AGENTS.md` overrides any skill advice. This project uses Riverpod without code generation, hand-written models, go_router, and bundled fonts, even if a skill suggests something else.
- Do not install skills, plugins or MCP servers that are not in `docs/TOOLS.md` without asking me first.

## 13. Working across tools (Claude Code and Codex)

I may switch between Claude Code and Codex when one runs out of quota. So:
1. At the start of every session read `AGENTS.md`, then `PROGRESS.md`, then the current phase file.
2. Commit often, in small steps.
3. Update `PROGRESS.md` after each task and always before stopping.
4. Never assume previous chat history exists. The repository and `PROGRESS.md` are the memory.
