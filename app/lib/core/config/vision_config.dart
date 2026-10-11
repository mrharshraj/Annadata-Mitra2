/// Direct-vision configuration. The key arrives ONLY via
/// `--dart-define=GEMINI_ANDROID_KEY=...` and MUST be Android-restricted
/// (package name + SHA-1) in Google AI Studio. Unrestricted keys must
/// never ship. Empty (default) = direct path disabled, Edge Function used.
abstract final class VisionConfig {
  static const String androidKey = String.fromEnvironment(
    'GEMINI_ANDROID_KEY',
    defaultValue: '',
  );

  static bool get directEnabled => androidKey.isNotEmpty;
}
