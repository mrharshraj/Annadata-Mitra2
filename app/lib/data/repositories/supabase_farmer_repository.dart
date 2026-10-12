import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/errors/backend_failure.dart';
import '../models/profile.dart';
import 'repositories.dart';
import 'supabase_helpers.dart';

/// Supabase Auth and the farmer's own profile row.
/// Session persistence is handled by supabase_flutter (secure storage).
class SupabaseFarmerRepository implements FarmerRepository {
  SupabaseFarmerRepository(this._db);

  final SupabaseClient _db;
  static Future<void>? _googleInit;

  @override
  Session? currentSession() => backendMissing ? null : _db.auth.currentSession;

  @override
  Stream<AuthState> authChanges() =>
      backendMissing ? const Stream.empty() : _db.auth.onAuthStateChange;

  @override
  Future<Result<void>> signInWithGoogle() async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (!SupabaseConfig.isGoogleConfigured) {
      return const Err(
        BackendFailure(
          BackendFailureKind.notConfigured,
          'Google sign-in is not configured.',
        ),
      );
    }

    try {
      _googleInit ??= GoogleSignIn.instance.initialize(
        clientId: SupabaseConfig.googleAndroidClientId.isEmpty
            ? null
            : SupabaseConfig.googleAndroidClientId,
        serverClientId: SupabaseConfig.googleWebClientId,
      );
      await _googleInit;
      await GoogleSignIn.instance.signOut();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const Err(
          BackendFailure(
            BackendFailureKind.authRequired,
            'Google did not return an ID token. Check OAuth client setup.',
          ),
        );
      }
      return switch (await guard(
        () => _db.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        ),
      )) {
        Ok() => const Ok(null),
        Err(:final failure) => Err<void>(failure),
      };
    } on GoogleSignInException catch (e) {
      return Err(_googleFailure(e));
    } on TimeoutException {
      return const Err(
        BackendFailure(BackendFailureKind.network, 'Google sign-in timed out.'),
      );
    } catch (e) {
      return Err(BackendFailure(BackendFailureKind.unknown, e.toString()));
    }
  }

  @override
  Future<Result<void>> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    return switch (await guard(
      () => _db.auth.signUp(email: email, password: password),
    )) {
      Ok() => const Ok(null),
      Err(:final failure) => Err<void>(failure),
    };
  }

  @override
  Future<Result<void>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    return switch (await guard(
      () => _db.auth.signInWithPassword(email: email, password: password),
    )) {
      Ok() => const Ok(null),
      Err(:final failure) => Err<void>(failure),
    };
  }

  @override
  Future<Result<void>> requestEmailOtp(String email) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    return switch (await guard(() => _db.auth.signInWithOtp(email: email))) {
      Ok() => const Ok(null),
      Err(:final failure) => Err<void>(failure),
    };
  }

  @override
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    return switch (await guard(
      () => _db.auth.verifyOTP(type: OtpType.email, token: otp, email: email),
    )) {
      Ok() => const Ok(null),
      Err(:final failure) => Err<void>(failure),
    };
  }

  @override
  Future<Result<Profile?>> profile() async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final row = await _db
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return null;
      return Profile.fromJson((row as Map).cast<String, dynamic>());
    });
  }

  @override
  Future<Result<Profile>> upsertProfile(Profile draft) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final row = await _db
          .from('profiles')
          .upsert({...draft.toJson(), 'id': uid})
          .select()
          .single();
      return Profile.fromJson((row as Map).cast<String, dynamic>());
    });
  }

  @override
  Future<Result<void>> deleteOwnProfile() async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return const Err(BackendFailure.authRequired());
    // RLS delete-own policy + FK cascades remove fields, crops, tasks,
    // scans and AI history. Auth account removal is server-side.
    return switch (await guard(
      () => _db.from('profiles').delete().eq('id', uid),
    )) {
      Ok() => const Ok(null),
      Err(:final failure) => Err<void>(failure),
    };
  }

  @override
  Future<Result<void>> signOut() async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_googleInit != null) {
      unawaited(GoogleSignIn.instance.signOut());
    }
    return switch (await guard(() => _db.auth.signOut())) {
      Ok() => const Ok(null),
      Err(:final failure) => Err<void>(failure),
    };
  }

  BackendFailure _googleFailure(GoogleSignInException e) {
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => const BackendFailure(
        BackendFailureKind.authRequired,
        'Google sign-in was cancelled.',
      ),
      GoogleSignInExceptionCode.interrupted => const BackendFailure(
        BackendFailureKind.authRequired,
        'Google sign-in was interrupted. Try again.',
      ),
      GoogleSignInExceptionCode.uiUnavailable => const BackendFailure(
        BackendFailureKind.unknown,
        'Google account chooser is unavailable on this device.',
      ),
      GoogleSignInExceptionCode.clientConfigurationError =>
        const BackendFailure(
          BackendFailureKind.notConfigured,
          'Google OAuth client configuration is invalid.',
        ),
      GoogleSignInExceptionCode.providerConfigurationError =>
        const BackendFailure(
          BackendFailureKind.notConfigured,
          'Google Sign-In provider configuration is invalid.',
        ),
      _ => BackendFailure(
        BackendFailureKind.unknown,
        e.description ?? 'Google sign-in failed.',
      ),
    };
  }
}
