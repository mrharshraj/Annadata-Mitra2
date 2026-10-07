import 'package:annadata_mitra/core/errors/backend_failure.dart';
import 'package:annadata_mitra/data/models/records.dart';
import 'package:annadata_mitra/data/repositories/ai_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubHistory implements AiHistoryReader {
  @override
  Future<Result<List<AiConversation>>> listConversations() async => const Ok([
    AiConversation(id: 'c1', profileId: 'u1', title: 'Irrigation'),
  ]);

  @override
  Future<Result<List<AiMessage>>> messages(String conversationId) async =>
      const Ok([
        AiMessage(id: 'm1', conversationId: 'c1', role: 'user', content: 'Hi'),
      ]);
}

void main() {
  test('send maps reply + conversation id', () async {
    final repo = FastApiAiRepository(
      chat: ({required message, conversationId, required context}) async => {
        'reply': 'Postpone irrigation.',
        'conversation_id': conversationId ?? 'c-new',
        'low_confidence': true,
      },
      history: _StubHistory(),
    );
    final res = await repo.sendMessage(message: 'irrigate?');
    final ok = (res as Ok<AiChatReply>).value;
    expect(ok.reply, 'Postpone irrigation.');
    expect(ok.conversationId, 'c-new');
    expect(ok.lowConfidence, isTrue);
  });

  test('auth failure passes through typed', () async {
    final repo = FastApiAiRepository(
      chat: ({required message, conversationId, required context}) =>
          throw const BackendFailure.authRequired(),
      history: _StubHistory(),
    );
    final res = await repo.sendMessage(message: 'hi');
    expect(
      (res as Err<AiChatReply>).failure.kind,
      BackendFailureKind.authRequired,
    );
  });

  test('transport failure becomes network error', () async {
    final repo = FastApiAiRepository(
      chat: ({required message, conversationId, required context}) =>
          throw Exception('down'),
      history: _StubHistory(),
    );
    final res = await repo.sendMessage(message: 'hi');
    expect(
      (res as Err<AiChatReply>).failure.kind,
      BackendFailureKind.network,
    );
  });

  test('history delegates to reader', () async {
    final repo = FastApiAiRepository(
      chat: ({required message, conversationId, required context}) async => {},
      history: _StubHistory(),
    );
    final convs = await repo.listConversations();
    expect((convs as Ok<List<AiConversation>>).value.length, 1);
    final msgs = await repo.messages('c1');
    expect((msgs as Ok<List<AiMessage>>).value.first.role, 'user');
  });
}
