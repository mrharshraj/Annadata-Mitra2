# Backend — FastAPI (Phase 3 foundation)

```text
backend/
├── app/
│   ├── main.py          # create_app(), /health + /api/v1 mount
│   ├── config.py        # env-only settings (no committed secrets)
│   ├── database.py      # service-role client, server-side only
│   ├── deps.py          # Supabase JWT verification (401/503, no leaks)
│   ├── errors.py        # sanitized {"detail","code"} envelope
│   ├── logging_conf.py  # stdout logging + x-request-id middleware
│   ├── models/          # Phase 4+ ORM/pydantic models
│   ├── schemas/health.py
│   ├── routers/{health,v1}.py   # feature routers mount in later phases
│   ├── services/ middleware/ utils/
├── tests/test_foundation.py
└── requirements.txt
```

## Run (no live credentials needed for health/tests)

```bash
python -m venv backend/.venv
backend/.venv/Scripts/python -m pip install -r backend/requirements.txt
backend/.venv/Scripts/python -m pytest backend/tests -q
backend/.venv/Scripts/python -m uvicorn app.main:app --app-dir backend --host 0.0.0.0 --port 8000
```

Live Supabase wiring (later): copy `.env.example` to `.env` (never commit)
and set `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`.

Contract: `GET /health` → `{"status": "ok"}` (also `/api/v1/health`).
