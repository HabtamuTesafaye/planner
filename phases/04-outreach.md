# Phase 4: Outreach

## Objective
A shared pipeline where both founders log every business they contact, see what needs a follow-up today, and never lose a lead.

## Prerequisites
Phase 3 approved.

## Tasks
1. Models and repository: `Contact`, `ContactsRepository` (stream for the team, add, update, delete, change status, set follow-up).
2. Outreach screen:
   - Filter by status and by "Mine / Everyone".
   - Sorted with overdue follow-ups first, shown in the accent color with plain text such as "3 days overdue".
   - Each row: name, business, status chip, next follow-up, who owns it.
3. Add and edit in a bottom sheet: name (required), business, channel, status, next follow-up date, price (optional), notes.
4. Quick actions from the list: change status, and "Followed up" which asks for the next follow-up date.
5. Swipe to delete (creator or team owner only) with a confirmation.
6. Realtime updates for the whole team.
7. Skeleton, empty state ("No contacts yet. Add the first business you message."), and error state.
8. Tests: sort order (overdue first, then soonest, then no date), overdue text, filter logic.

## Do
- Make adding a contact take under 15 seconds.
- Keep the list readable at 100+ contacts using `ListView.builder`.

## Do not
- Do not build email sending, reminders per contact, import/export, tags or a kanban view.
- Do not let a user edit fields while offline without showing why saving is disabled.

## Done when
- I can log 10 contacts and the other founder sees them within seconds.
- Overdue follow-ups appear first and are clearly marked.
- Filters and quick actions work on a small screen.

## Report back, then stop

When the phase is finished, update `PROGRESS.md` and commit your work. Then reply with:
1. What you built, in a few lines.
2. Exactly how I test it on my phone (numbered steps).
3. Anything you were unsure about or chose a default for.
4. The result of `flutter analyze` and `flutter test`.

Then stop and wait for my "go". Do not start the next phase.
