# Security audit log

Newest first. Each finding has a severity, status and fix. Severity: Critical, High, Medium, Low, Info.

---

## Change review: Google sign-in (2026-11-01)

| # | Area | Severity | Status | Notes |
|---|---|---|---|---|
| G1 | OAuth flow | Info | OK | Supabase OAuth with **PKCE** (supabase_flutter default). The browser returns to `com.elvaris.planner://login-callback`; a stolen redirect without the app's code verifier cannot be exchanged for a session. |
| G2 | Secrets | Info | OK | The Google client secret lives only in the Supabase dashboard. The app only uses the public anon key. Nothing new in the repo. |
| G3 | Provider check | Info | OK | Before opening the browser the app reads the public `/auth/v1/settings` (anon key, no secrets) to see if Google is on; if not, a calm message. Failure counts as "off". |
| G4 | Account linking | Low | Accepted | Supabase links a Google login to an existing account with the same **verified** email. Acceptable: Google emails are verified. Keep "Confirm email" on for password sign-ups (issue #3) so an unverified password account can't pre-claim someone's Gmail. |
| G5 | Profile name | Info | OK | Migration 015: the sign-up trigger takes `full_name`/`name` from Google metadata, trimmed and capped at 60 characters (same check constraint as before). Covered by a check in `supabase/tests/rls_isolation.sql` (141/141). |
| G6 | Android | Info | OK | Manifest `<queries>` for https VIEW intents (Android 11+ package visibility) so the browser can open; no new permissions. |

---

## Phase 7 audit: spaces, projects and release (2026-11-01)

Scope: migrations 011–014 (spaces, projects, plan-for-today, settings), app code from phases 3–7, release build configuration.

Method: `supabase/tests/rls_isolation.sql` (**139/139**, now including spaces, personal spaces, projects, plan-for-today and profile privacy); live end-to-end of every app query with temporary users; `supabase db advisors`; manual review; `apksigner` on the release APK.

| # | Finding | Severity | Status |
|---|---|---|---|
| 1 | Teammates could read each other's whole profile row, which since 011 includes reminder time (a daily routine), theme and last selected space. | Medium (privacy) | **Fixed** in 014: column-level SELECT (id, name, created) for others; own settings only through `get_my_profile()`. Tested in SQL and live (teammate gets 403). |
| 2 | Deleting an account failed: removing its personal space tried to update the profile being deleted. | Medium (availability) | **Fixed** in 013 (`last_team_id` validated by trigger instead of a foreign key). Found by the isolation test before release. |
| 3 | A task could link a project step from another space. | Low | **Prevented** by trigger `check_task_item` (tested). |
| 4 | Release builds fell back to the debug key (Phase 0, #4). | Low | **Fixed**: release builds fail without `android/key.properties`; the keystore lives outside the repo; R8 shrinking and obfuscation on; APK verified as signed by `CN=Planner, O=Elvaris`. |
| 5 | Advisor: `get_my_profile()` is SECURITY DEFINER and callable by `authenticated`. | Warn | **Accepted, by design**: returns only the caller's row (`auth.uid()`), fixed `search_path`, revoked from anon. Same reasoning as the team RPCs. |
| 6 | Advisor: leaked password protection (HaveIBeenPwned) is off. | Low | **User action** if your plan allows: Authentication → Policies. |
| 7 | Join codes are shared as plain text through the share sheet. | Info | Accepted: that is their purpose. A code only lets someone join; members can leave, and the owner keeps control. |

Verified:
- Spaces: personal space per user (created on sign-up and backfilled), cannot be joined or left, at most 20 spaces, deleted with its user.
- Projects and steps: shared inside the space, invisible outside; steps always take the project's space; only creator or owner deletes.
- The 3-task limit counts across all spaces, also for planned project steps.
- No secrets in git (keystore, key password, env files and DB password are git-ignored or outside the repo).

---

## Change review: email links open the app (2026-11-01)

| # | Finding | Severity | Status |
|---|---|---|---|
| 1 | The custom scheme `com.elvaris.planner://login-callback` could also be registered by another app, which might receive a confirmation link. | Low | **Mitigated**: supabase_flutter uses PKCE, so the code in the link is useless without the verifier stored only on the device that signed up. Only the exact path is accepted, and Supabase only redirects to URLs on the allow list. |
| 2 | Flutter's own deep-link routing would push the callback URL into go_router (an unknown route). | Info | **Fixed**: `flutter_deeplinking_enabled=false`; supabase_flutter handles the link. |
| 3 | A failed or expired link arrives as an error on the auth stream. | Info | **Handled**: logged and ignored, and the sign-in state keeps working. The user can still sign in by hand. |

---

## Phase 1 audit: backend (2026-11-01)

Scope: all migrations (`001`–`010`), RLS policies, `security definer` functions, grants, Realtime publication, the public API surface with the anon key, and the Supabase advisors.

Method:
- Manual review against the Supabase security checklist (skills `supabase` and `supabase-postgres-best-practices`).
- `supabase/tests/rls_isolation.sql`: **98 checks, 98 passed**, as three users and anon.
- Live probes of the REST and GraphQL API with only the anon key.
- `supabase db advisors --type all`.

| # | Finding | Severity | Status |
|---|---|---|---|
| 1 | New tables and functions in `public` are granted to `anon` and `authenticated` by default on this project. | High (by default) | **Fixed**: every migration revokes all and grants back only what is needed. 007 also changes the default privileges so future objects are not granted to anon. |
| 2 | Users could update any column of their own rows, including `id`, `created_at` and `done_at`. | Low | **Fixed** in 010: column-level UPDATE grants on tasks, contacts and income. Tested. |
| 3 | Advisor: `create_team`, `join_team`, `leave_team` are SECURITY DEFINER and callable by `authenticated`. | Warn | **Accepted, by design.** Memberships have no write policies, so these RPCs are the only way to change them. Each acts only on `auth.uid()`, validates input, uses `search_path = ''`, and is revoked from anon and PUBLIC. |
| 4 | Join codes could be brute-forced. 31^8 ≈ 8.5 × 10^11 codes, and a wrong code reveals nothing. | Low | Accepted for v1. If needed later, add a per-user attempt limit in `join_team`. |
| 5 | Join code characters have a tiny modulo bias (256 mod 31). | Info | Accepted. It does not meaningfully reduce the search space. |
| 6 | The server minimum password length is the Supabase default (6). The app requires 8. | Low | **User action**: dashboard → Authentication → Providers → Email → Minimum password length = 8. |
| 7 | The Gmail SMTP app password from the Phase 0 audit (#3) still needs rotating. | High | **User action** (carried over) |

Verified:
- RLS is enabled on all 9 tables, from the migration that creates each one. No table ever existed without it.
- With only the anon key, every table returns `42501 permission denied`, RPCs are denied, the `private` schema is not exposed (`PGRST106`), and GraphQL is disabled (`pg_graphql` not installed).
- Cross-team: no reads and no writes on any table, including profiles, teams and memberships.
- Same team: teammates read everything; own-row tables are writable only by their owner; shared rows are editable by members, but creator, team and created time cannot change; deletes only by the creator or the team owner.
- The 3-task limit holds for single inserts, bulk inserts and moving a task's day, with an advisory lock against races. `done_at` is set only by the database.
- Leaving: the owner hands over to the oldest member, and the last member leaving deletes the team and all its data.
- Helpers live in the unexposed `private` schema with a fixed `search_path`, and every policy uses `(select auth.uid())` (no per-row re-evaluation; the performance advisor is clean).
- Realtime (tasks, contacts, income) applies the same SELECT policies.

---

## Phase 0 audit (2026-11-01)

Scope: repo and git history, secrets handling, env config, Android manifest and Gradle config, Supabase project setup. There is no backend code or data access yet, so RLS is audited in Phase 1.

Method: manual review plus checks for tracked secret files, secret patterns in the full git history, merged manifest permissions, and `print` calls.

| # | Finding | Severity | Status |
|---|---|---|---|
| 1 | Release builds had no `INTERNET` permission (Flutter adds it only to debug and profile), so the release app could not reach Supabase. | High (availability) | **Fixed**: declared in `src/main/AndroidManifest.xml` |
| 2 | `allowBackup` defaulted to true. From Phase 2 the Supabase session (refresh token) would be copied to cloud backups and device transfers. | Medium | **Fixed**: `allowBackup="false"`, `fullBackupContent="false"`, `data_extraction_rules.xml` excludes all domains (Android 12+) |
| 3 | A Gmail SMTP app password was pasted into the AI chat. It is not in the repo or the app, but the chat log holds it. | High | **User action**: revoke it in Google Account → App passwords and use a new one only in Supabase → SMTP settings |
| 4 | Release builds fall back to the debug signing key when `android/key.properties` is missing, so a debug-signed release could ship by mistake. | Low | Open, Phase 7: fail the release build when the key is missing |
| 5 | The database password is stored in plain text at `env/staging.db-password` (git-ignored, mode 600). | Low | Accepted for staging. Keep a copy in a password manager. |
| 6 | Email confirmation is ON but the Site URL is the default `http://localhost:3000`, so confirmation links end on an error page. Not a vulnerability; avoid open redirect allow-lists when fixing it. | Info | Open, Phase 2 |

Checks that passed:
- Only `env/example.json` is tracked. `env/*.json`, `env/*.db-password`, `*.jks`, `*.keystore` and `key.properties` are git-ignored.
- No JWTs, `sb_secret` keys, service_role keys or passwords anywhere in git history.
- The app contains only the Supabase URL and the anon key. The service_role key was never written to disk.
- Merged manifest permissions: INTERNET, ACCESS_NETWORK_STATE, POST_NOTIFICATIONS, VIBRATE. No exact alarms, storage, location or contacts.
- Only the launcher activity is exported. Cleartext HTTP is blocked by default (targetSdk ≥ 28).
- No `print` calls in `lib/`.
- The Supabase anon key is limited to the auth health endpoint until RLS policies exist (no tables yet).

Next audit: end of Phase 1, a full RLS and functions review, the Supabase security advisor, and the two-user isolation test.
