import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/errors/backend_failure.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../core/widgets/backend_state_view.dart';
import '../../../data/models/profile.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// Primary authentication gate. Android uses the native Google account
/// chooser, then exchanges the Google ID token with Supabase Auth.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  BackendFailure? _error;

  Future<void> _continueWithGoogle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final repo = ref.read(farmerRepositoryProvider);
    final result = await repo.signInWithGoogle();
    if (!mounted) return;

    switch (result) {
      case Ok():
        ref.invalidate(profileProvider);
        final profileResult = await repo.profile();
        if (!mounted) return;
        switch (profileResult) {
          case Ok(:final value):
            if (value == null) {
              await _createStarterProfile();
              if (!mounted) return;
              context.go(AppRoutes.locationSetup);
            } else if (_needsOnboarding(value)) {
              context.go(AppRoutes.locationSetup);
            } else {
              context.go(AppRoutes.home);
            }
          case Err(:final failure):
            setState(() {
              _busy = false;
              _error = failure;
            });
        }
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure;
        });
    }
  }

  Future<void> _createStarterProfile() async {
    final repo = ref.read(farmerRepositoryProvider);
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final user = session.user;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName = (metadata['full_name'] ?? metadata['name'] ?? '')
        .toString()
        .trim();
    final avatarUrl = (metadata['avatar_url'] ?? metadata['picture'] ?? '')
        .toString()
        .trim();
    final result = await repo.upsertProfile(
      Profile(
        id: user.id,
        fullName: fullName.isEmpty ? null : fullName,
        preferredLanguage: 'en',
        avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
      ),
    );
    if (result case Err(:final failure) when mounted) {
      setState(() {
        _busy = false;
        _error = failure;
      });
    }
  }

  bool _needsOnboarding(Profile profile) => profile.villageId == null;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!SupabaseConfig.isConfigured) {
      return AmScaffold(
        title: 'SIGN IN',
        subtitle: 'Connect Annadata Mitra to your farm account',
        body: ListView(
          children: [
            const SizedBox(height: AppSpacing.md),
            const BackendStateView.failure(
              failure: BackendFailure.notConfigured(),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.privacy),
              child: Text(l.privacyTitle.toUpperCase()),
            ),
            Text(l.phase1Note, style: AppTextStyles.bodyMd(context)),
          ],
        ),
      );
    }

    return AmScaffold(
      title: 'SIGN IN',
      subtitle: 'Continue securely with your Google account',
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.lg),
          const _HeroPanel(),
          const SizedBox(height: AppSpacing.lg),
          _GoogleButton(
            busy: _busy,
            configured: SupabaseConfig.isGoogleConfigured,
            onPressed: _continueWithGoogle,
          ),
          if (!SupabaseConfig.isGoogleConfigured) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Google sign-in needs GOOGLE_WEB_CLIENT_ID at build time.',
              style: AppTextStyles.bodyMd(context)
                  .copyWith(color: AppColors.error),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            BackendStateView.failure(failure: _error!),
          ],
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: _busy ? null : () => context.go(AppRoutes.privacy),
            child: Text(l.privacyTitle.toUpperCase()),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Your Google ID token is sent only to Supabase Auth. Server-side keys never enter the app.',
            style: AppTextStyles.bodyMd(context)
                .copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return AmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.verified_user_outlined),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Secure farmer access',
            style: AppTextStyles.headlineSm(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose a Google account from your device to sync your profile, fields, crops, tasks, scans and AI history.',
            style: AppTextStyles.bodyMd(context)
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.busy,
    required this.configured,
    required this.onPressed,
  });

  final bool busy;
  final bool configured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: busy || !configured ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleMark(),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Continue with Google',
                    style: AppTextStyles.labelMd(context)
                        .copyWith(color: AppColors.onSurface),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(20),
      painter: _GoogleMarkPainter(),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final rect = Offset.zero & size;
    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        rect.deflate(stroke / 2),
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    arc(const Color(0xFF4285F4), -0.15, 1.25);
    arc(const Color(0xFF34A853), 1.1, 1.25);
    arc(const Color(0xFFFBBC05), 2.35, 1.15);
    arc(const Color(0xFFEA4335), 3.5, 1.4);
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.5),
      Offset(size.width * 0.95, size.height * 0.5),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.square,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
