import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/errors/backend_failure.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../core/widgets/backend_state_view.dart';
import '../../../data/models/location.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 04 — Onboarding step 1/3: farm location.
/// With a live backend, states stream from Supabase (seeded in Phase 2);
/// in UI-shell mode the prototype static card is shown.
class LocationSetupScreen extends ConsumerWidget {
  const LocationSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.locationTitle.toUpperCase(),
      subtitle: l.locationSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          const AmStepsHeader(step: 1, total: 3),
          const SizedBox(height: AppSpacing.md),
          if (!SupabaseConfig.isConfigured)
            AmCard(
              child: ListTile(
                leading: const Icon(Icons.my_location),
                title: Text(
                  l.locationDetect,
                  style: AppTextStyles.labelMd(context),
                ),
                subtitle: Text(
                  'Nilokheri, Karnal — Indo-Gangetic Plain',
                  style: AppTextStyles.bodyMd(context),
                ),
              ),
            )
          else
            _LiveStates(ref: ref),
          const SizedBox(height: AppSpacing.md),
          AmPrimaryButton(
            label: l.locationNext,
            icon: Icons.arrow_forward,
            // TODO(Phase 4): persist State→District→Block→Panchayat→Village.
            onPressed: () => context.go(AppRoutes.farmProfile),
          ),
        ],
      ),
    );
  }
}

class _LiveStates extends StatefulWidget {
  const _LiveStates({required this.ref});

  final WidgetRef ref;

  @override
  State<_LiveStates> createState() => _LiveStatesState();
}

class _LiveStatesState extends State<_LiveStates> {
  late Future<Result<List<StateItem>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.ref.read(locationRepositoryProvider).states();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<List<StateItem>>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const BackendStateView.loading();
        return switch (snap.data!) {
          Ok(:final value) when value.isEmpty => const BackendStateView.empty(
            message: 'No states seeded yet.',
          ),
          Ok(:final value) => AmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECT STATE (${value.length} AVAILABLE)',
                  style: AppTextStyles.labelMd(context),
                ),
                for (final s in value.take(12))
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.map),
                    title: Text(s.name.toUpperCase()),
                    trailing: const Icon(Icons.chevron_right),
                    // TODO(Phase 4): drill District → Block → Panchayat → Village.
                    onTap: () {},
                  ),
              ],
            ),
          ),
          Err(:final failure) => BackendStateView.failure(
            failure: failure,
            onRetry: () => setState(() {
              _future = widget.ref.read(locationRepositoryProvider).states();
            }),
          ),
        };
      },
    );
  }
}
