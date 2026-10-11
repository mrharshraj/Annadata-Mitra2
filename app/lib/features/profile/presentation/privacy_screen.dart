import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// Privacy Policy screen (v1.0, 2026-10-11). Short in-app rendering of
/// docs/PRIVACY_POLICY.md. Published URL is pending — see the doc.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = <String, String>{
    'What we collect':
        'Email, name, phone (optional), village and farm details you enter, tasks, AI chats and crop photos you capture. No background tracking.',
    'How it is used':
        'Sign-in, syncing your farm records, weather for your area, AI advice and scan results — each farmer sees only their own data.',
    'Sharing':
        'Supabase hosts your data. Open-Meteo receives village coordinates for weather. Gemini receives your question plus farm context for advice. No ads, no analytics SDK, no data sale.',
    'Deletion':
        'Use DELETE MY DATA on the Profile screen: removes your profile, fields, crops, tasks, scans and AI history, then signs you out. Full account removal on request via support contact in the policy document.',
    'Contact':
        'Support email and postal address are placeholders in docs/PRIVACY_POLICY.md until publication. Policy version 1.0.',
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.privacyTitle.toUpperCase(),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          for (final e in _sections.entries) ...[
            Text(e.key.toUpperCase(), style: AppTextStyles.labelMd(context)),
            const SizedBox(height: AppSpacing.xs),
            Text(e.value, style: AppTextStyles.bodyMd(context)),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
