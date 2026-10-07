import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../models/task.dart';
import 'repositories.dart';
import 'supabase_helpers.dart';

/// Owner-scoped task CRUD.
class SupabaseTaskRepository implements TaskRepository {
  SupabaseTaskRepository(this._db);

  final SupabaseClient _db;

  String? get _uid => _db.auth.currentUser?.id;

  @override
  Future<Result<List<TodoTask>>> listTasks() async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final rows = await _db
          .from('todo_tasks')
          .select()
          .order('due_date', ascending: true, nullsFirst: true);
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(TodoTask.fromJson)
          .toList();
    });
  }

  @override
  Future<Result<TodoTask>> createTask(TodoTask draft) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    final uid = _uid;
    if (uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final row = await _db
          .from('todo_tasks')
          .insert({...draft.toJson(), 'farmer_id': uid})
          .select()
          .single();
      return TodoTask.fromJson((row as Map).cast<String, dynamic>());
    });
  }

  @override
  Future<Result<TodoTask>> setCompleted(TodoTask task, bool completed) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final row = await _db
          .from('todo_tasks')
          .update({'is_completed': completed})
          .eq('id', task.id)
          .select()
          .single();
      return TodoTask.fromJson((row as Map).cast<String, dynamic>());
    });
  }
}
