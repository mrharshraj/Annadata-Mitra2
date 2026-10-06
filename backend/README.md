# Backend (Phase 3)

FastAPI skeleton lands here in Phase 3:

```text
backend/
├── app/{main,config,database,models,schemas,routers,services,middleware,utils}.py
├── tests/
└── requirements.txt
```

Phase 1 only provides `.env.example` so secret handling is agreed upfront.
No server secrets are referenced from `app/` (Flutter).
