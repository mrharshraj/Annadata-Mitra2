import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// 20 — Identity + system hub, including the EN/HI toggle.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final isHindi = locale.languageCode == 'hi';

    return AmScaffold(
      title: l.profileTitle.toUpperCase(),
      subtitle: 'Kisan ID #KR-88219',
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          AmCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surfaceHigh,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RAMESH PATEL', style: AppTextStyles.labelMd(context)),
                      Text(
                        '8.5 acres — Taraori, Nilokheri',
                        style: AppTextStyles.bodyMd(context),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified, color: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AmCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.profileLanguage, style: AppTextStyles.labelMd(context)),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('EN')),
                    ButtonSegment(value: true, label: Text('हिं')),
                  ],
                  selected: {isHindi},
                  onSelectionChanged: (sel) {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(
                          Locale(sel.first ? 'hi' : 'en'),
                        );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AmSecondaryButton(
            label: l.profileLogout,
            icon: Icons.logout,
            // TODO(Phase 5): Supabase sign-out + clear session.
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l.phase1Note, style: AppTextStyles.bodyMd(context)),
        ],
      ),
    );
  }
}
