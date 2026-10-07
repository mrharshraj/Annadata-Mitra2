import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../models/records.dart';
import 'ai_repository.dart';
import 'supabase_helpers.dart';

/// Owner-scoped conversation/message history over Supabase direct access.
class SupabaseAiHistory implements AiHistoryReader {
  SupabaseAiHistory(this._db);

  final SupabaseClient _db;

  String? get _uid => _db.auth.currentUser?.id;

  @override
  Future<Result<List<AiConversation>>> listConversations() async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final rows = await _db
          .from('ai_conversations')
          .select()
          .order('updated_at', ascending: false)
          .limit(20);
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(AiConversation.fromJson)
          .toList();
    });
  }

  @override
  Future<Result<List<AiMessage>>> messages(String conversationId) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    if (_uid == null) return const Err(BackendFailure.authRequired());
    return guard(() async {
      final rows = await _db
          .from('ai_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at');
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(AiMessage.fromJson)
          .toList();
    });
  }
}
