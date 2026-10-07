import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../models/crop.dart';
import 'repositories.dart';
import 'supabase_helpers.dart';

/// Read-only crop catalog + advice.
class SupabaseCropRepository implements CropRepository {
  SupabaseCropRepository(this._db);

  final SupabaseClient _db;

  @override
  Future<Result<List<Crop>>> listCrops() async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_db.auth.currentUser == null) {
      return const Err(BackendFailure.authRequired());
    }
    return guard(() async {
      final rows = await _db.from('crops').select().order('name');
      return (rows as List).cast<Map<String, dynamic>>().map(Crop.fromJson).toList();
    });
  }

  @override
  Future<Result<List<CropAdvice>>> adviceFor(String cropId) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_db.auth.currentUser == null) {
      return const Err(BackendFailure.authRequired());
    }
    return guard(() async {
      final rows = await _db
          .from('crop_advice')
          .select()
          .eq('crop_id', cropId)
          .order('created_at');
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(CropAdvice.fromJson)
          .toList();
    });
  }
}
