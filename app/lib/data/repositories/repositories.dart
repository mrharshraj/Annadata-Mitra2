// Typed repository contracts. Supabase implementations live in
// supabase_*_repository.dart; widgets depend only on these abstractions.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../models/crop.dart';
import '../models/field.dart';
import '../models/location.dart';
import '../models/profile.dart';
import '../models/task.dart';

/// Reference hierarchy State → … → Village (authenticated read-only).
abstract class LocationRepository {
  Future<Result<List<StateItem>>> states();
  Future<Result<List<District>>> districts(String stateId);
  Future<Result<List<Block>>> blocks(String districtId);
  Future<Result<List<Panchayat>>> panchayats(String blockId);
  Future<Result<List<Village>>> villages(String panchayatId);
}

/// Supabase Auth + own profile row.
abstract class FarmerRepository {
  Session? currentSession();
  Stream<AuthState> authChanges();
  Future<Result<void>> signInWithGoogle();
  Future<Result<void>> signUpWithPassword({
    required String email,
    required String password,
  });
  Future<Result<void>> signInWithPassword({
    required String email,
    required String password,
  });
  Future<Result<void>> requestEmailOtp(String email);
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String otp,
  });
  Future<Result<Profile?>> profile();
  Future<Result<Profile>> upsertProfile(Profile draft);
  Future<Result<void>> deleteOwnProfile();
  Future<Result<void>> signOut();
}

/// Own fields + plantings.
abstract class FieldRepository {
  Future<Result<List<Field>>> listFields();
  Future<Result<Field>> createField(Field draft);
  Future<Result<void>> deleteField(String fieldId);
  Future<Result<List<FieldCrop>>> plantings(String fieldId);
  Future<Result<FieldCrop>> createPlanting(FieldCrop draft);
}

/// Crop catalog + advice (read-only reference).
abstract class CropRepository {
  Future<Result<List<Crop>>> listCrops();
  Future<Result<List<CropAdvice>>> adviceFor(String cropId);
}

/// Own tasks.
abstract class TaskRepository {
  Future<Result<List<FarmTask>>> listTasks();
  Future<Result<FarmTask>> createTask(FarmTask draft);
  Future<Result<FarmTask>> setStatus(FarmTask task, String status);
  Future<Result<FarmTask>> updateTask(FarmTask task);
}
