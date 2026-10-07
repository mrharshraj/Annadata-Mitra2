import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/errors/backend_failure.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../core/widgets/backend_state_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 03 — Passwordless email-OTP sign-in (Supabase Auth, Phase 2).
/// No passwords, no fake session: without backend credentials the screen
/// explains UI-shell mode instead of pretending to sign in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  BackendFailure? _error;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
    _otp.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await ref
        .read(farmerRepositoryProvider)
        .requestEmailOtp(_email.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    switch (res) {
      case Ok():
        setState(() => _codeSent = true);
      case Err(:final failure):
        setState(() => _error = failure);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await ref
        .read(farmerRepositoryProvider)
        .verifyEmailOtp(email: _email.text.trim(), otp: _otp.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    switch (res) {
      case Ok():
        // Session established; the router guard moves us to onboarding.
        context.go(AppRoutes.locationSetup);
      case Err(:final failure):
        setState(() => _error = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!SupabaseConfig.isConfigured) {
      return AmScaffold(
        title: l.signInTitle.toUpperCase(),
        subtitle: l.signInSubtitle,
        body: ListView(
          children: [
            const SizedBox(height: AppSpacing.md),
            const BackendStateView.failure(
              failure: BackendFailure.notConfigured(),
            ),
            Text(l.phase1Note, style: AppTextStyles.bodyMd(context)),
          ],
        ),
      );
    }
    return AmScaffold(
      title: l.signInTitle.toUpperCase(),
      subtitle: l.signInSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          const AmCard(
            child: ListTile(
              leading: Icon(Icons.mail_outline),
              title: Text('PASSWORDLESS EMAIL OTP'),
              subtitle: Text('6-digit code, no password to remember'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            enabled: !_busy && !_codeSent,
            decoration: const InputDecoration(
              labelText: 'EMAIL',
              hintText: 'ramesh@example.in',
            ),
          ),
          if (_codeSent) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              enabled: !_busy,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'OTP CODE',
                hintText: '123456',
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            BackendStateView.failure(failure: _error!),
          ],
          const SizedBox(height: AppSpacing.md),
          if (_busy)
            const Center(child: CircularProgressIndicator())
          else if (!_codeSent)
            AmPrimaryButton(
              label: 'SEND OTP CODE',
              icon: Icons.send,
              onPressed: _email.text.trim().isEmpty ? null : _sendCode,
            )
          else
            AmPrimaryButton(
              label: 'VERIFY & CONTINUE',
              icon: Icons.verified,
              onPressed: _otp.text.trim().length < 6 ? null : _verify,
            ),
        ],
      ),
    );
  }
}
