import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// 09 — Hourly/daily forecast detail (static; Phase 8 wires FastAPI).
class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.forecastTitle.toUpperCase(),
      subtitle: l.forecastSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          AmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOURLY RUNOFF • NEXT 24H (SAMPLE)',
                  style: AppTextStyles.labelMd(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 8,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (_, i) => AmMetricTile(
                      icon: Icons.cloud,
                      value: '${20 + i}°',
                      label: '+${i}H',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
