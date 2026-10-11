import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../models/profile.dart';
import 'repositories.dart';
import 'supabase_helpers.dart';

/// Email/password + email-OTP auth and the farmer's own profile row.
/// Session persistence is handled by supabase_flutter (secure storage).
class SupabaseFarmerRepository implements FarmerRepository {
  SupabaseFarmerRepository(this._db);

  final SupabaseClient _db;

  @override
  Session? currentSession() =>
      backendMissing ? null : _db.auth.currentSession;

  @override
  Stream<AuthState> authChanges() =>
      backendMissing ? const Stream.empty() : _db.auth.onAuthStateChange;

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
      final row = await _db.from('profiles').select().eq('id', uid).maybeSingle();
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
    return switch (await guard(() => _db.auth.signOut())) {
      Ok() => const Ok(null),
      Err(:final failure) => Err<void>(failure),
    };
  }
}
