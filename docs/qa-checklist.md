# QA checklist (Phase 7)

Run on 2026-11-01. ✅ verified · 👤 needs a person on a real device (could not be automated here) · ⚠️ known limitation.

How things were verified:
- **Unit and widget tests:** 226 passing (`flutter test`). Screens run on a 360×640 dp phone at 1.5× text, in both themes, and on a 1280×800 tablet.
- **Accessibility guidelines:** `test/accessibility_test.dart` checks Android tap targets (48 dp), labelled tap targets and text contrast on Welcome, Sign in, Sign up and all 5 tabs, light and dark.
- **Database:** `supabase/tests/rls_isolation.sql`, 132/132 checks.
- **Live backend:** every app query and write run against `planner-staging` with temporary users (since deleted). All passed.
- **Device:** Redmi 23090RA98I, Android 16. Release build launched (cold start 0.73 s); light and dark screenshots checked. The device blocks automated taps, so flows on the phone are marked 👤.

## Accounts and spaces
| Check | Result |
|---|---|
| Sign up → "Check your email" → link opens the app → signed in | ✅ flow and deep link tested (link opens app); 👤 full email round trip |
| Wrong password shows a friendly message | ✅ widget test + live API (`invalid_credentials`) |
| Stay signed in after closing the app | ✅ Supabase session persistence; 👤 on phone |
| New account lands in Personal (no forced team) | ✅ |
| Create team space, join with code (any case, spaces), wrong code message | ✅ widget + live |
| Switch spaces from the top of a tab; choice remembered | ✅ widget + live (`last_team_id`) |
| Leave space (owner hand-over; last member deletes it); personal can't be left | ✅ SQL tests + live |

## Today
| Check | Result |
|---|---|
| Up to 3 tasks across all spaces; 4th blocked in app and database | ✅ widget + controller + live |
| Complete (animation, strike-through, haptic), swipe delete + Undo | ✅ tests; 👤 feel on phone |
| Goal of the week edit/clear | ✅ live upsert |
| Sunday/Monday review prompt only when missing | ✅ logic tests |
| Date rolls over after midnight on resume | ✅ re-read on resume (code), 👤 overnight |

## Projects
| Check | Result |
|---|---|
| New project from template shows its steps; progress bar moves | ✅ |
| Plan a step for today (respects the 3 limit); completing the task completes the step | ✅ SQL + live |
| Teammate can check steps; only creator/owner can delete | ✅ SQL + live |

## Outreach
| Check | Result |
|---|---|
| Overdue first, then soonest, then no date; "3 days overdue" in attention color | ✅ |
| Filters: status, Mine/Everyone | ✅ |
| Add in seconds (only name required), edit, quick status, Followed up | ✅ tests + live |
| 100+ contacts stay smooth | ✅ lazy list (`SliverList.builder`); 👤 on a low-end phone |

## Money
| Check | Result |
|---|---|
| `12,500 ETB` formatting, decimals only when needed | ✅ |
| Totals exact; 31st→1st and Dec→Jan boundaries | ✅ |
| Target + progress, delete with Undo, previous months | ✅ |

## Space and review
| Check | Result |
|---|---|
| Member cards: today, week, contacts, goal, last review | ✅ |
| Invite copy and share sheet | ✅ code; 👤 share sheet on phone |
| Theme System/Light/Dark saved and applied | ✅ live profile update |
| Weekly review saves; next goal becomes next week's goal | ✅ live |

## Offline, reminders, platform
| Check | Result |
|---|---|
| Offline banner; save buttons pause with reason; typed text kept; refresh on reconnect | ✅ widget tests; 👤 airplane mode on phone |
| Daily reminder at chosen time (inexact), permission asked politely, works if denied | ✅ scheduling logic + Addis Ababa time zone; 👤 notification arrives |
| Reminder survives reboot | ✅ boot receiver configured; 👤 reboot test |
| Edge-to-edge, light/dark system bars | ✅ screenshots |
| Predictive back gesture | ✅ enabled; 👤 swipe on Android 14+ |
| 360×640 at 1.5× text, tablet centered at 600 dp | ✅ tests |
| TalkBack labels, focus order | ✅ guideline tests; 👤 full TalkBack walk-through |
| Release APK signed with release key, R8 on, ~22 MB arm64 | ✅ `apksigner` verified |
| Small old phone (Android 7, 2 GB) | 👤 not available here |

## Known limitations
- ⚠️ Online-first: no offline editing (by design, AGENTS.md 5.5).
- ⚠️ Reminder is inexact by design (no exact-alarm permission).
- ⚠️ Free Supabase projects pause after 7 days without use.
