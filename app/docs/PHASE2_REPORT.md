# Phase 2 Report — Supabase (spec revision, live project)

No secret values appear in this report. Credentials live only in the
git-ignored project-root `credentials.txt` and were used from memory.

## Schema (`supabase/migrations/0001_schema.sql`)

Implemented exactly per contract: states, districts, blocks, panchayats,
villages (lat/long), profiles (id = auth.users id; full_name, phone,
preferred_language en/hi, state→village FKs, avatar_url), fields
(profile_id, village_id, name, area_value > 0, area_unit
acre/hectare/bigha/gunta, lat/long, soil_type, notes), crops (name unique,
scientific_name, category, season, description), field_crops
(sowing_date, expected_harvest_date ≥ sowing_date, status, notes), tasks
(profile_id, nullable field/crop, title 1–200, description, due_date,
priority low/medium/high, status pending/in_progress/done/cancelled,
completed_at), weather_advisories (village + nullable profile,
weather_date, temperature/rainfall/humidity/wind, advisory_text,
severity), crop_advice (crop + nullable field/profile, advice_type,
title, content, severity), ai_conversations (profile, title, language),
ai_messages (conversation, role user/assistant/system, content,
metadata JSONB), crop_scans (profile, nullable field, image_path,
detected crop/issue, confidence 0–1, analysis JSONB, status).
UUID PKs, RESTRICT reference FKs, CASCADE owner rows, indexes on all FKs,
`touch_updated_at()` triggers. Structural check: parens balanced,
15/15 tables present in schema + RLS files, seed references valid.

## Connection

Live project verified reachable: Auth health endpoint HTTP 200
(GoTrue v2.x). Migrations are version-controlled and reviewed but not
yet pushed — push needs a DB password or access token (the stored
connection string carries a password placeholder), or paste the three
migration files + seed into the dashboard SQL editor in order.

## RLS (`0002_rls.sql`)

Enabled on 15/15 tables. Owner-only SELECT/INSERT/UPDATE/DELETE via
`auth.uid()` for profiles, fields, field_crops (owns_field), tasks,
ai_conversations, ai_messages (owns_conversation), crop_scans.
Authenticated-read-only for states/districts/blocks/panchayats/villages/
crops/crop_advice (the only `using (true)` policies — reference data,
never private rows). Weather advisories: own-village or assigned-profile
SELECT; writes service-role only.

## Storage (`0003_storage.sql`)

Private `crop-scans` bucket with per-`<uid>/` prefix policies for
insert/select/update/delete. No public objects.

## Auth foundation

Email+password signup/login, email-OTP request/verify, secure session
persistence (supabase_flutter), real sign-out, go_router guard
redirecting protected routes to sign-in when configured. Google OAuth:
routing/guard ready, no credentials invented (dashboard enablement only).

## Flutter integration

supabase_flutter 2.18.0; `SupabaseConfig` via `--dart-define`
(URL + publishable key, `isConfigured` gate, UI-shell fallback);
`Result<T>`/`BackendFailure` (5 kinds); `BackendStateView`
(loading/empty/failure); models for all tables; 5 typed repositories
with exception mapping; Riverpod client/session/repo/profile providers;
OTP+password sign-in UI, live states list, working logout.

## Seed (`supabase/seed.sql`)

Idempotent reference data only: starter states, all 38 Bihar districts,
sample Haryana districts, Nalanda/Karnal sample chains, 10-crop catalog,
2 advice notes. No farmer accounts, no weather/AI rows. Coordinates are
approximate development samples.

## Verification

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 16/16 passed.
- `flutter build apk --debug --no-pub`: BUILD SUCCESSFUL (result + size
  recorded below before commit).
- Security: zero credential material in Dart/SQL (grep clean);
  credentials.txt + .env ignored and untracked; service-role key absent
  everywhere (not provided — Phase 3 only); RLS + storage reviewed.

## APK

- Path: `app/build/app/outputs/flutter-apk/app-debug.apk`
- Size: 205,369,044 bytes (195.86 MB, debug, multi-arch)

## Blockers / next

Push migrations + seed (needs DB password or access token, or dashboard
paste), enable Email provider in Auth settings, run with `--dart-define`
public values. Service-role key still required before Phase 3 backend.
Next: Phase 3 — FastAPI Backend.
