# Phase 6: Team and weekly review

## Objective
Make the shared space useful: each founder can see the other's progress at a glance, and both write a short weekly review.

## Prerequisites
Phase 5 approved.

## Tasks
1. Team tab, finalized. One card per member showing, derived from existing tables with no new tables:
   - name
   - today's tasks done out of 3
   - tasks completed this week
   - contacts added this week
   - current weekly goal
   - date of last weekly review
   Tap a card to see that person's tasks for today and their latest review (read only).
2. Invite section: code with copy button and a share sheet using `share_plus`.
3. Settings section: daily reminder time (UI only for now, wiring is Phase 7), theme (system, light, dark), leave team, sign out. Leave team asks for confirmation.
4. Weekly review screen: 3 fields (what I did, what is blocked, next week's goal), one per user per week, editable until the week ends. Saves the next goal into the weekly goal for next week.
5. List of past reviews for me and for my teammates, newest first.
6. Gentle prompt on Today on Sunday and Monday if this week's review is missing.
7. Realtime updates for the progress cards.
8. Tests: weekly count logic, review upsert behavior, prompt visibility rules.

## Do
- Make progress feel encouraging, not like surveillance. Use calm wording and no scores or rankings between members.
- Keep cards compact so two members fit comfortably on a small screen.

## Do not
- Do not add chat, comments, reactions, streaks or leaderboards.
- Do not expose anything outside the user's team.

## Done when
- Both founders see each other's progress and reviews on their own phones.
- Leaving a team and rejoining with the code works.
- The Team tab is readable at font scale 1.5 on a small screen.

## Report back, then stop

When the phase is finished, update `PROGRESS.md` and commit your work. Then reply with:
1. What you built, in a few lines.
2. Exactly how I test it on my phone (numbered steps).
3. Anything you were unsure about or chose a default for.
4. The result of `flutter analyze` and `flutter test`.

Then stop and wait for my "go". Do not start the next phase.
