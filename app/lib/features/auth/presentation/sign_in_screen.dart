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

/// 03 — SSO gate (UI shell; Supabase Auth lands in Phase 2/5).
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.signInTitle.toUpperCase(),
      subtitle: l.signInSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          const AmCard(
            child: ListTile(
              leading: Icon(Icons.verified_user, color: AppColors.primary),
              title: Text('Ramesh Patel'),
              subtitle: Text('ramesh@example.in'),
              trailing: Icon(Icons.radio_button_checked),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AmPrimaryButton(
            label: l.signInCta,
            icon: Icons.login,
            // TODO(Phase 5): replace with Supabase Auth OTP/Google flow.
            onPressed: () => context.go(AppRoutes.locationSetup),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l.phase1Note, style: AppTextStyles.bodyMd(context)),
        ],
      ),
    );
  }
}
