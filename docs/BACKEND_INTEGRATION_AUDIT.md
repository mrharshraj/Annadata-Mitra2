# Backend Integration Audit — Annadata Mitra

Date: 2026-10-11. Method: code inspection + live probes (no secrets printed).

## Dependency map

- Onboarding/auth screens → Supabase Auth (OTP/password) + `profiles`.
- Location cascade → PostgREST reference tables (seeded).
- Fields/crops/tasks → owner-scoped PostgREST (RLS).
- Dashboard/weather → FastAPI `/api/v1/weather/*` → Open-Meteo (keyless),
  SharedPreferences 6h cache fallback.
- AI chat → FastAPI `/api/v1/ai/chat` (Bearer JWT) → Gemini → persists to
  `ai_conversations`/`ai_messages`.
- Scanner → Storage `crop-scans/<uid>/` → FastAPI `/api/v1/scanner/analyze`
  → Gemini vision → `crop_scans` row.
- Admin → FastAPI `/api/v1/admin/overview` (session + allowlist).

## Verified live (this audit)

- Supabase REST reachable; anon reads return `[]`, anon writes 401.
- GoTrue health 200. 15/15 tables, RLS 15/15, 39 policies, private bucket.
- Open-Meteo 200 with real temperature. Gemini key valid, model
  `gemini-3.8-flash` per vendor message (code updated).
- FastAPI boots locally; `/health` + `/api/v1/health` 200.

## Not yet live

- Backend has no public HTTPS deployment (Render blueprint + manual steps
  in repo; needs a Render account). APK `API_BASE_URL` therefore unset —
  backend paths degrade gracefully (cache/static/honest 503s).
- No device/emulator here: on-device E2E (OTP email, camera, install)
  must be run by the farmer-tester with the release APK.

## Fixed in this audit

- Retired Gemini model IDs replaced (`2.0-flash` → `2.5-flash` →
  vendor-mandated `3.8-flash`).
- Rate limiting added on `/ai/*` (20/min) and `/scanner/*` (10/min).
- Task-details editor + first-crop onboarding writes implemented
  (stale Phase 6/7 TODOs closed).
- Release signing via local upload keystore (was: debug keys).
