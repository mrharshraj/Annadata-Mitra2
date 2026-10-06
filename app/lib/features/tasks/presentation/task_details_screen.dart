import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// 17 — Editable task form shell (wired to Supabase in Phase 7).
class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.taskDetailsTitle.toUpperCase(),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          const AmCard(
            child: ListTile(
              leading: Icon(Icons.psychology),
              title: Text('DELAY WHEAT IRRIGATION'),
              subtitle: Text('78% rainfall — North Canal 4.0 ac (sample)'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            decoration: InputDecoration(labelText: l.taskDetailsTitle),
          ),
          const SizedBox(height: AppSpacing.md),
          AmPrimaryButton(
            label: l.actionSave,
            icon: Icons.save,
            // TODO(Phase 7): update todo_tasks.
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
