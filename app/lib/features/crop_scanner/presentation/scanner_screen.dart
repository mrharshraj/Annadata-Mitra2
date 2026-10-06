import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// 13 — Scanner viewfinder shell. Camera + FastAPI analysis in Phase 10.
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.scannerTitle.toUpperCase(),
      subtitle: l.scannerSubtitle,
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Center(
                child: Text(
                  'VIEWFINDER (PHASE 10)',
                  style: AppTextStyles.labelMd(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AmPrimaryButton(
            label: l.scannerCta,
            icon: Icons.camera_alt,
            // TODO(Phase 10): image_picker + upload + analysis.
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
