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

## Supabase

Setup steps (migrations, email confirmation, keys, the free-plan 7-day pause and how to restore) are added in Phase 1.

## Agent skills

Installed per `docs/TOOLS.md` into `.agents/skills/` (Codex) with symlinks in `.claude/skills/` (Claude Code). `AGENTS.md` overrides any skill advice.
