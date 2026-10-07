# Phase 2 Report — Supabase Backend & Data Foundation

## Status: implementation complete, verification in progress

Baseline: Phase 1 commit `533f21c`. No UI redesign, no routing replacement,
no prototype changes. No live Supabase project exists yet, so this phase
ships reviewed SQL + a credentials-free Flutter integration that runs in
UI-shell mode until configured. No Supabase credentials were requested.

## Schema implemented (`supabase/migrations/0001_schema.sql`)

Hierarchy state → district → block → panchayat → village →
farmer_profiles (PK = auth.users id) → fields → field_crops, plus crops,
crop_advice, todo_tasks, weather_advisories, ai_conversations, ai_messages,
crop_scans. UUID PKs, RESTRICT on reference FKs, CASCADE on owner rows,
`updated_at` triggers, indexes on every FK, CHECKs (language en/hi,
area > 0, harvest ≥ sowing, title length, role enum, confidence 0–1).

## Auth implementation

Email-OTP passwordless via `SupabaseFarmerRepository`
(request → verify), session persistence by supabase_flutter, real sign-out
on Profile, go_router guard redirecting protected routes to `/sign-in`
when configured (open in UI-shell mode). No fake sessions: unconfigured
builds show an explicit not-configured state.

## RLS policies (`0002_rls.sql`)

Enabled on all 15 tables. Owner-only (all commands) for profiles, fields,
plantings (via `owns_field`), tasks, AI chats/messages (via
`owns_conversation`), scans. Authenticated read-only for locations, crops,
crop_advice. Weather advisories: own-village SELECT, writes service-role
only (no write policy). Helpers are `security definer ... stable`.

## Storage setup (`0003_storage.sql`)

Private `crop-scans` bucket (`public=false`); insert/select/update/delete
restricted to the caller's `<uid>/` prefix via `storage.foldername`.
Image bytes never enter Postgres.

## Seed data (`supabase/seed.sql`)

Idempotent (`ON CONFLICT DO NOTHING`, FKs via subselects): starter states,
all 38 Bihar districts, sample Haryana districts, Nalanda + Karnal sample
chains (Nilokheri, Taraori, Rajgir, Sohsarai — approximate coords,
documented samples), 10-crop catalog, 2 advice notes.

## Flutter integration

- `core/config/supabase_config.dart`: `--dart-define` URL/anon key,
  `isConfigured`, descriptive `requireConfigured` (no hardcoding).
- `core/errors/backend_failure.dart`: `BackendFailureKind` ×5 + `Result<T>`.
- `core/widgets/backend_state_view.dart`: loading/empty/failure states.
- `data/models/`: location, farmer_profile, field, crop, task, records.
- `data/repositories/`: typed contracts + 5 Supabase implementations with
  exception mapping (auth/network/permission/unknown).
- `core/providers/supabase_providers.dart`: client, auth refresh tick,
  session, repositories, profile.
- Screens: OTP sign-in, live states list on Location Setup, real logout.
- `main.dart`: initializes Supabase only when configured.

## Security checks

- No secrets/keys/JWTs in `lib` (grep: only doc/UI copy matched).
- `.env` ignored at all levels; `.env.example` placeholders only.
- No service-role key anywhere near Flutter; anon value passed as
  `publishableKey` (Supabase rename, same role — documented).
- RLS on 15/15 tables; storage private with prefix policies.

## Tests

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 15/15 passed (3 smoke + 12 data-layer:
  config validation, guard mapping, 7 model round-trips).

## APK build result

`flutter build apk --debug --no-pub`: BUILD SUCCESSFUL in 357.6s
(no daemon crash on retry path; SDK already provisioned).
- Path: `app/build/app/outputs/flutter-apk/app-debug.apk`
- Size: 205,357,189 bytes (195.84 MB, debug, multi-arch)

## Known limitations

- No live project: migrations/seed reviewed, not yet applied via
  `supabase db push`; E2E auth/RLS verification needs credentials.
- Phone OTP needs provider config on the project (email OTP works as-is).
- Only `brandmark.png` vendored (unchanged from Phase 1).

## Required configuration for the next developer

```bash
# 1. Create/link project, apply backend (needs access token):
supabase link --project-ref <ref> && supabase db push
psql "$DATABASE_URL" -f supabase/seed.sql
# 2. Enable Email OTP provider in Supabase Auth settings.
# 3. Run/build with public values only (anon/publishable key, never service-role):
flutter run --dart-define=SUPABASE_URL=<https-url> \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```
