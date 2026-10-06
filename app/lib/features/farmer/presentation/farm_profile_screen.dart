import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 05 — Onboarding step 2/3: farm size + type.
class FarmProfileScreen extends StatelessWidget {
  const FarmProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.farmTitle.toUpperCase(),
      subtitle: l.farmSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          const AmStepsHeader(step: 2, total: 3),
          const SizedBox(height: AppSpacing.md),
          Text(l.farmSizeLabel, style: AppTextStyles.labelMd(context)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: const <Widget>[
              Chip(label: Text('2.5')),
              Chip(label: Text('5')),
              Chip(label: Text('10')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AmPrimaryButton(
            label: l.farmNext,
            icon: Icons.arrow_forward,
            // TODO(Phase 5): save acres/type to farmer_profiles.
            onPressed: () => context.go(AppRoutes.addCrop),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Prototype chips — real profile form in Phase 5.',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
