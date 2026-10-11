import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../models/field.dart';
import 'repositories.dart';
import 'supabase_helpers.dart';

/// Owner-scoped field + planting access (RLS enforces farmer_id).
class SupabaseFieldRepository implements FieldRepository {
  SupabaseFieldRepository(this._db);

  final SupabaseClient _db;

  String? get _uid => _db.auth.currentUser?.id;

  @override
  Future<Result<List<Field>>> listFields() async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final rows = await _db
          .from('fields')
          .select()
          .order('created_at', ascending: false);
      return (rows as List).cast<Map<String, dynamic>>().map(Field.fromJson).toList();
    });
  }

  @override
  Future<Result<Field>> createField(Field draft) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    final uid = _uid;
    if (uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final row = await _db
          .from('fields')
          .insert({...draft.toJson(), 'profile_id': uid})
          .select()
          .single();
      return Field.fromJson((row as Map).cast<String, dynamic>());
    });
  }

  @override
  Future<Result<void>> deleteField(String fieldId) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_uid == null) return const Err(BackendFailure.authRequired());
    return switch (await guard(
      () => _db.from('fields').delete().eq('id', fieldId),
    )) {
      Ok() => const Ok(null),
      Err(:final failure) => Err<void>(failure),
    };
  }

  @override
  Future<Result<FieldCrop>> createPlanting(FieldCrop draft) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final row = await _db
          .from('field_crops')
          .insert(draft.toJson())
          .select()
          .single();
      return FieldCrop.fromJson((row as Map).cast<String, dynamic>());
    });
  }

  @override
  Future<Result<List<FieldCrop>>> plantings(String fieldId) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final rows = await _db
          .from('field_crops')
          .select()
          .eq('field_id', fieldId)
          .order('created_at', ascending: false);
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(FieldCrop.fromJson)
          .toList();
    });
  }
}
