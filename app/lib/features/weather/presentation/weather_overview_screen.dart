import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 08 — Current weather snapshot (static; API in Phase 8).
class WeatherOverviewScreen extends StatelessWidget {
  const WeatherOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.weatherTitle.toUpperCase(),
      subtitle: l.weatherSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          AmCard(
            child: Column(
              children: [
                Text('24°C', style: AppTextStyles.headlineLg(context)),
                Text(
                  "Tomorrow's rain risk 75% (sample)",
                  style: AppTextStyles.bodyMd(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              Expanded(
                child: AmMetricTile(icon: Icons.air, value: '28', label: 'KM/H'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: AmMetricTile(
                  icon: Icons.water_drop,
                  value: '72%',
                  label: 'HUM',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: AmMetricTile(
                  icon: Icons.wb_twilight,
                  value: '4.2h',
                  label: 'SUN',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AmPrimaryButton(
            label: l.weatherDetails,
            icon: Icons.arrow_forward,
            onPressed: () => context.go(AppRoutes.forecast),
          ),
        ],
      ),
    );
  }
}
