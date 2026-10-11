import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../../core/providers/supabase_providers.dart';
import '../../data/models/records.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/supabase_ai_history.dart';

/// Chat sender goes through the `ai-chat` Edge Function (Gemini key +
/// persistence server-side); history reads stay on Supabase direct access
/// (owner RLS). No FastAPI, no secrets in the app.
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return FastApiAiRepository(
    chat: ({
      required String message,
      String? conversationId,
      required Map<String, dynamic> context,
    }) async {
      final SupabaseClient client;
      try {
        client = ref.read(supabaseClientProvider);
      } catch (_) {
        throw const BackendFailure.notConfigured();
      }
      if (client.auth.currentSession == null) {
        throw const BackendFailure.authRequired();
      }
      final res = await client.functions.invoke(
        'ai-chat',
        body: {
          'message': message,
          'conversation_id': conversationId,
          'context': context,
        },
      );
      return _checked(res.data, res.status);
    },
    history: _LazyHistory(ref),
  );
});

/// Maps Edge Function responses to typed failures. Never throws raw.
Map<String, dynamic> _checked(dynamic data, int? status) {
  if (status == 200 && data is Map<String, dynamic>) {
    return data;
  }
  if (status == 401) throw const BackendFailure.authRequired();
  if (status == 403) {
    throw const BackendFailure(
      BackendFailureKind.permission,
      'Not allowed.',
    );
  }
  if (status == 429) {
    throw const BackendFailure(
      BackendFailureKind.network,
      'Too many requests. Try again shortly.',
    );
  }
  throw const BackendFailure(
    BackendFailureKind.network,
    'AI unavailable. Try again when online.',
  );
}

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
