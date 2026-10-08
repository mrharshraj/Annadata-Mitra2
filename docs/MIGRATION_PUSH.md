# Phase 2 Finalization — Live Migration Pushed

No secret values in this file. Connection details stay in the
git-ignored project-root `credentials.txt`.

## Push result

Tool: `backend/scripts/push_migrations.py` (transactional per file,
redacted output, never drops/resets). Direct Postgres connection over
IPv6 with URL-encoded password.

- APPLIED: 0001_schema.sql, 0002_rls.sql, 0003_storage.sql, seed.sql
- CHECK tables_present: 15
- CHECK rls_enabled: 15
- CHECK policies_total: 39
- CHECK bucket_private: False (= private bucket, correct)
- Seed: 8 states, 38 Bihar districts, 10 crops, 4 villages
- VERIFY: PASS

Per-table policy matrix (`backend/scripts/verify_live.py`):
profiles/fields/field_crops/tasks/ai_conversations/crop_scans ×4
(select/insert/update/delete); ai_messages ×3; weather_advisories ×1
(read-only, service role writes); reference tables ×1 read-only;
storage ×4 `<uid>/` prefix policies.

## Post-push verification

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 32/32 passed.
- `flutter build apk --debug --no-pub`: success, 125.4s.
  APK 205,747,926 bytes (~196.22 MB).

## Remaining external items

- Service-role key + JWT secret: still needed for backend runtime
  (Phase 3 deploy). GEMINI_API_KEY already provided by user — required
  only when deploying the backend, not stored in the repo.
