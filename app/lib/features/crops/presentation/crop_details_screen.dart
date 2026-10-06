import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// 12 — Single-crop drill-down (static; tabs mirror prototype).
class CropDetailsScreen extends StatelessWidget {
  const CropDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.cropDetailsTitle,
      subtitle: l.cropDetailsStage,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          AmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OVERVIEW • HEALTH • ADVISORY • TIMELINE',
                    style: AppTextStyles.labelMd(context)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'North Canal Field, 4.0 acres, sown Nov 12 (sample).',
                  style: AppTextStyles.bodyMd(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
