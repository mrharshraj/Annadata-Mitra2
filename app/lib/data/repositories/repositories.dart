// Typed repository contracts. Supabase implementations live in
// supabase_*_repository.dart; widgets depend only on these abstractions.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../models/crop.dart';
import '../models/farmer_profile.dart';
import '../models/field.dart';
import '../models/location.dart';
import '../models/task.dart';

/// Reference hierarchy State → … → Village (authenticated read-only).
abstract class LocationRepository {
  Future<Result<List<StateItem>>> states();
  Future<Result<List<District>>> districts(String stateId);
  Future<Result<List<Block>>> blocks(String districtId);
  Future<Result<List<Panchayat>>> panchayats(String blockId);
  Future<Result<List<Village>>> villages(String panchayatId);
}

/// Supabase Auth + own farmer profile.
abstract class FarmerRepository {
  Session? currentSession();
  Stream<AuthState> authChanges();
  Future<Result<void>> requestEmailOtp(String email);
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String otp,
  });
  Future<Result<FarmerProfile?>> profile();
  Future<Result<FarmerProfile>> upsertProfile(FarmerProfile draft);
  Future<Result<void>> signOut();
}

/// Own fields + plantings.
abstract class FieldRepository {
  Future<Result<List<Field>>> listFields();
  Future<Result<Field>> createField(Field draft);
  Future<Result<List<FieldCrop>>> plantings(String fieldId);
}

/// Crop catalog + advice (read-only reference).
abstract class CropRepository {
  Future<Result<List<Crop>>> listCrops();
  Future<Result<List<CropAdvice>>> adviceFor(String cropId);
}

/// Own tasks.
abstract class TaskRepository {
  Future<Result<List<TodoTask>>> listTasks();
  Future<Result<TodoTask>> createTask(TodoTask draft);
  Future<Result<TodoTask>> setCompleted(TodoTask task, bool completed);
}
