/// Compile-time public configuration only.
/// Never put service-role / AI / weather secrets here — those stay in
/// `backend/.env` (Phase 3). Supabase anon key wiring lands in Phase 2.
abstract final class AppConfig {
  /// FastAPI base URL placeholder. Phase 3 runs the backend locally;
  /// production URL is injected with `--dart-define=API_BASE_URL=...`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const String appName = 'Annadata Mitra';
  static const String appVersion = '1.0.0+1';
}
