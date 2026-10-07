import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 16 — Task list (static; CRUD in Phase 7).
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.tasksTitle.toUpperCase(),
      subtitle: l.tasksSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          AmCard(
            child: ListTile(
              leading: const Icon(Icons.priority_high),
              title: const Text('DELAY WHEAT IRRIGATION'),
              subtitle: Text(l.taskDetailsTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.taskDetails),
            ),
          ),
          const AmCard(
            child: ListTile(
              leading: Icon(Icons.science),
              title: Text('PREPARE UREA AFTER RAINS'),
              subtitle: Text('Due in 3 days (sample)'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AmPrimaryButton(
            label: l.tasksAdd,
            icon: Icons.add,
            // TODO(Phase 7): create tasks row.
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
