import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../models/task.dart';
import 'repositories.dart';
import 'supabase_helpers.dart';

/// Owner-scoped task CRUD over public.tasks.
class SupabaseTaskRepository implements TaskRepository {
  SupabaseTaskRepository(this._db);

  final SupabaseClient _db;

  String? get _uid => _db.auth.currentUser?.id;

  @override
  Future<Result<List<FarmTask>>> listTasks() async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final rows = await _db
          .from('tasks')
          .select()
          .order('due_date', ascending: true, nullsFirst: true);
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(FarmTask.fromJson)
          .toList();
    });
  }

  @override
  Future<Result<FarmTask>> createTask(FarmTask draft) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    final uid = _uid;
    if (uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final row = await _db
          .from('tasks')
          .insert({...draft.toJson(), 'profile_id': uid})
          .select()
          .single();
      return FarmTask.fromJson((row as Map).cast<String, dynamic>());
    });
  }

  @override
  Future<Result<FarmTask>> setStatus(FarmTask task, String status) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final row = await _db
          .from('tasks')
          .update({'status': status})
          .eq('id', task.id)
          .select()
          .single();
      return FarmTask.fromJson((row as Map).cast<String, dynamic>());
    });
  }
}
