import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// 10 — Filterable AI action stream (static chips; engine in Phase 9).
class AdvisoryScreen extends StatelessWidget {
  const AdvisoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.advisoryTitle.toUpperCase(),
      subtitle: l.advisorySubtitle,
      body: ListView(
        children: const [
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('ALL 4')),
              Chip(label: Text('IRRIGATION 2')),
              Chip(label: Text('PEST 1')),
              Chip(label: Text('NUTRITION 1')),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          AmCard(
            child: ListTile(
              leading: Icon(Icons.thunderstorm),
              title: Text('POSTPONE IRRIGATION 36H'),
              subtitle: Text('18mm rain expected (sample rule)'),
            ),
          ),
          AmCard(
            child: ListTile(
              leading: Icon(Icons.bug_report),
              title: Text('SCOUT FOR APHIDS'),
              subtitle: Text('Humid spell favors sucking pests (sample)'),
            ),
          ),
        ],
      ),
    );
  }
}
