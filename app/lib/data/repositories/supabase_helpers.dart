import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../../core/config/supabase_config.dart';

/// Runs a Supabase call and maps client exceptions to [BackendFailure].
/// Callers check `SupabaseConfig.isConfigured` first via [requiresBackend].
Future<Result<T>> guard<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on AuthException catch (e) {
    return Err(BackendFailure(BackendFailureKind.authRequired, e.message));
  } on PostgrestException catch (e) {
    if (e.code == '42501' ||
        e.message.toLowerCase().contains('permission') ||
        e.message.toLowerCase().contains('policy')) {
      return Err(
        BackendFailure(
          BackendFailureKind.permission,
          'Database policy denied this action.',
        ),
      );
    }
    return Err(BackendFailure(BackendFailureKind.unknown, e.message));
  } on SocketException {
    return const Err(
      BackendFailure(
        BackendFailureKind.network,
        'No network connection. Try again when online.',
      ),
    );
  } on TimeoutException {
    return const Err(
      BackendFailure(BackendFailureKind.network, 'Request timed out.'),
    );
  } catch (e) {
    return Err(BackendFailure(BackendFailureKind.unknown, e.toString()));
  }
}

/// Short-circuit when the app runs without Supabase credentials.
bool get backendMissing => !SupabaseConfig.isConfigured;
