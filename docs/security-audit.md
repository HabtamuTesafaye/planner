# Security audit log

Newest first. Each finding has a severity, status and fix. Severity: Critical, High, Medium, Low, Info.

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
