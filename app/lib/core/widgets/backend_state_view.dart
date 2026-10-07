import 'package:flutter/material.dart';

import '../errors/backend_failure.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';

// Standard backend-driven states: loading / empty / error / auth-required /
// not-configured. Screens render content only on success; everything else
// goes through here so failure modes stay consistent.
class BackendStateView extends StatelessWidget {
  const BackendStateView.loading({super.key})
    : _mode = _Mode.loading,
      message = null,
      failure = null,
      onRetry = null;

  const BackendStateView.empty({super.key, required this.message})
    : _mode = _Mode.empty,
      failure = null,
      onRetry = null;

  const BackendStateView.failure({
    super.key,
    required this.failure,
    this.onRetry,
  }) : _mode = _Mode.failure,
       message = null;

  final _Mode _mode;
  final String? message;
  final BackendFailure? failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (_mode) {
      case _Mode.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CircularProgressIndicator(),
          ),
        );
      case _Mode.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              message ?? '',
              style: AppTextStyles.bodyMd(context),
              textAlign: TextAlign.center,
            ),
          ),
        );
      case _Mode.failure:
        final activeFailure = failure ?? const BackendFailure.unknown();
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconFor(activeFailure.kind), size: 40),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _titleFor(context, activeFailure),
                  style: AppTextStyles.labelMd(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  activeFailure.message,
                  style: AppTextStyles.bodyMd(context),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: onRetry,
                    child: Text(l.actionRetry),
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }

  static IconData _iconFor(BackendFailureKind kind) => switch (kind) {
    BackendFailureKind.notConfigured => Icons.cloud_off,
    BackendFailureKind.authRequired => Icons.lock_outline,
    BackendFailureKind.network => Icons.wifi_off,
    BackendFailureKind.permission => Icons.block,
    BackendFailureKind.unknown => Icons.error_outline,
  };

  static String _titleFor(BuildContext context, BackendFailure f) {
    final l = AppLocalizations.of(context);
    return switch (f.kind) {
      BackendFailureKind.notConfigured => 'BACKEND NOT CONFIGURED',
      BackendFailureKind.authRequired => l.signInTitle.toUpperCase(),
      BackendFailureKind.network => 'NETWORK FAILURE',
      BackendFailureKind.permission => 'ACCESS DENIED',
      BackendFailureKind.unknown => 'SOMETHING WENT WRONG',
    };
  }
}

enum _Mode { loading, empty, failure }
