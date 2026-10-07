import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/errors/backend_failure.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../core/widgets/backend_state_view.dart';
import '../../../data/models/profile.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 05 — Onboarding step 2/3: farmer identity.
/// Live backend: loads the signed-in farmer's row, edits full name, phone
/// and preferred language (synced with the app locale), and upserts.
/// UI-shell mode: prototype layout, no fake persistence.
class FarmProfileScreen extends ConsumerStatefulWidget {
  const FarmProfileScreen({super.key});

  @override
  ConsumerState<FarmProfileScreen> createState() => _FarmProfileScreenState();
}

class _FarmProfileScreenState extends ConsumerState<FarmProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  BackendFailure? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    if (SupabaseConfig.isConfigured) {
      Future.microtask(_load);
    } else {
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await ref.read(farmerRepositoryProvider).profile();
    if (!mounted) return;
    setState(() {
      _loaded = true;
      switch (res) {
        case Ok(:final value):
          if (value != null) {
            _name.text = value.fullName ?? '';
            _phone.text = value.phone ?? '';
            ref
                .read(localeProvider.notifier)
                .setLocale(Locale(value.preferredLanguage));
          }
        case Err(:final failure):
          // Missing row is normal pre-onboarding; only surface real errors.
          if (failure.kind != BackendFailureKind.authRequired) {
            _error = failure;
          }
      }
    });
  }

  Future<void> _saveAndContinue() async {
    final session = ref.read(sessionProvider);
    if (!SupabaseConfig.isConfigured || session == null) {
      if (mounted) context.go(AppRoutes.addCrop);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final locale = ref.read(localeProvider).languageCode;
    final repo = ref.read(farmerRepositoryProvider);
    final existing = await repo.profile();
    final base = switch (existing) {
      Ok(:final value) => value ?? Profile(id: session.user.id, fullName: ''),
      Err() => Profile(id: session.user.id, fullName: ''),
    };
    final res = await repo.upsertProfile(
      base.copyWith(
        fullName: _name.text.trim().isEmpty ? null : _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        preferredLanguage: locale,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (res) {
      case Ok():
        ref.invalidate(profileProvider);
        context.go(AppRoutes.addCrop);
      case Err(:final failure):
        setState(() => _error = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    return AmScaffold(
      title: l.farmTitle.toUpperCase(),
      subtitle: l.farmSubtitle,
      body: !_loaded
          ? const BackendStateView.loading()
          : ListView(
              children: [
                const SizedBox(height: AppSpacing.md),
                const AmStepsHeader(step: 2, total: 3),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _name,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'FULL NAME',
                    hintText: 'Ramesh Patel',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'PHONE',
                    hintText: '+91 …',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l.profileLanguage,
                      style: AppTextStyles.labelMd(context),
                    ),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('EN')),
                        ButtonSegment(value: true, label: Text('हिं')),
                      ],
                      selected: {locale.languageCode == 'hi'},
                      onSelectionChanged: (s) => ref
                          .read(localeProvider.notifier)
                          .setLocale(Locale(s.first ? 'hi' : 'en')),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  BackendStateView.failure(failure: _error!),
                ],
                const SizedBox(height: AppSpacing.md),
                if (_saving)
                  const Center(child: CircularProgressIndicator())
                else
                  AmPrimaryButton(
                    label: l.farmNext,
                    icon: Icons.arrow_forward,
                    onPressed: _name.text.trim().isEmpty &&
                            SupabaseConfig.isConfigured
                        ? null
                        : _saveAndContinue,
                  ),
                if (!SupabaseConfig.isConfigured) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Prototype form — persists to Supabase once configured.',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ],
            ),
    );
  }
}
