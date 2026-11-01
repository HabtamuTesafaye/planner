# Phase 0: Foundation

## Objective
Have a running, empty app that already looks right in light and dark mode, with the project skeleton, theme system and shared widgets that every later phase builds on. No backend yet.

## Before you start
Read `AGENTS.md`, `PROGRESS.md` and `docs/TOOLS.md`. Then send me ONE message with the questions from AGENTS.md section 2 (confirm or correct the 5 assumptions, max 5 questions). If I do not answer, continue with the defaults.

## Tasks
0. Skills: read `docs/TOOLS.md`. Show me the install commands for the listed skills and run them after I say yes. Restart or reload so the skills are active.
1. Create the project for Android only: `flutter create --platforms=android`. Placeholder package id `com.example.planner`.
2. Add the packages from AGENTS.md section 3 and pin the resolved versions. Set strict lints in `analysis_options.yaml`.
3. Create the folder structure from AGENTS.md section 8.
4. Config: `env/example.json` with `SUPABASE_URL` and `SUPABASE_ANON_KEY`, `.gitignore` entries for secrets, and an `AppConfig` class that reads values with `String.fromEnvironment`. If values are missing, show a clear "setup needed" screen instead of crashing.
5. Theme system in `lib/core/theme/`: `AppColors`, `AppSpacing`, `AppRadius`, `AppTextStyles`, light and dark `ThemeData`. Style these components in the theme: `NavigationBar`, `FilledButton`, `OutlinedButton`, `TextButton`, `InputDecorationTheme`, `FilterChip`, `SnackBar`, bottom sheet, date picker, divider.
6. Fonts: declare Fraunces and Manrope in `pubspec.yaml`. If the files are missing, fall back to system fonts without errors.
7. Shared widgets in `lib/core/widgets/`: `CircleCheck` (animated, accessible), `Skeleton`, `EmptyState`, `SectionHeader`, `OfflineBanner` (visual only for now).
8. Router: `go_router` shell with 4 bottom tabs (Today, Outreach, Money, Team). Each tab shows its title and an `EmptyState`. Theme mode follows the system.
9. Android setup: `minSdk` 24, edge-to-edge with correct system bar colors, app label, release signing documented (not committed).
10. Tests: a theme smoke test, and a contrast test that checks every text/background token pair meets 4.5:1 in both themes.
11. Start `README.md`: what the app is, how to run it, how to pass the env file.

## Do
- Make the theme the single source of truth for colors, spacing and type.
- Use `const` constructors and small widgets.

## Do not
- Do not add Supabase code, auth or any feature logic.
- Do not use `google_fonts`, `fromSeed`, or hardcoded colors in screens.
- Do not add packages that are not in AGENTS.md.

## Done when
- The app runs on a real phone and shows 4 tabs that look right in light and dark mode.
- No overflow at font scale 1.5 on a 360 x 640 screen.
- `flutter analyze` is clean and all tests pass, including the contrast test.

## Report back, then stop

When the phase is finished, update `PROGRESS.md` and commit your work. Then reply with:
1. What you built, in a few lines.
2. Exactly how I test it on my phone (numbered steps).
3. Anything you were unsure about or chose a default for.
4. The result of `flutter analyze` and `flutter test`.

Then stop and wait for my "go". Do not start the next phase.
