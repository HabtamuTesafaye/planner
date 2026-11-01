# Tools, skills, and switching between Claude Code and Codex

## 1. Skills to install

Skills are folders with a `SKILL.md` that the agent loads only when a task matches. Install ONLY the ones below. They come from the official Flutter, Dart and Supabase teams.

| Skill source | What it gives the agent | Install (Claude Code and Codex together) |
|---|---|---|
| `flutter/agent-plugins` (official Flutter skills) | Responsive layouts, routing, widget tests, integration tests, localization, widget previews | `npx skills add flutter/agent-plugins --skill '*' -a claude-code -a codex -y` |
| `dart-lang/skills` (official Dart skills) | Unit tests, dependency problems, static analysis fixes | `npx skills add dart-lang/skills --skill '*' -a claude-code -a codex -y` |
| `supabase/agent-skills`, skill `supabase` | Supabase auth, Realtime, RLS, migrations, security checks | `npx skills add supabase/agent-skills --skill supabase -a claude-code -a codex -y` |
| `supabase/agent-skills`, skill `supabase-postgres-best-practices` | Schema, index, RLS and query best practices | `npx skills add supabase/agent-skills --skill supabase-postgres-best-practices -a claude-code -a codex -y` |

### Mobile design skill (approved by the user)

| Skill source | What it gives the agent | Install |
|---|---|---|
| `vudovn/antigravity-kit`, skill `mobile-design` | Touch and thumb-zone ergonomics, haptics, Material 3 and Android conventions, Flutter performance checklists. 13 markdown guides plus `scripts/mobile_audit.py` (Python standard library only, read-only, no network). | `npx skills add vudovn/antigravity-kit --skill mobile-design -a claude-code -a codex -y` |

AGENTS.md wins over this skill. Ignore its advice on iOS/HIG (Android only), offline-first storage like Room or SQLite (v1 is online-first), and BLoC, GetX or Redux (we use Riverpod). Its audit script is written mostly for React Native: treat "touch target" hits on icon sizes, "no dark mode" and "no testing framework" as false positives for this project.

### Security plugins (Claude Code only, approved by the user)

From the official Trail of Bits repo `trailofbits/skills`. Installed at project scope, so `.claude/settings.json` enables them for anyone who opens the repo in Claude Code.

| Plugin | What it does | What it can run |
|---|---|---|
| `insecure-defaults` | Audits for unsafe defaults: weak crypto, open access, fallback secrets, debug flags. Run `/insecure-defaults:audit`. | A multi-agent Workflow and Bash (heavier on tokens) |
| `sharp-edges` | Flags error-prone APIs and dangerous configurations | Instructions only |
| `differential-review` | Security review of a change set (diff, blast radius, test coverage) | Instructions only (reads git) |

```
claude plugin marketplace add trailofbits/skills
claude plugin install insecure-defaults@trailofbits --scope project
claude plugin install sharp-edges@trailofbits --scope project
claude plugin install differential-review@trailofbits --scope project
```

Also use the built-in `/security-review`, and the Supabase security advisor against `planner-staging` from Phase 1. Write audit findings to `docs/security-audit.md`.

Audit schedule: a light audit after Phase 0, a full audit at the end of Phase 1 (RLS, functions, advisor, isolation test), a differential review at the end of every later phase, and a full audit in Phase 7 before the release build.

Notes:
- The Flutter repo was renamed. Use `flutter/agent-plugins`, not the old `flutter/skills`.
- Claude Code reads project skills from `.claude/skills/`. Codex reads `.agents/skills/`. Installing with both `-a` flags puts them in both places. If a flag is rejected, run `npx skills add --help` and use the closest option.
- Alternative for Claude Code only, which also adds the official Dart and Flutter MCP server (lets the agent run analyzer, tests and inspect the app):
  ```
  claude plugin marketplace add flutter/agent-plugins
  claude plugin install dart-flutter@dart-flutter
  ```
- For Codex, the Flutter docs describe a Dart and Flutter plugin marketplace. See https://docs.flutter.dev/ai/agent-skills for the current command.
- After installing, restart the CLI session so the new skills are discovered. Commit the skill folders to git so both tools and both founders get the same setup.

## 2. Rules for skills (the agent must follow these)

1. The agent MAY run the install commands above itself, but must show me each command first and wait for my yes.
2. Do not install any skill, plugin or MCP server that is not in the table without asking me. If you think another one would help, explain why and name the source.
3. Before installing anything new, open its `SKILL.md` and scripts and tell me in two lines what it does and what it is allowed to run.
4. When a skill's advice conflicts with `AGENTS.md`, `AGENTS.md` wins. Example: skills may suggest `json_serializable`, `freezed`, code generation, or other state management. This project does not use them.
5. Never give any tool or skill the Supabase `service_role` key. If a Supabase MCP server is ever used, it must be limited to the staging project only.

## 3. Useful built-in commands

- Claude Code: `/security-review` before finishing Phase 1 and Phase 7. `/compact` or `/clear` between phases to keep context small.
- Both tools: ask the agent to run `flutter analyze` and `flutter test` itself before reporting.

## 4. Switching between Claude Code and Codex (when one hits its limit)

Both tools read `AGENTS.md`. Claude Code reads it through `CLAUDE.md`. The rest depends on keeping `PROGRESS.md` current and committing often.

Rules for every session, in either tool:
1. Start by reading `AGENTS.md`, then `PROGRESS.md`, then the current phase file.
2. Commit after every meaningful step with a clear message. A cut-off session loses uncommitted work.
3. Update `PROGRESS.md` at the end of each task and always before stopping: current phase, what is done, decisions, open questions, next step.
4. Do not redo finished work. Check the code and `PROGRESS.md` first.

Message to start or continue in Codex (or Claude Code):

> Read AGENTS.md, then PROGRESS.md, then the current phase file it points to. Continue from the next step. Commit as you go and update PROGRESS.md before you stop.

If a quota cut happens in the middle of a task, the new agent should run `git status` and `git log -5`, review any uncommitted changes, finish or discard them, and then continue.

## 5. Where each tool is stronger (practical, not strict)

- Use whichever you have quota for. The briefs are written to work in both.
- Keep one agent per phase when possible. Switching in the middle of a phase works, but PROGRESS.md must be accurate.
