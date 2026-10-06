import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// 18 — Chronological farm log (static; source of truth in later phases).
class ActivityTimelineScreen extends StatelessWidget {
  const ActivityTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.timelineTitle.toUpperCase(),
      subtitle: l.timelineSubtitle,
      body: const Column(
        children: [
          SizedBox(height: AppSpacing.md),
          AmCard(
            child: ListTile(
              leading: Icon(Icons.water_drop),
              title: Text('IRRIGATION — WHEAT 2A'),
              subtitle: Text('Nov 28 — 18mm applied (sample)'),
            ),
          ),
          AmCard(
            child: ListTile(
              leading: Icon(Icons.science),
              title: Text('UREA TOP-DRESSING'),
              subtitle: Text('Dec 02 — 25kg/ac (sample)'),
            ),
          ),
        ],
      ),
    );
  }
}
