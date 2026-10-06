import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// 15 — Chat transcript (static bubbles; streaming in Phase 9).
class AiConversationScreen extends StatelessWidget {
  const AiConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.conversationTitle.toUpperCase(),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          const Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AmCard(
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Should I irrigate wheat today?'),
                      subtitle: Text('Transcribed voice query (sample)'),
                    ),
                  ),
                  AmCard(
                    child: ListTile(
                      leading: Icon(Icons.smart_toy),
                      title: Text('Postpone 36 hours — rain likely.'),
                      subtitle: Text('Verified agronomist style (sample)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: l.conversationHint),
                  enabled: false,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                // TODO(Phase 9): send via FastAPI AI route.
                onPressed: () {},
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
