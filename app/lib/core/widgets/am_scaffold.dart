import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Centered max-width column reproducing the Stitch mobile gutter.
class AmScaffold extends StatelessWidget {
  const AmScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.body,
    this.actions,
    this.bottomBar,
    this.fab,
  });

  final String title;
  final String? subtitle;
  final Widget? body;
  final List<Widget>? actions;
  final Widget? bottomBar;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.labelMd(
                context,
              ).copyWith(color: AppColors.onSurface),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: AppTextStyles.bodyMd(context).copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        actions: actions,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: bottomBar,
      floatingActionButton: fab,
    );
  }
}
