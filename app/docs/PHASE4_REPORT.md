# Phase 4 Report — Location Hierarchy End-to-End

## Implementation

- `features/location/presentation/location_selection.dart`:
  `LocationSelectionNotifier` (Riverpod `Notifier`) driving the cascade
  State → District → Block → Panchayat → Village via `LocationRepository`.
  Selecting a parent clears all levels below; failures surface as
  `BackendFailure` state; reads repo through `ref` so tests override it.
- `features/location/presentation/location_setup_screen.dart`: onboarding
  step 1/3 renders cascading dropdowns when a backend is configured and
  persists the full chain (state→village ids) onto the farmer profile via
  `upsertProfile` before continuing. UI-shell mode keeps the prototype
  static card unchanged.
- `data/models/profile.dart`: `copyWith` extended with
  state/district/block/panchayat ids.
- `test/location_selection_test.dart`: 4 tests over a fake repository
  (initial load, parent-switch clearing, full drill-down to village,
  failure surfacing).

## Verification

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 20/20 passed (16 existing + 4 new).
- `flutter build apk --debug --no-pub`: BUILD SUCCESSFUL in 81.3s.
  APK: `app/build/app/outputs/flutter-apk/app-debug.apk`,
  205,378,453 bytes (195.86 MB, debug, multi-arch).

## Limitations / next

- Live drill-down needs the pushed seed data (dashboard migration user step).
- Phase 5: farmer profile completion (name/phone/language + village link).
