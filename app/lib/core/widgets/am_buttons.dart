import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Primary (dark) and secondary buttons matching the Stitch hero actions.
class AmPrimaryButton extends StatelessWidget {
  const AmPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
      label: Text(
        label,
        style: AppTextStyles.labelMd(
          context,
        ).copyWith(color: AppColors.surface),
      ),
    );
  }
}

class AmSecondaryButton extends StatelessWidget {
  const AmSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
      label: Text(label, style: AppTextStyles.labelMd(context)),
    );
  }
}

/// 3-step onboarding progress (Location → Farm → Crop).
class AmStepsHeader extends StatelessWidget {
  const AmStepsHeader({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP $step OF $total',
          style: AppTextStyles.labelMd(
            context,
          ).copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: step / total,
          backgroundColor: AppColors.surfaceHigh,
          color: AppColors.onSurface,
          minHeight: 6,
          borderRadius: BorderRadius.circular(999),
        ),
      ],
    );
  }
}
