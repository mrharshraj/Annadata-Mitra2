# Test Report — Annadata Mitra audit pass (2026-10-11)

Commands executed (from repo root unless noted):

- `flutter analyze --no-pub` (app/): No issues found.
- `flutter test --no-pub` (app/): 34/34 passed — smoke (3), data layer
  (11), location cascade (4), weather cache (4), AI repo (4), scanner (4),
  privacy routes (2).
- `backend/.venv/Scripts/python -m pytest backend/tests -q`: 31/31 passed
  — foundation (6), weather (7), AI (6), scanner (7), admin (3),
  rate-limit (2).
- `flutter build apk --debug --no-pub`: success.
- `flutter build apk --release --no-pub`: success, upload-key signed
  (apksigner DN verified) — `app/build/app/outputs/flutter-apk/app-release.apk`,
  56,811,589 bytes (54.18 MB).
- AAB via `gradlew bundleRelease` (same signing config; flutter wrapper's
  NDK strip post-step fails on this Windows toolchain, `debugSymbolLevel`
  NONE set): `app/build/app/outputs/bundle/release/app-release.aab`,
  26,805,193 bytes (25.56 MB), upload-key signed (keytool DN verified).
- Live probes: Supabase GoTrue 200; anon reads `[]`/writes 401;
  Open-Meteo 200; Gemini key valid (live 200 after model fix);
  local uvicorn `/health` + `/api/v1/health` 200.

## Status key

- Passed: everything above.
- Blocked: on-device install/E2E (no adb/emulator here); backend HTTPS
  deploy (no hosting account); live OTP round-trip (needs device + inbox).
- Failed: none. Not run: Play Console flows (manual). N/A: iOS.
