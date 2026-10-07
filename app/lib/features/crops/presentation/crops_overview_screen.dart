import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/errors/backend_failure.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../core/widgets/backend_state_view.dart';
import '../../../data/models/crop.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 11 — Crop portfolio. Live catalog from Supabase when configured
/// (read-only reference); prototype sample cards otherwise.
class CropsOverviewScreen extends ConsumerStatefulWidget {
  const CropsOverviewScreen({super.key});

  @override
  ConsumerState<CropsOverviewScreen> createState() =>
      _CropsOverviewScreenState();
}

class _CropsOverviewScreenState extends ConsumerState<CropsOverviewScreen> {
  late Future<Result<List<Crop>>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseConfig.isConfigured
        ? ref.read(cropRepositoryProvider).listCrops()
        : Future.value(const Err(BackendFailure.notConfigured()));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.cropsTitle.toUpperCase(),
      subtitle: l.cropsSubtitle,
      body: !SupabaseConfig.isConfigured
          ? ListView(
              children: [
                const SizedBox(height: AppSpacing.md),
                AmCard(
                  child: ListTile(
                    leading: const Icon(Icons.grass),
                    title: const Text('WHEAT HD-2967 — 4.0 AC'),
                    subtitle: Text(l.cropDetailsStage),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(AppRoutes.cropDetails),
                  ),
                ),
                const AmCard(
                  child: ListTile(
                    leading: Icon(Icons.eco),
                    title: Text('MUSTARD — 2.5 AC'),
                    subtitle: Text('Pod stage — Day 68 (sample)'),
                  ),
                ),
                const AmCard(
                  child: ListTile(
                    leading: Icon(Icons.spa),
                    title: Text('POTATO — 2.0 AC'),
                    subtitle: Text('Tuber bulking (sample)'),
                  ),
                ),
              ],
            )
          : FutureBuilder<Result<List<Crop>>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) return const BackendStateView.loading();
                return switch (snap.data!) {
                  Ok(:final value) when value.isEmpty =>
                    const BackendStateView.empty(
                      message: 'No crops in the catalog yet.',
                    ),
                  Ok(:final value) => ListView(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      for (final c in value)
                        AmCard(
                          child: ListTile(
                            leading: const Icon(Icons.grass),
                            title: Text(c.name.toUpperCase()),
                            subtitle: Text(
                              [
                                if (c.category != null) c.category!,
                                if (c.season != null) c.season!,
                              ].join(' • '),
                              style: AppTextStyles.bodyMd(context),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.go(AppRoutes.cropDetails),
                          ),
                        ),
                    ],
                  ),
                  Err(:final failure) => BackendStateView.failure(
                    failure: failure,
                    onRetry: () => setState(() {
                      _future = ref
                          .read(cropRepositoryProvider)
                          .listCrops();
                    }),
                  ),
                };
              },
            ),
    );
  }
}
