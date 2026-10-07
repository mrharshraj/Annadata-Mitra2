import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/weather_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 08 — Current weather snapshot: live FastAPI data when reachable,
/// prototype sample otherwise.
class WeatherOverviewScreen extends ConsumerWidget {
  const WeatherOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(weatherProvider);
    final live = switch (async) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final temp = live == null
        ? '24°C'
        : '${live.current.temperatureC.toStringAsFixed(0)}°C'
              '${live.stale ? ' (cached)' : ''}';
    final sub = live == null
        ? "Tomorrow's rain risk 75% (sample)"
        : '${live.current.summary} — rain '
            '${live.current.rainProbPct?.toStringAsFixed(0) ?? '—'}%';
    return AmScaffold(
      title: l.weatherTitle.toUpperCase(),
      subtitle: l.weatherSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          AmCard(
            child: Column(
              children: [
                Text(temp, style: AppTextStyles.headlineLg(context)),
                Text(sub, style: AppTextStyles.bodyMd(context)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AmMetricTile(
                  icon: Icons.air,
                  value: live?.current.windKmh?.toStringAsFixed(0) ?? '28',
                  label: 'KM/H',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AmMetricTile(
                  icon: Icons.water_drop,
                  value:
                      '${live?.current.humidityPct?.toStringAsFixed(0) ?? '72'}%',
                  label: 'HUM',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AmMetricTile(
                  icon: Icons.thermostat,
                  value: live == null || live.daily.isEmpty
                      ? '27°/14°'
                      : '${live.daily.first.maxC?.toStringAsFixed(0) ?? '—'}°/'
                        '${live.daily.first.minC?.toStringAsFixed(0) ?? '—'}°',
                  label: 'HI/LO',
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
