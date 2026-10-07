# Phase 9 Report — Contextual AI Assistant

## Backend

- `app/services/ai.py`: `AiProvider` protocol, `GeminiProvider` (REST,
  constructed only with server-side `GEMINI_API_KEY`), `StubProvider`
  that refuses instead of hallucinating, `FarmContext` + locale-aware
  system prompt with explicit uncertainty instruction.
- `app/routers/ai.py`: authed `POST /api/v1/ai/chat` — verifies owner,
  completes with context, persists user+assistant messages to
  `ai_conversations`/`ai_messages` via service role. 503/404/502 typed.
- `backend/tests/test_ai.py`: 6 tests (prompt, stub honesty, provider
  selection, gating, auth, validation).

## Flutter

- `data/repositories/ai_repository.dart`: `FastApiAiRepository` (Dio
  POST with session bearer token; typed auth/network errors) +
  `AiHistoryReader` for owner-scoped Supabase history reads.
- `core/providers/ai_providers.dart`: lazy client resolution (shell-safe).
- `ai_conversation_screen.dart`: working chat — bubbles, thinking state,
  low-confidence notes, profile/locale context, disabled offline.
- `test/ai_test.dart`: 4 tests (reply mapping, auth passthrough, network
  error, history delegation).

## Verification

- `pytest backend/tests`: 19/19 passed.
- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 28/28 passed.
- `flutter build apk --debug --no-pub`: BUILD SUCCESSFUL in 47.6s.
  APK: `app/build/app/outputs/flutter-apk/app-debug.apk`,
  205,573,833 bytes (196.05 MB, debug, multi-arch).

## Limitations / next

- Live replies need `GEMINI_API_KEY` server-side + pushed schema.
- Phase 10: crop scanner (camera → Storage → analysis → confidence).
