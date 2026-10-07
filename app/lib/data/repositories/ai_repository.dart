import '../../core/errors/backend_failure.dart';
import '../models/records.dart';

/// Fetch function injected for testability (production: Dio POST).
typedef AiChatFetcher =
    Future<Map<String, dynamic>> Function({
      required String message,
      String? conversationId,
      required Map<String, dynamic> context,
    });

/// Contract: contextual chat with persistence server-side.
abstract class AiRepository {
  Future<Result<AiChatReply>> sendMessage({
    required String message,
    String? conversationId,
    Map<String, dynamic> context,
  });
  Future<Result<List<AiConversation>>> listConversations();
  Future<Result<List<AiMessage>>> messages(String conversationId);
}

class AiChatReply {
  const AiChatReply({
    required this.reply,
    required this.conversationId,
    this.lowConfidence = false,
  });

  final String reply;
  final String conversationId;
  final bool lowConfidence;

  factory AiChatReply.fromJson(Map<String, dynamic> json) => AiChatReply(
    reply: json['reply'] as String? ?? '',
    conversationId: json['conversation_id'] as String? ?? '',
    lowConfidence: json['low_confidence'] as bool? ?? false,
  );
}

/// FastAPI-backed chat. History reads stay on Supabase direct access
/// (owner RLS); sending goes through the backend for provider + persist.
class FastApiAiRepository implements AiRepository {
  FastApiAiRepository({
    required this.chat,
    required this.history,
  });

  final AiChatFetcher chat;
  final AiHistoryReader history;

  @override
  Future<Result<AiChatReply>> sendMessage({
    required String message,
    String? conversationId,
    Map<String, dynamic> context = const {},
  }) async {
    try {
      final json = await chat(
        message: message,
        conversationId: conversationId,
        context: context,
      );
      return Ok(AiChatReply.fromJson(json));
    } on BackendFailure catch (e) {
      return Err(e);
    } catch (_) {
      return const Err(
        BackendFailure(
          BackendFailureKind.network,
          'AI unavailable. Try again when online.',
        ),
      );
    }
  }

  @override
  Future<Result<List<AiConversation>>> listConversations() =>
      history.listConversations();

  @override
  Future<Result<List<AiMessage>>> messages(String conversationId) =>
      history.messages(conversationId);
}

/// Supabase-direct history reads (owner RLS enforced server-side).
abstract class AiHistoryReader {
  Future<Result<List<AiConversation>>> listConversations();
  Future<Result<List<AiMessage>>> messages(String conversationId);
}
