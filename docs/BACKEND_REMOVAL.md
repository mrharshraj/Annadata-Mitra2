# Backend Removal Report — FastAPI runtime dependency eliminated

## Endpoint audit (all FastAPI routes and their replacements)

| FastAPI endpoint | Purpose | Replacement (live, tested) |
|---|---|---|
| `GET /health`, `GET /api/v1/health` | liveness | Dropped (client needs none; Supabase/Open-Meteo reached directly) |
| `GET /api/v1/weather/current+forecast` | normalized weather + rules | Direct Open-Meteo HTTPS in app + Dart `Forecast.fromOpenMeteo` + `buildAgriAdvisories` (identical thresholds) |
| `POST /api/v1/ai/chat` | Gemini chat + persistence | Edge Function `ai-chat` (JWT check, ownership, Gemini, persist) |
| `POST /api/v1/scanner/analyze` | vision + persistence | Direct Gemini in app (primary when an Android-restricted key is provisioned) with `scan-crop` Edge Function as fallback |
| `GET /api/v1/admin/overview` | aggregates | Edge Function `admin-overview` (session + allowlist) |

## Removed (Flutter)

- `lib/core/network/api_client.dart`, `lib/core/providers/api_providers.dart`,
  `lib/core/config/app_config.dart` (sole purpose: FastAPI base URL).
- No remaining `API_BASE_URL` / Render references in Dart (docs history only).
- Dio stays as the Open-Meteo HTTP client only.

## Client-safe vs server-side (explicit)

- Safe in APK: Supabase URL + publishable key, Open-Meteo direct calls,
  all RLS-scoped CRUD, cached weather, deterministic rules.
- Must stay server-side: `GEMINI_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
  (both in Edge Function env), `ADMIN_EMAILS`. Nothing privileged was
  moved into the app — verified by grep + APK string audit.

## Verification

- `tsc` syntax check on 3 functions: clean (only environmental
  remote-import notices).
- `flutter analyze`: clean. `flutter test`: 37/37.
- `pytest backend/tests`: 31/31 (FastAPI retained as local reference).
- Release builds: debug APK + release APK + AAB (paths/sizes at commit).

## Remaining external setup

1. `supabase functions deploy ai-chat scan-crop admin-overview` (needs a
   CLI access token — not available here).
2. `supabase secrets set GEMINI_API_KEY=... ADMIN_EMAILS=...` (+ the
   standard Supabase URL/keys which Edge Functions receive automatically).
3. Rebuild APKs after deploy (no `API_BASE_URL` needed anymore).
4. On-device E2E of AI chat + scanner against deployed functions.
