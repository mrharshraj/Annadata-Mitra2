import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// 19 — Spatial asset registry (static; fields table in Phase 6).
class FieldsScreen extends StatelessWidget {
  const FieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.fieldsTitle.toUpperCase(),
      subtitle: l.fieldsSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          const AmCard(
            child: ListTile(
              leading: Icon(Icons.map),
              title: Text('NORTH FIELD — PARCEL 2A'),
              subtitle: Text('4.0 ac — Tube well + canal (sample)'),
            ),
          ),
          const AmCard(
            child: ListTile(
              leading: Icon(Icons.map),
              title: Text('SOUTH FIELD — PARCEL 1B'),
              subtitle: Text('4.5 ac — Canal (sample)'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AmPrimaryButton(
            label: l.fieldsAdd,
            icon: Icons.add,
            // TODO(Phase 6): insert into fields.
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
