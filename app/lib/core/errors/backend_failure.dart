/// Backend failure taxonomy shared by every repository.
/// UI maps these to [BackendStateView] states; nothing here carries secrets.
enum BackendFailureKind {
  /// No SUPABASE_URL / SUPABASE_ANON_KEY supplied at build time.
  notConfigured,

  /// Caller needs an authenticated session (or it expired).
  authRequired,

  /// Transport-level problem (DNS, timeout, offline).
  network,

  /// RLS / policy denial or forbidden storage prefix.
  permission,

  /// Anything else (constraint violation, unexpected payload, ...).
  unknown,
}

/// Typed failure with a human-readable, log-safe message.
class BackendFailure implements Exception {
  const BackendFailure(this.kind, this.message);

  final BackendFailureKind kind;
  final String message;

  const BackendFailure.notConfigured()
    : kind = BackendFailureKind.notConfigured,
      message = 'Backend not configured.';

  const BackendFailure.authRequired()
    : kind = BackendFailureKind.authRequired,
      message = 'Sign in required.';

  const BackendFailure.unknown()
    : kind = BackendFailureKind.unknown,
      message = 'Unexpected error.';

  @override
  String toString() => 'BackendFailure($kind): $message';
}

/// Minimal Result type so repositories return data OR a typed failure
/// instead of throwing raw client exceptions into widgets.
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final BackendFailure failure;
}
