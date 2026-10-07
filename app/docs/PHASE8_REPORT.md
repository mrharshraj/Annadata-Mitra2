# Phase 8 Report — Weather + Agricultural Advisories

## Backend

- `app/services/weather.py`: provider abstraction over keyless Open-Meteo
  (no API key needed); normalized `CurrentWeather`/`DayForecast`.
- `app/services/advisory.py`: deterministic rules — rain ≥10mm warning,
  heat ≥40°C, cold ≤5°C, wind ≥30km/h, humidity ≥85%, else normal-info.
- `app/routers/weather.py`: authed `GET /api/v1/weather/current` and
  `/forecast` (current + 3-day + advisories); provider failures → 502
  `weather_unavailable`, never tracebacks.
- `backend/tests/test_weather.py`: 7 tests (normalization, rule firing,
  calm-day, endpoint shape mocked, 502 path, auth required).

## Flutter

- `data/models/weather.dart`: contracts mirroring the API.
- `data/repositories/weather_repository.dart`: network-first with
  SharedPreferences cache (6h TTL); failures serve fresh cache flagged
  `stale`, else typed network error. Injectabler fetcher/clock.
- `core/providers/weather_providers.dart`: prefs injection, Dio-backed
  repo, home-farm `weatherProvider`.
- Dashboard: live 4-tile strip + top advisory card with cached badge,
  prototype fallback on failure. Weather overview: live current + hi/lo.
- `test/weather_test.dart`: 4 cache/TTL tests.
- `ApiClient`: 8s/15s timeouts for graceful degradation.

## Verification

- `pytest backend/tests`: 13/13 passed.
- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 24/24 passed.
- `flutter build apk --debug --no-pub`: BUILD SUCCESSFUL in 48.5s.
  APK: `app/build/app/outputs/flutter-apk/app-debug.apk`,
  205,568,713 bytes (196.05 MB, debug, multi-arch).

## Limitations / next

- Village geo still uses home-farm constants until profile geo is live.
- Advisories persist to `weather_advisories` in a later pass (service key).
- Phase 9: contextual AI assistant (provider abstraction + chat persistence).
