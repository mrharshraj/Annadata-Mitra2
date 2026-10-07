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
import '../../../data/repositories/repositories.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 03 — Supabase Auth gate (Phase 2): email/OTP code, email+password
/// login, and email+password signup. Passwords go only to Supabase Auth
/// over TLS; nothing is stored locally. Without backend credentials the
/// screen explains UI-shell mode instead of pretending to sign in.
/// (Google OAuth: prepared at the routing/guard level; no credentials
/// invented — provider enablement happens in the Supabase dashboard.)
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

enum _AuthMode { otp, passwordLogin, passwordSignup }

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  _AuthMode _mode = _AuthMode.otp;
  bool _codeSent = false;
  bool _busy = false;
  BackendFailure? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_email, _password, _otp]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  bool get _emailOk => _email.text.trim().contains('@');
  bool get _passwordOk => _password.text.length >= 6;

  void _fail(BackendFailure f) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = f;
    });
  }

  void _done() {
    if (!mounted) return;
    setState(() => _busy = false);
    context.go(AppRoutes.locationSetup);
  }

  Future<void> _run(Future<Result<void>> Function() call) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await call();
    switch (res) {
      case Ok():
        if (_mode == _AuthMode.otp && !_codeSent) {
          if (mounted) {
            setState(() {
              _busy = false;
              _codeSent = true;
            });
          }
        } else {
          _done();
        }
      case Err(:final failure):
        _fail(failure);
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
    final repo = ref.read(farmerRepositoryProvider);
    return AmScaffold(
      title: l.signInTitle.toUpperCase(),
      subtitle: l.signInSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<_AuthMode>(
            segments: const [
              ButtonSegment(value: _AuthMode.otp, label: Text('OTP')),
              ButtonSegment(
                value: _AuthMode.passwordLogin,
                label: Text('LOGIN'),
              ),
              ButtonSegment(
                value: _AuthMode.passwordSignup,
                label: Text('SIGN UP'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.first;
              _codeSent = false;
              _error = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          const AmCard(
            child: ListTile(
              leading: Icon(Icons.mail_outline),
              title: Text('SECURE FARMER SIGN IN'),
              subtitle: Text('Sessions persist securely on this device'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'EMAIL',
              hintText: 'ramesh@example.in',
            ),
          ),
          if (_mode != _AuthMode.otp) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _password,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'PASSWORD',
                hintText: 'min 6 characters',
              ),
            ),
          ],
          if (_mode == _AuthMode.otp && _codeSent) ...[
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
          else
            _actionButton(repo),
        ],
      ),
    );
  }

  Widget _actionButton(FarmerRepository repo) {
    final email = _email.text.trim();
    switch (_mode) {
      case _AuthMode.otp:
        if (!_codeSent) {
          return AmPrimaryButton(
            label: 'SEND OTP CODE',
            icon: Icons.send,
            onPressed: _emailOk
                ? () => _run(() => repo.requestEmailOtp(email))
                : null,
          );
        }
        return AmPrimaryButton(
          label: 'VERIFY & CONTINUE',
          icon: Icons.verified,
          onPressed: _otp.text.trim().length < 6
              ? null
              : () => _run(
                  () => repo.verifyEmailOtp(
                    email: email,
                    otp: _otp.text.trim(),
                  ),
                ),
        );
      case _AuthMode.passwordLogin:
        return AmPrimaryButton(
          label: 'LOGIN',
          icon: Icons.login,
          onPressed: _emailOk && _passwordOk
              ? () => _run(
                  () => repo.signInWithPassword(
                    email: email,
                    password: _password.text,
                  ),
                )
              : null,
        );
      case _AuthMode.passwordSignup:
        return AmPrimaryButton(
          label: 'CREATE ACCOUNT',
          icon: Icons.person_add,
          onPressed: _emailOk && _passwordOk
              ? () => _run(
                  () => repo.signUpWithPassword(
                    email: email,
                    password: _password.text,
                  ),
                )
              : null,
        );
    }
  }
}
