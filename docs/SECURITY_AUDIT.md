# Phase 12 Report — Security Audit

Date: 2026-10-07. Scope: entire repo at commit `791105f` + Phase 12 changes
(none required — audit only). No secret values in this file.

## 1. Secrets handling — PASS

- Repo-wide scan for JWTs, `sb_secret_`/`sbp_` tokens, Google/Gemini keys,
  OpenAI keys, private keys, project refs: matches ONLY in the git-ignored,
  untracked `credentials.txt` (the sanctioned local store).
- Zero tracked files match `credentials|*.env|*.pem|*.key`.
- `.gitignore` covers `credentials.txt`, `.env`, `.env.local`, `*.key`,
  `*.pem`, `.venv/`, build outputs.
- Flutter `lib/`: no URLs, keys, or tokens of any kind.
- Backend: all secrets via env (`SUPABASE_*`, `GEMINI_API_KEY`,
  `ADMIN_EMAILS`); `require_backend()` fails closed with names only.

## 2. Database / RLS — PASS (reviewed, live push pending)

- RLS enabled on 15/15 tables (migration 0002).
- Owner-only SELECT/INSERT/UPDATE/DELETE via `auth.uid()` on profiles,
  fields, field_crops, tasks, ai_conversations, ai_messages, crop_scans.
- `using (true)` appears ONLY on 7 authenticated-read reference policies
  (states→villages, crops, crop_advice) — no private data.
- Weather advisories: own-village/assigned-profile read; writes service
  role only.

## 3. Storage — PASS

- `crop-scans` bucket `public=false`; 4 prefix-scoped policies
  (`<uid>/`), no public access.

## 4. API authorization — PASS

- 5/5 sensitive endpoints gated on verified Supabase JWT
  (weather×2, ai/chat, scanner/analyze, admin/overview).
- `/health` open by design (no data). Admin additionally email-allowlisted.
- Errors sanitized (`{"detail","code"}`, no tracebacks); CORS from env.

## 5. Flutter client — PASS

- Only anon/publishable key via `--dart-define`; service-role absent.
- Android permissions minimal (INTERNET, CAMERA, LOCATION).
- Session via supabase_flutter secure storage; no passwords stored.

## Residual risks (accepted, documented)

- Live RLS/policy effectiveness awaits dashboard migration + E2E check.
- Release APK currently signs with debug keys (Phase 14 notes store
  signing setup). No PII beyond farmer-provided profile data.
