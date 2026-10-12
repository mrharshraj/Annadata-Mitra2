/// Supabase connection settings for the Flutter client.
///
/// Credentials NEVER live in source. They arrive via:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// Only the public anon key is used here — the service-role key must never
/// enter the app (it stays in `backend/.env`, Phase 3+). Note: Supabase now
/// labels this value "publishable key"; the role is identical, so the
/// `SUPABASE_ANON_KEY` define name is kept for stability.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: '',
  );

  /// True when both public values were supplied at build/run time.
  /// The app boots into UI-shell mode when false (Phase 1 behaviour);
  /// repositories surface [BackendFailure.notConfigured] instead of
  /// attempting network calls.
  static bool get isConfigured =>
      url.isNotEmpty && anonKey.isNotEmpty && _looksLikeUrl(url);

  static bool _looksLikeUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  static bool get isGoogleConfigured => googleWebClientId.isNotEmpty;

  /// Throws a descriptive [StateError] naming the missing define.
  static void requireConfigured() {
    if (isConfigured) return;
    throw StateError(
      'Supabase is not configured. Re-run with '
      '--dart-define=SUPABASE_URL=<https-url> '
      '--dart-define=SUPABASE_ANON_KEY=<anon-key>. '
      '--dart-define=GOOGLE_WEB_CLIENT_ID=<web-oauth-client-id>. '
      'See app/docs/PHASE2_REPORT.md for setup.',
    );
  }
}
