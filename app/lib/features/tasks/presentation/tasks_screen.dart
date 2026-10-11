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
import '../../../routing/app_routes.dart';

/// 16 — Task list with live management when configured: list own tasks,
/// create (title/description/due/priority), mark done/reopen.
/// UI-shell mode keeps the prototype sample cards.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  late Future<Result<List<FarmTask>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Result<List<FarmTask>>> _load() {
    if (!SupabaseConfig.isConfigured) {
      return Future.value(const Err(BackendFailure.notConfigured()));
    }
    return ref.read(taskRepositoryProvider).listTasks();
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _toggle(FarmTask t) async {
    final next = t.isCompleted ? 'pending' : 'done';
    final res = await ref.read(taskRepositoryProvider).setStatus(t, next);
    if (!mounted) return;
    switch (res) {
      case Ok():
        _refresh();
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.tasksTitle.toUpperCase(),
      subtitle: l.tasksSubtitle,
      body: !SupabaseConfig.isConfigured
          ? ListView(
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
              ],
            )
          : FutureBuilder<Result<List<FarmTask>>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) return const BackendStateView.loading();
                return switch (snap.data!) {
                  Ok(:final value) when value.isEmpty =>
                    const BackendStateView.empty(
                      message: 'No tasks yet. Create your first task below.',
                    ),
                  Ok(:final value) => ListView(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      for (final t in value)
                        AmCard(
                          child: ListTile(
                            leading: Checkbox(
                              value: t.isCompleted,
                              onChanged: (_) => _toggle(t),
                            ),
                            title: Text(
                              t.title.toUpperCase(),
                              style: TextStyle(
                                decoration: t.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: t.dueDate == null
                                ? null
                                : Text(
                                    'Due ${t.dueDate!.toLocal().toString().substring(0, 10)} • ${t.priority}',
                                  ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final changed = await context.push<bool>(
                                AppRoutes.taskDetails,
                                extra: t,
                              );
                              if (changed == true && context.mounted) {
                                _refresh();
                              }
                            },
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      AmPrimaryButton(
                        label: l.tasksAdd,
                        icon: Icons.add,
                        onPressed: () async {
                          final created = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const _TaskForm(),
                          );
                          if (created == true) _refresh();
                        },
                      ),
                    ],
                  ),
                  Err(:final failure) => BackendStateView.failure(
                    failure: failure,
                    onRetry: _refresh,
                  ),
                };
              },
            ),
    );
  }
}

/// Create-task sheet. Tapping a task title toggles done/pending inline.
class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm();

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _priority = 'medium';
  bool _saving = false;
  BackendFailure? _error;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final res = await ref
        .read(taskRepositoryProvider)
        .createTask(
          FarmTask(
            id: '',
            profileId: session.user.id,
            title: _title.text.trim(),
            description: _desc.text.trim().isEmpty
                ? null
                : _desc.text.trim(),
            priority: _priority,
          ),
        );
    if (!mounted) return;
    switch (res) {
      case Ok():
        Navigator.pop(context, true);
      case Err(:final failure):
        setState(() {
          _saving = false;
          _error = failure;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('NEW TASK'),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _title,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'TITLE'),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _desc,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'DESCRIPTION'),
          ),
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
          if (_error != null) BackendStateView.failure(failure: _error!),
          const SizedBox(height: AppSpacing.sm),
          if (_saving)
            const CircularProgressIndicator()
          else
            AmPrimaryButton(
              label: 'SAVE TASK',
              icon: Icons.save,
              onPressed: _title.text.trim().isEmpty ? null : _save,
            ),
        ],
      ),
    );
  }
}
