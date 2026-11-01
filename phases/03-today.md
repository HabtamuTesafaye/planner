# Phase 3: Today

## Objective
The Today screen: up to 3 tasks per day and a goal of the week, updating live. This is the core daily habit of the app, so it must feel fast and satisfying.

## Prerequisites
Phase 2 approved.

## Tasks
1. Models and repositories: `Task`, `WeeklyGoal`, `TasksRepository` (stream today's tasks for me, add, toggle done, delete, restore), `GoalsRepository`.
2. Date helpers: today, week start (Monday), end of week, with tests including month and year boundaries.
3. Today screen:
   - Big date in Fraunces.
   - "Goal of the week" line, tap to edit in a bottom sheet.
   - Task list (max 3) with the custom `CircleCheck`. Completing animates the check and strikes through the title.
   - Add task via a bottom sheet or inline field. A 4th task shows the message "Three is the limit. Finish or remove one first."
   - Swipe to delete with an Undo snackbar.
   - Skeleton loading state and a friendly empty state.
4. Realtime: use a Supabase stream filtered by team and user so the list updates without refresh.
5. Map the database error for the 4th task to the same friendly message (the database is the source of truth).
6. Haptic feedback (light) when completing a task.
7. Tests: the 3-task rule in the repository and UI logic, week helper tests.

## Do
- Keep the screen calm: lots of space, one clear action.
- Update the UI optimistically and roll back with a message if the save fails.

## Do not
- Do not show teammates' tasks here (that is Phase 6).
- Do not add task categories, due times, priorities, subtasks or drag-and-drop.
- Do not allow empty titles or titles above 120 characters.

## Done when
- A task added on one phone appears within seconds on a second phone signed in to the same account.
- The 4th task is blocked in the app, and a forced insert from outside the app is blocked by the database.
- Delete with Undo works, and the screen works with font scale 1.5.

## Report back, then stop

When the phase is finished, update `PROGRESS.md` and commit your work. Then reply with:
1. What you built, in a few lines.
2. Exactly how I test it on my phone (numbered steps).
3. Anything you were unsure about or chose a default for.
4. The result of `flutter analyze` and `flutter test`.

Then stop and wait for my "go". Do not start the next phase.
