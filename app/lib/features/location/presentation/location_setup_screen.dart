import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 04 — Onboarding step 1/3: farm location.
class LocationSetupScreen extends StatelessWidget {
  const LocationSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.locationTitle.toUpperCase(),
      subtitle: l.locationSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          const AmStepsHeader(step: 1, total: 3),
          const SizedBox(height: AppSpacing.md),
          AmCard(
            child: ListTile(
              leading: const Icon(Icons.my_location),
              title: Text(l.locationDetect, style: AppTextStyles.labelMd(context)),
              subtitle: Text(
                'Nilokheri, Karnal — Indo-Gangetic Plain',
                style: AppTextStyles.bodyMd(context),
              ),
            ),
          ),
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
