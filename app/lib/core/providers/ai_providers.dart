import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/backend_failure.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/supabase_providers.dart';
import '../../data/models/records.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/supabase_ai_history.dart';

/// Chat sender goes through FastAPI (provider + persistence server-side);
/// history reads stay on Supabase direct access (owner RLS).
/// The client resolves lazily so UI-shell mode never throws at build.
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FastApiAiRepository(
    chat: ({
      required String message,
      String? conversationId,
      required Map<String, dynamic> context,
    }) async {
      String? token;
      try {
        token = ref.read(sessionProvider)?.accessToken;
      } catch (_) {
        token = null;
      }
      if (token == null) {
        throw const BackendFailure.authRequired();
      }
      final res = await dio.post<Map<String, dynamic>>(
        '/ai/chat',
        data: {
          'message': message,
          'conversation_id': conversationId,
          'context': context,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return (res.data ?? {}).cast<String, dynamic>();
    },
    history: _LazyHistory(ref),
  );
});

class _LazyHistory implements AiHistoryReader {
  _LazyHistory(this._ref);

  final Ref _ref;

  SupabaseAiHistory get _impl =>
      SupabaseAiHistory(_ref.read(supabaseClientProvider));

  @override
  Future<Result<List<AiConversation>>> listConversations() async {
    try {
      return await _impl.listConversations();
    } on BackendFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<List<AiMessage>>> messages(String conversationId) async {
    try {
      return await _impl.messages(conversationId);
    } on BackendFailure catch (e) {
      return Err(e);
    }
  }
}
