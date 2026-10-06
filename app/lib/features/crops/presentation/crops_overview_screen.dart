import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 11 — Crop portfolio (static sample; CRUD in Phase 6).
class CropsOverviewScreen extends StatelessWidget {
  const CropsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.cropsTitle.toUpperCase(),
      subtitle: l.cropsSubtitle,
      body: ListView(
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
          const SizedBox(height: AppSpacing.sm),
          AmPrimaryButton(
            label: l.cropsAdd,
            icon: Icons.add,
            // TODO(Phase 6): open crop create sheet.
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
