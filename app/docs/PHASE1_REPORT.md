# Phase 1 Completion Report — Flutter Foundation

## Implementation completed

- Flutter app scaffolded at `app/` (project `annadata_mitra`,
  `in.annadatamitra.annadata_mitra`), Flutter 3.47.5 / Dart 3.13.4.
- State: Riverpod 3.4.3 (`ProviderScope`, `NotifierProvider` locale).
- Routing: go_router 18.0.2 with `StatefulShellRoute` bottom nav
  (Home / Crops / AI / Tasks / Profile) + onboarding stack, auth-guard
  hook reserved for Phase 5.
- Network: centralized Dio `ApiClient` (`API_BASE_URL` via `--dart-define`,
  default `http://10.0.2.2:8000/api/v1`); repository contracts only,
  no fake backend logic.
- Theme: Monochrome Impact tokens (surface `#FBF9F9`, on-surface `#1B1C1C`,
  primary `#5C5C5C`, containers, error `#BA1A1A`), Anton headlines /
  Poiret One body / Bebas Neue labels (Noto Sans Devanagari fallback for
  Hindi), 24px gutter, 24px xl radius, reusable `Am*` widgets.
- Localization: custom `AppLocalizations` delegate, EN + HI for all
  20 screens (11–20 Hindi translated fresh, layout preserved).
- All 20 Stitch screens reproduced as UI shells with prototype copy and
  `TODO(Phase N)` wiring markers; no Supabase/FastAPI/weather/AI logic.
- Assets: `brandmark.png` self-hosted (`app/assets/images/`); remaining
  remote images mapped in `docs/ASSETS.md`, zero runtime hotlinks.
- Android: INTERNET/CAMERA/LOCATION permissions; app ID verified.
- Placeholders only: `backend/.env.example` (no real secrets),
  `backend/README.md`, `supabase/README.md`.
- Prototypes untouched (`stitch_new_project_setup (1)/`).

## Files / features changed

- `app/lib/**` (~40 files): main, core, data contracts, 20 screens,
  routing, l10n. `app/pubspec.yaml`, `AndroidManifest.xml`,
  `app/docs/ASSETS.md`, `app/README_PHASE1.md`, `test/app_smoke_test.dart`.
- `backend/.env.example`, `backend/README.md`, `supabase/README.md`.
- Excluded from commit: `build/`, `.dart_tool/`, `.gradle/`,
  `local.properties`, crash logs (all git-ignored).

## Verification

- `flutter analyze`: No issues found (88.8s run).
- `flutter test`: +3 All tests passed.
- `flutter build apk --debug`: BUILD SUCCESSFUL (retry; first attempt
  killed by a Temurin JDK 17.0.20 internal crash during SDK install —
  JDK bug, not app code; orphaned Kotlin daemon cleared, no project
  files touched).

## APK

- Path: `app/build/app/outputs/flutter-apk/app-debug.apk`
- Size: 170,783,912 bytes (162.87 MB, debug, multi-arch)

## Known limitations

- Static prototype copy only; live data in Phases 2–10.
- Only `brandmark.png` vendored; other images pending (see ASSETS.md).
- google_fonts 9 resolves TextTheme via `package:material_ui`, so the
  base textTheme uses `.apply(fontFamily:)`; per-style GoogleFonts
  TextStyles unaffected.
- First builds on new machines download SDK components (slow-link warning).

## Next recommended phase

Phase 2 — Supabase: schema, migrations, RLS, Auth, `crop-scans` bucket,
seed data for State→…→Village. No Supabase tokens requested in Phase 1.
