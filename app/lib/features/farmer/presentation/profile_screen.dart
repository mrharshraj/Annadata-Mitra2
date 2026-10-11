import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/errors/backend_failure.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../routing/app_routes.dart';
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.privacyDeleteTitle),
        content: Text(l.privacyDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.actionBack),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(
              l.privacyDelete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final repo = ref.read(farmerRepositoryProvider);
    final deleted = await repo.deleteOwnProfile();
    if (!context.mounted) return;
    switch (deleted) {
      case Ok():
        await repo.signOut();
        if (context.mounted) context.go(AppRoutes.signIn);
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final isHindi = locale.languageCode == 'hi';
    // Live profile name when a backend is configured; prototype name otherwise.
    final liveName = !SupabaseConfig.isConfigured
        ? null
        : switch (ref.watch(profileProvider)) {
            AsyncData(:final value) => value?.fullName,
            _ => null,
          };
    final displayName = (liveName == null || liveName.isEmpty)
        ? 'RAMESH PATEL'
        : liveName.toUpperCase();

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
                      Text(displayName, style: AppTextStyles.labelMd(context)),
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
            // Real Supabase sign-out when configured; the router guard
            // returns to sign-in. No-op in UI-shell mode (no session).
            onPressed: SupabaseConfig.isConfigured
                ? () => ref.read(farmerRepositoryProvider).signOut()
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AmSecondaryButton(
            label: l.privacyTitle.toUpperCase(),
            icon: Icons.privacy_tip_outlined,
            onPressed: () => context.go(AppRoutes.privacy),
          ),
          if (SupabaseConfig.isConfigured) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_forever, color: AppColors.error),
              label: Text(
                l.privacyDelete,
                style: AppTextStyles.labelMd(
                  context,
                ).copyWith(color: AppColors.error),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(l.phase1Note, style: AppTextStyles.bodyMd(context)),
        ],
      ),
    );
  }
}
