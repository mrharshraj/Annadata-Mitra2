import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 01 — Brand launch gate. Auto-advances to Welcome (prototype progress).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go(AppRoutes.welcome);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 144,
                  height: 144,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceLowest,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  // Self-hosted prototype brandmark (see docs/ASSETS.md).
                  child: Image.asset(
                    'assets/images/brandmark.png',
                    fit: BoxFit.contain,
                    semanticLabel: 'Annadata Mitra emblem',
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.eco,
                      size: 72,
                      color: AppColors.primary,
                      semanticLabel: 'Annadata Mitra emblem',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l.splashTitle.toUpperCase(),
                  style: AppTextStyles.headlineLg(context),
                  textAlign: TextAlign.center,
                ),
                Text(
                  l.splashSubtitle,
                  style: AppTextStyles.labelMd(
                    context,
                  ).copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                const LinearProgressIndicator(
                  backgroundColor: AppColors.surfaceHigh,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.splashLoading, style: AppTextStyles.labelMd(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
