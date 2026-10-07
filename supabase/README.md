# Supabase — Annadata Mitra data foundation (Phase 2)

```text
supabase/
├── config.toml            # local-only project metadata (no secrets)
├── migrations/
│   ├── 0001_schema.sql    # tables, FKs, indexes, updated_at triggers
│   ├── 0002_rls.sql       # RLS enablement + owner/reference policies
│   └── 0003_storage.sql   # private `crop-scans` bucket + prefix policies
├── seed.sql               # deterministic, re-runnable reference data
└── functions/             # reserved for later Edge Functions (empty)
```

## Apply (needs a linked project — not required until rollout)

```bash
supabase link --project-ref <ref>   # needs access token
supabase db push                    # applies migrations in order
supabase db seed                    # or: psql "$DATABASE_URL" -f seed.sql
```

Phase 2 ships reviewed SQL without a live project; nothing here contains
credentials. The Flutter client uses only `SUPABASE_URL` + anon key via
`--dart-define` (see `app/docs/PHASE2_REPORT.md`). The service-role key
must never enter the app — it belongs in `backend/.env` (Phase 3).

## Data summary

- Hierarchy: states → districts → blocks → panchayats → villages →
  farmer_profiles (id = auth.users id) → fields → field_crops.
- Owner-scoped: profiles, fields, plantings, tasks, AI chats, scans.
- Authenticated read-only: locations, crops, crop_advice.
- Backend-written: weather_advisories (service role, Phase 8).
- Seed: starter states, all 38 Bihar districts, sample Haryana districts,
  Nilokheri/Karnal + Nalanda sample chain, 10-crop catalog, 2 advice notes.
  Village coordinates are approximate development samples.
