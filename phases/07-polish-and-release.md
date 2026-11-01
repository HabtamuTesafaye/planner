# Phase 7: Polish and release

## Objective
Turn a working app into a reliable, polished one that runs well on any Android device, and produce a signed release build.

## Prerequisites
Phase 6 approved.

## Tasks
1. Offline handling: `connectivity_plus` drives a calm `OfflineBanner`. When offline, keep the last loaded data visible, disable save actions with a short reason, preserve text typed in open forms, and retry automatically when back online. Test every screen.
2. Daily reminder: schedule one local notification at the time chosen in settings using inexact scheduling. Ask for the Android 13+ permission with a clear explanation first, and keep the app fully working if denied. Reschedule after reboot.
3. Accessibility pass: TalkBack labels for icon buttons and `CircleCheck`, focus order, minimum 48 dp targets, contrast re-check.
4. Layout pass: 360 x 640 phone, large phone, foldable, tablet (content centered, max width 600 dp), font scale up to 1.5, light and dark, gesture and 3-button navigation, edge-to-edge.
5. Performance pass: run in profile mode on a low-end device or emulator, fix jank, check list performance and startup time.
6. Visual polish: consistent spacing, transitions of 200 to 250 ms, no leftover default Material blue or stray shadows, consistent empty and error copy.
7. App icon (`flutter_launcher_icons`) and splash (`flutter_native_splash`) using the stormy blue accent on the beige-gray background. The icon set is already drawn in `assets/icon/` (regenerate with `python3 assets/icon/src/make_icons.py`); wire it up, including the adaptive foreground, monochrome themed icon, notification icon, and the dark splash variant.
8. Release build: generate a signing keystore with instructions (kept out of git), enable R8, build `flutter build apk --release --split-per-abi`, and document install steps.
9. Final README: setup, env files, Supabase notes, how to restore a paused project, how to build a release, known limitations.
10. Final QA checklist run-through with results written to `docs/qa-checklist.md`.

## Do
- Fix problems you find, do not just list them.
- Keep the app size small: no unused assets or packages.

## Do not
- Do not add new features.
- Do not request exact-alarm permission or any permission the app does not need.
- Do not commit the keystore, passwords or env files.

## Done when
- Release APK installs and works on a small old Android phone and on a large one.
- The app handles airplane mode without crashing on every screen.
- The reminder fires at the chosen time, and the app works if notifications are denied.
- `flutter analyze` is clean, all tests pass, and `docs/qa-checklist.md` is complete.

## Report back, then stop

When the phase is finished, update `PROGRESS.md` and commit your work. Then reply with:
1. What you built, in a few lines.
2. Exactly how I test it on my phone (numbered steps).
3. Anything you were unsure about or chose a default for.
4. The result of `flutter analyze` and `flutter test`.

Then stop and wait for my "go". Do not start the next phase.
