import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/errors/backend_failure.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../core/widgets/backend_state_view.dart';
import '../../../data/models/task.dart';
import '../../../l10n/app_localizations.dart';

/// 17 — Task editor. Receives the [FarmTask] via route `extra` from the
/// task list; edits title/description/priority/status and persists through
/// `updateTask`. Without a task (deep link / shell mode) shows the
/// prototype static shell.
class TaskDetailsScreen extends ConsumerStatefulWidget {
  const TaskDetailsScreen({super.key, this.task});

  final FarmTask? task;

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late String _priority;
  late String _status;
  bool _saving = false;
  BackendFailure? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task?.title ?? '');
    _desc = TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? 'medium';
    _status = widget.task?.status ?? 'pending';
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final task = widget.task;
    if (task == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final res = await ref
        .read(taskRepositoryProvider)
        .updateTask(
          task.copyWith(
            title: _title.text.trim(),
            description: () =>
                _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            priority: _priority,
            status: _status,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (res) {
      case Ok():
        context.pop(true);
      case Err(:final failure):
        setState(() => _error = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final task = widget.task;
    if (!SupabaseConfig.isConfigured || task == null) {
      return AmScaffold(
        title: l.taskDetailsTitle.toUpperCase(),
        body: ListView(
          children: const [
            SizedBox(height: AppSpacing.md),
            AmCard(
              child: ListTile(
                leading: Icon(Icons.psychology),
                title: Text('DELAY WHEAT IRRIGATION'),
                subtitle: Text('78% rainfall — North Canal 4.0 ac (sample)'),
              ),
            ),
          ],
        ),
      );
    }
    return AmScaffold(
      title: l.taskDetailsTitle.toUpperCase(),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _title,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'TITLE'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _desc,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'DESCRIPTION'),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: 'PRIORITY'),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('LOW')),
              DropdownMenuItem(value: 'medium', child: Text('MEDIUM')),
              DropdownMenuItem(value: 'high', child: Text('HIGH')),
            ],
            onChanged: (v) => setState(() => _priority = v ?? 'medium'),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'STATUS'),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('PENDING')),
              DropdownMenuItem(value: 'in_progress', child: Text('IN PROGRESS')),
              DropdownMenuItem(value: 'done', child: Text('DONE')),
              DropdownMenuItem(value: 'cancelled', child: Text('CANCELLED')),
            ],
            onChanged: (v) => setState(() => _status = v ?? 'pending'),
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
              label: l.actionSave,
              icon: Icons.save,
              onPressed: _title.text.trim().isEmpty ? null : _save,
            ),
        ],
      ),
    );
  }
}
