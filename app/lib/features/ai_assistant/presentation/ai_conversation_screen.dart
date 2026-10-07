import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/errors/backend_failure.dart';
import '../../../core/providers/ai_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../core/widgets/backend_state_view.dart';
import '../../../l10n/app_localizations.dart';

/// 15 — Chat transcript. Signed-in farmers send through FastAPI (context
/// from profile + locale); replies flag low confidence honestly.
/// UI-shell mode keeps the prototype sample bubbles.
class AiConversationScreen extends ConsumerStatefulWidget {
  const AiConversationScreen({super.key});

  @override
  ConsumerState<AiConversationScreen> createState() =>
      _AiConversationScreenState();
}

class _ChatBubble {
  _ChatBubble(this.mine, this.text, {this.note = false});

  final bool mine;
  final String text;
  final bool note;
}

class _AiConversationScreenState extends ConsumerState<AiConversationScreen> {
  final _input = TextEditingController();
  final _bubbles = <_ChatBubble>[
    _ChatBubble(true, 'Should I irrigate wheat today?'),
    _ChatBubble(false, 'Postpone 36 hours — rain likely. (sample)'),
  ];
  String? _conversationId;
  bool _sending = false;
  BackendFailure? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
      _bubbles.add(_ChatBubble(true, text));
      _input.clear();
    });
    final locale = ref.read(localeProvider).languageCode;
    String? farmerName;
    try {
      final profile = await ref.read(profileProvider.future);
      farmerName = profile?.fullName;
    } catch (_) {
      farmerName = null;
    }
    final repo = ref.read(aiRepositoryProvider);
    final res = await repo.sendMessage(
      message: text,
      conversationId: _conversationId,
      context: {'language': locale, 'farmer_name': farmerName},
    );
    if (!mounted) return;
    setState(() => _sending = false);
    switch (res) {
      case Ok(:final value):
        _conversationId = value.conversationId;
        _bubbles.add(
          _ChatBubble(false, value.reply, note: value.lowConfidence),
        );
      case Err(:final failure):
        _error = failure;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final live = SupabaseConfig.isConfigured;
    return AmScaffold(
      title: l.conversationTitle.toUpperCase(),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView(
              children: [
                for (final b in _bubbles)
                  AmCard(
                    child: ListTile(
                      leading: Icon(
                        b.mine ? Icons.person : Icons.smart_toy,
                      ),
                      title: Text(b.text),
                      subtitle: b.note
                          ? const Text('Low confidence — verify locally.')
                          : null,
                    ),
                  ),
                if (_sending)
                  const AmCard(
                    child: ListTile(
                      leading: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text('Thinking…'),
                    ),
                  ),
                if (_error != null)
                  BackendStateView.failure(failure: _error!),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: InputDecoration(hintText: l.conversationHint),
                  enabled: live && !_sending,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: live && !_sending ? _send : null,
                child: Text(l.conversationSend),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
