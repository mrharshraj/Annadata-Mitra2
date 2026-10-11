# Edge Functions — canonical server-side backend

The app no longer requires a separately deployed FastAPI server. All
server-side operations run as Supabase Edge Functions (Deno/TypeScript,
co-located with the database, no Render/hosting account needed):

| Function | Replaces (FastAPI) | Secrets (function env only) |
|---|---|---|
| `ai-chat` | `POST /api/v1/ai/chat` | `GEMINI_API_KEY` |
| `scan-crop` | `POST /api/v1/scanner/analyze` (fallback; primary is direct in-app vision when an Android-restricted key is provisioned — see below) | `GEMINI_API_KEY` |
| `admin-overview` | `GET /api/v1/admin/overview` | `ADMIN_EMAILS` |

Direct scanner vision (no function hop): the app sends captured JPEG
bytes straight to Gemini (`inline_data` base64) when built with
`--dart-define=GEMINI_ANDROID_KEY=...`, then persists the outcome with an
owner-scoped `crop_scans` insert. The key MUST be Android-restricted
(package + SHA-1) in Google AI Studio; without it the app keeps using
`scan-crop`. Verified live against a wheat photo (crop identified,
confidence 0.92).

Common env for all three: `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`SUPABASE_SERVICE_ROLE_KEY`. Set via dashboard or CLI (values never in repo):

```bash
supabase secrets set GEMINI_API_KEY=... ADMIN_EMAILS=...
supabase functions deploy ai-chat scan-crop admin-overview
```

Deploy needs a CLI access token (not currently available — see docs).
`verify_jwt = true` is set in `supabase/config.toml`; each function also
verifies the caller and checks ownership before touching data.

## What runs where (no FastAPI runtime needed)

- Client-safe, direct from app: Supabase Auth, owner-scoped PostgREST
  (RLS), Storage uploads, Open-Meteo HTTPS (keyless), cached weather +
  deterministic advisory rules in Dart.
- Server-side only (Edge Functions above): Gemini chat/vision, chat
  persistence, scan persistence, admin aggregates.
- Nothing requires a privileged key in the APK. The FastAPI tree stays in
  `backend/` as a tested local reference only.
