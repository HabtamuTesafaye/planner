# Planner build brief

A step-by-step brief for building the team planner app (Flutter + Supabase) with an AI coding agent.

## What is in this folder

| File | Purpose |
|---|---|
| `CLAUDE.md` | Tells Claude Code to load `AGENTS.md` (Codex reads `AGENTS.md` directly). |
| `PROGRESS.md` | Live status so Claude Code and Codex can hand over to each other without losing track. |
| `docs/TOOLS.md` | Which skills to install and the exact commands, rules for skills, and how to switch between Claude Code and Codex. |
| `AGENTS.md` | The permanent reference: product scope, stack and libraries, compatibility, Supabase schema and security, design system, rules. |
| `phases/00-foundation.md` | Project, theme, shared widgets, navigation shell |
| `phases/01-backend.md` | Supabase tables, security (RLS), functions, tests |
| `phases/02-auth-and-team.md` | Sign up, sign in, create and join a team |
| `phases/03-today.md` | Daily tasks (max 3) and weekly goal |
| `phases/04-outreach.md` | Shared contact pipeline and follow-ups |
| `phases/05-money.md` | Monthly income against a target |
| `phases/06-team-and-review.md` | Team progress and weekly review |
| `phases/07-polish-and-release.md` | Offline handling, reminders, accessibility, release APK |

Each phase file has: objective, tasks, do and do-not lists, a done-when test, and what the agent must report back.

## How to use it

1. Create a new Flutter project folder and put `AGENTS.md` and the `phases/` folder in the root.
2. Download the fonts Fraunces and Manrope from Google Fonts and put the files in `assets/fonts/`.
3. Create a free Supabase project named `planner-staging` (needed from Phase 1).
4. Run `git init` and commit these files so the first commit is the brief itself.
5. Give your coding agent this message to start (it will ask your permission before installing the skills in `docs/TOOLS.md`):

   > Read AGENTS.md fully. Then do `phases/00-foundation.md` only. Follow it exactly and stop when it asks you to report back.

6. Test the result on your phone. If it is good, send the next message:

   > Phase 0 is approved. Now do `phases/01-backend.md` only. Stop when it asks you to report back.

   Repeat with the next file each time. If something is wrong, tell the agent exactly what to fix before moving on.

## Tips

- One phase at a time. Do not let the agent skip ahead.
- Commit to git after every approved phase.
- Phases 0 to 3 already give you a usable app. Phases 4 to 7 can follow when you have time.
- Never paste your Supabase `service_role` key anywhere. The app only uses the URL and the anon key.

## If you hit your Claude Code limit

Open the project in Codex and send:

> Read AGENTS.md, then PROGRESS.md, then the current phase file it points to. Continue from the next step. Commit as you go and update PROGRESS.md before you stop.

Details are in `docs/TOOLS.md`. This only works if the agent keeps committing and keeps `PROGRESS.md` current, which the brief tells it to do.
