# Edge Functions — canonical server-side backend

The app no longer requires a separately deployed FastAPI server. All
server-side operations run as Supabase Edge Functions (Deno/TypeScript,
co-located with the database, no Render/hosting account needed):

| Function | Replaces (FastAPI) | Secrets (function env only) |
|---|---|---|
| `ai-chat` | `POST /api/v1/ai/chat` | `GEMINI_API_KEY` |
| `scan-crop` | `POST /api/v1/scanner/analyze` | `GEMINI_API_KEY` |
| `admin-overview` | `GET /api/v1/admin/overview` | `ADMIN_EMAILS` |

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
