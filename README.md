# Planner

A calm daily planner for a two-person founding team: three tasks a day, a goal of the week, a shared outreach pipeline, monthly income against a target, and a weekly review. Android only. Flutter + Supabase.

The build brief lives in `AGENTS.md` (product, stack, design, rules) and `phases/` (one file per phase). Progress is tracked in `PROGRESS.md`.

## Requirements

- Flutter stable (built with 3.47.9 / Dart 3.13.7)
- Android SDK 36, a phone or emulator on Android 7.0 (API 24) or newer
- Node.js (only for `npx supabase` and the agent skills)

## Run it

1. Get packages:
   ```
   flutter pub get
   ```
2. Create your env file from the example. It is git-ignored, so it never gets committed:
   ```
   cp env/example.json env/staging.json
   ```
   Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY` from the Supabase dashboard (Project Settings → API). Only the **anon** key goes here. Never use the `service_role` key in the app or the repo.
3. Run on a connected phone:
   ```
   flutter run --dart-define-from-file=env/staging.json
   ```

If you run without `--dart-define-from-file`, the app shows a **Setup needed** screen explaining what is missing instead of crashing.

Until the Supabase project exists (Phase 1), you can run with the example file to see the UI:
```
flutter run --dart-define-from-file=env/example.json
```

## Checks

```
flutter analyze   # must report no issues
flutter test      # includes the WCAG contrast test for every color pair
```

## Fonts

Fraunces (headings, dates, big numbers) and Manrope (everything else) are bundled in `assets/fonts/` as static TTFs from Google Fonts, under the SIL Open Font License (license files are next to the fonts). Nothing is downloaded at runtime.

## Design notes

- All colors, spacing, radii and type live in `lib/core/theme/`. Screens read them via `context.colors` and `context.text`.
- Palette: stormy blue accent (`#2E4A6B` light, `#8EB0D6` dark) on soft beige-gray (`#F3F1EC` light, `#121519` dark), with a warm clay **attention** color (`#A9431A` / `#F0905F`) for overdue items and errors. Full table in `AGENTS.md` section 7.
- Every text pair passes WCAG AA (4.5:1) and every border and icon passes 3:1 in both themes. `test/core/theme/contrast_test.dart` checks this, so a color change that breaks contrast fails the tests.
- Font scaling is honored up to 1.5x.

## App icon

The icon set lives in `assets/icon/`. It is drawn by `assets/icon/src/make_icons.py` (Pillow only) from one set of shapes: a filled blue circle with a check (one task done) above three empty rings (three tasks a day). To change colors or shapes, edit the constants at the top of the script and run:
```
python3 assets/icon/src/make_icons.py
```
It is wired into the launcher and splash in Phase 7.

## Release signing (not committed)

Release builds read `android/key.properties`, which is git-ignored. Without it, release builds are signed with the debug key so `flutter run --release` works locally. The full release steps come in Phase 7. In short:

1. Create a keystore outside the repo:
   ```
   keytool -genkey -v -keystore ~/keys/planner-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias planner
   ```
2. Create `android/key.properties`:
   ```
   storePassword=...
   keyPassword=...
   keyAlias=planner
   storeFile=/home/you/keys/planner-release.jks
   ```
3. Back up the keystore and passwords somewhere safe. If you lose them, you can't ship updates to the same app.

## Supabase (backend)

The backend is a Supabase project (staging: `planner-staging`, region eu-central-1). Everything lives in `supabase/migrations/`, numbered and meant to be read top to bottom.

### Set up a fresh project
1. **Create the project.** Use the dashboard (New project, name `planner-staging`, free plan, region Frankfurt), or the CLI:
   ```
   npx supabase@2.122.0 login
   npx supabase@2.122.0 projects create planner-staging --org-id <your-org-id> --region eu-central-1 --db-password '<strong password>'
   ```
   Keep the database password in a password manager. Locally it can live in `env/staging.db-password` (git-ignored).
2. **App keys.** In Project Settings → API, copy the **Project URL** and the **anon** key into `env/staging.json` (see `env/example.json`). Never copy the `service_role` key anywhere.
3. **Run the migrations, in order:**
   ```
   npx supabase@2.122.0 link --project-ref <project-ref>
   SUPABASE_DB_PASSWORD="$(cat env/staging.db-password)" npx supabase@2.122.0 db push --linked
   ```
   No CLI? Paste each file from `supabase/migrations/` into the dashboard SQL editor, in number order.
4. **Auth settings** (dashboard → Authentication):
   - Sign In / Providers → Email: enabled. Set **Minimum password length** to 8, matching the app.
   - **Email confirmation:** the brief planned it OFF for staging, because Supabase's built-in mailer allows only a few emails per hour. This project has it **ON** with custom SMTP (Emails → SMTP Settings, Gmail with an app password). If you turn it on, set up SMTP first.
   - URL Configuration → **Site URL**: a page you own. The default `http://localhost:3000` makes confirmation links end on an error page.
5. **Prove isolation** (see below).

### Isolation and rules test
```
npx supabase@2.122.0 db query --linked -f supabase/tests/rls_isolation.sql
```
It creates three throwaway users (A and C in one team, B in another), runs about 100 checks as each user and as a logged-out caller, deletes everything it created, and prints one row per check. The last row is the summary, and every row must say `ok: true`. It covers cross-team reads and writes, owner-only writes, creator-or-owner deletes, anon access, the 3-task limit, input checks, join codes, and leaving a team.

Also run the security advisor after any schema change:
```
npx supabase@2.122.0 db advisors --linked --type all
```
The only expected warnings are for `create_team`, `join_team` and `leave_team` (see `docs/security-audit.md`).

### Error codes the backend returns
The app maps these to friendly messages:

| Code | When |
|---|---|
| `task_limit_reached` | A 4th task for the same person and day |
| `already_in_team` | Creating or joining while already in a team |
| `invalid_code` | Join code is wrong (nothing else is revealed) |
| `invalid_team_name` | Team name empty or over 60 characters |
| `not_in_team` | Leaving when not in a team |
| `not_authenticated` | RPC called without a login |
| `immutable_column` | Trying to change a row's team, creator or creation time |

### Free plan facts
- 500 MB database, 50,000 monthly active users, 2 free projects, **no daily backups**.
- **Free projects pause after 7 days without activity.** Daily use keeps it awake. If it pauses, open the dashboard, select the project and press **Restore project**. It takes a few minutes and the data is kept.

## Agent skills

Installed per `docs/TOOLS.md` into `.agents/skills/` (Codex) with symlinks in `.claude/skills/` (Claude Code). `AGENTS.md` overrides any skill advice.
