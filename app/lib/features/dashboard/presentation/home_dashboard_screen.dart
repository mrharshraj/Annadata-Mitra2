import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 07 — Main hub. Static prototype copy; live weather/advisory in Phase 8.
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.appName,
      subtitle: 'Karnal, Haryana',
      actions: const [Icon(Icons.notifications_outlined)],
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(l.dashboardGreeting, style: AppTextStyles.headlineSm(context)),
          const SizedBox(height: AppSpacing.sm),
          const Wrap(
            spacing: 8,
            children: [
              AmPill(label: 'NILOKHERI, KARNAL', icon: Icons.pin_drop),
              AmPill(label: '24°C SUNNY', icon: Icons.wb_sunny),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AmPill(label: 'HIGH PRIORITY • AI INSIGHT', dark: true),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l.dashboardHeroTitle,
                  style: AppTextStyles.headlineSm(context),
                ),
                Text(l.dashboardHeroBody, style: AppTextStyles.bodyMd(context)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AmPrimaryButton(
                        label: 'DELAY TASK',
                        icon: Icons.more_time,
                        onPressed: () => context.go(AppRoutes.tasks),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AmSecondaryButton(
                        label: 'ASK AI',
                        icon: Icons.chat_bubble_outline,
                        onPressed: () => context.go(AppRoutes.askAi),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AmSectionHeader(
            title: l.dashboardWeather,
            actionLabel: l.weatherDetails,
            onAction: () => context.go(AppRoutes.weather),
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              AmMetricTile(icon: Icons.thermostat, value: '24°', label: 'TEMP'),
              AmMetricTile(icon: Icons.water_drop, value: '62%', label: 'HUM'),
              AmMetricTile(icon: Icons.air, value: '11', label: 'KM/H'),
              AmMetricTile(icon: Icons.umbrella, value: '80%', label: 'TOM'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AmSectionHeader(title: l.dashboardCrops),
          const AmCard(
            child: ListTile(
              leading: Icon(Icons.grass, color: AppColors.primary),
              title: Text('WHEAT • DAY 42'),
              subtitle: Text('Tillering — soil adequate (sample)'),
              trailing: Chip(label: Text('OPTIMAL')),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
