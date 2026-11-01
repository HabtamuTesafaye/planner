# Phase 5: Money

## Objective
Show the team's income this month against a target, so progress toward leaving the day jobs is visible every day.

## Prerequisites
Phase 4 approved.

## Tasks
1. Models and repository: `IncomeEntry`, `MonthlyTarget`, `MoneyRepository` (stream entries for a month, add, delete, get and set target, list previous months with totals).
2. Money screen:
   - Large this-month total in Fraunces, shown as `12,500 ETB`, with the target and a thin progress bar.
   - List of this month's entries (amount, note, who added it, date).
   - "Add income" bottom sheet (amount above zero, short note).
   - "Set target" for the month.
   - Previous months list with totals.
3. Currency and number formatting helper with tests (thousands separator, no decimals unless needed).
4. Month boundary logic: entries belong to the first day of their month. Test the 31st to 1st rollover and December to January.
5. Realtime updates, skeleton, empty state, error state.
6. Delete an entry with Undo (creator or team owner only).

## Do
- Treat amounts as `numeric` and avoid floating point errors in sums.
- Keep the screen quiet and clear: the big number is the hero.

## Do not
- Do not add charts, expenses, invoices, multiple currencies or export.
- Do not show negative or zero amounts.

## Done when
- Adding an entry on one phone updates the total on the other phone.
- Totals are correct across month boundaries.
- Progress bar and large number look right at font scale 1.5.

## Report back, then stop

When the phase is finished, update `PROGRESS.md` and commit your work. Then reply with:
1. What you built, in a few lines.
2. Exactly how I test it on my phone (numbered steps).
3. Anything you were unsure about or chose a default for.
4. The result of `flutter analyze` and `flutter test`.

Then stop and wait for my "go". Do not start the next phase.
