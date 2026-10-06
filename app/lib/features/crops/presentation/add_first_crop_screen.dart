import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 06 — Onboarding step 3/3: register first crop.
class AddFirstCropScreen extends StatelessWidget {
  const AddFirstCropScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.addCropTitle.toUpperCase(),
      subtitle: l.addCropSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          const AmStepsHeader(step: 3, total: 3),
          const SizedBox(height: AppSpacing.md),
          const AmCard(
            child: ListTile(
              leading: Icon(Icons.grass),
              title: Text('WHEAT HD-2967'),
              subtitle: Text('Tillering — Day 42 (sample)'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AmPrimaryButton(
            label: l.addCropCta,
            icon: Icons.check,
            // TODO(Phase 6): write field + field_crops rows, then enter shell.
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
