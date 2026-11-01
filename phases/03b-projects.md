# Phase 3b: Projects

## Objective
Each space keeps its backlog in projects, so Today can stay at three tasks.

## Tasks
1. `Project`, `ProjectItem` models and `ProjectsRepository` (stream projects and steps for a space, create from template, rename, mark done, delete, add/toggle/delete steps with Undo).
2. Built-in templates in code: Blank, Client project, Product launch, Content plan, Event, each with 4 to 7 steps.
3. Projects tab: list with progress bar and status, empty state with one button, new project sheet (name + template cards).
4. Project screen: checklist, add step inline, swipe to delete with Undo, "Plan for today" on a step (uses one of the 3 slots, friendly message when full), mark project done.
5. Realtime for the whole space. Skeleton, empty and error states. Tests: template steps, progress maths, plan-for-today limit mapping.

## Done when
- A project from a template shows its steps, and checking steps moves the progress bar.
- "Plan for today" adds the step to Today; the 4th is blocked with the friendly message.
