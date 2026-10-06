import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 02 — Value-prop onboarding.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.appName,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(l.welcomeTitle.toUpperCase(), style: AppTextStyles.headlineLg(context)),
          const SizedBox(height: AppSpacing.sm),
          Text(l.welcomeSubtitle, style: AppTextStyles.bodyMd(context)),
          const SizedBox(height: AppSpacing.lg),
          AmPrimaryButton(
            label: l.welcomeCta,
            icon: Icons.arrow_forward,
            onPressed: () => context.go(AppRoutes.signIn),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l.phase1Note, style: AppTextStyles.bodyMd(context)),
        ],
      ),
    );
  }
}
