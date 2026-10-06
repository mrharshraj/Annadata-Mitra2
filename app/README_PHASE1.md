# Annadata Mitra — Flutter (Phase 1 foundation)

India-first AI farming companion. Phase 1 = UI shell + architecture.
No Supabase / FastAPI / weather / AI / scanner backend yet.

## Stack

Flutter 3.47.5 / Dart 3.13.4 · Riverpod · go_router · Dio · google_fonts

## Run

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Backend URL placeholder: `--dart-define=API_BASE_URL=...`
(default `http://10.0.2.2:8000/api/v1`).

## Layout

```text
lib/
├── main.dart
├── core/{config,constants,theme,network,providers,widgets}
├── data/repositories/   # contracts only (Phase 2+ implements)
├── features/            # 20 screens (splash→…→profile)
├── l10n/                # en + hi, all screens
└── routing/             # go_router + bottom nav shell
```

Prototypes (untouched source of truth):
`stitch_new_project_setup (1)/stitch_new_project_setup/`
