import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 14 — Voice-first AI entry (static; provider abstraction in Phase 9).
class AskAiScreen extends StatelessWidget {
  const AskAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.askAiTitle,
      subtitle: l.askAiSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          const AmCard(
            child: ListTile(
              leading: Icon(Icons.grass, color: AppColors.primary),
              title: Text('WHEAT — DAY 42 (TILLERING)'),
              subtitle: Text('Mustard — Day 68 (sample context)'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.aiConversation),
              icon: const Icon(Icons.mic, size: 32),
              label: Text(l.askAiSpeak),
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 96),
                shape: const CircleBorder(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AmSecondaryButton(
            label: l.conversationTitle.toUpperCase(),
            icon: Icons.chat,
            onPressed: () => context.go(AppRoutes.aiConversation),
          ),
        ],
      ),
    );
  }
}
