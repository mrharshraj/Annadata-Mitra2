import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Rounded surface card used across dashboard, crops, weather and tasks.
class AmCard extends StatelessWidget {
  const AmCard({super.key, required this.child, this.onTap, this.color});

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color ?? AppColors.surfaceLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

/// Uppercase section header row (e.g. "TODAY'S WEATHER" + action link).
class AmSectionHeader extends StatelessWidget {
  const AmSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.labelMd(
                context,
              ).copyWith(color: AppColors.onSurface),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Small uppercase pill (location, weather, priority tags).
class AmPill extends StatelessWidget {
  const AmPill({super.key, required this.label, this.icon, this.dark = false});

  final String label;
  final IconData? icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? AppColors.onSurface : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: dark ? AppColors.surface : AppColors.primary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelMd(context).copyWith(
              color: dark ? AppColors.surface : AppColors.onSurface,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-line metric tile used in weather/crop grids.
class AmMetricTile extends StatelessWidget {
  const AmMetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineSm(context).copyWith(fontSize: 20),
          ),
          Text(
            label,
            style: AppTextStyles.labelMd(
              context,
            ).copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
