import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/errors/backend_failure.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../core/widgets/backend_state_view.dart';
import '../../../data/models/field.dart';
import '../../../l10n/app_localizations.dart';

/// 19 — Field registry with live CRUD when configured:
/// list own fields, create (name/area/unit/soil), delete with confirm.
/// UI-shell mode keeps the prototype static cards.
class FieldsScreen extends ConsumerStatefulWidget {
  const FieldsScreen({super.key});

  @override
  ConsumerState<FieldsScreen> createState() => _FieldsScreenState();
}

class _FieldsScreenState extends ConsumerState<FieldsScreen> {
  late Future<Result<List<Field>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Result<List<Field>>> _load() {
    if (!SupabaseConfig.isConfigured) {
      return Future.value(const Err(BackendFailure.notConfigured()));
    }
    return ref.read(fieldRepositoryProvider).listFields();
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _delete(Field f) async {
    // Delete flows through RLS owner policy; confirm first.
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('DELETE FIELD?'),
        content: Text('${f.name} and its plantings will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await ref
        .read(fieldRepositoryProvider)
        .deleteField(f.id);
    if (!mounted) return;
    switch (res) {
      case Ok():
        _refresh();
      case Err(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.fieldsTitle.toUpperCase(),
      subtitle: l.fieldsSubtitle,
      body: !SupabaseConfig.isConfigured
          ? ListView(
              children: const [
                SizedBox(height: AppSpacing.md),
                AmCard(
                  child: ListTile(
                    leading: Icon(Icons.map),
                    title: Text('NORTH FIELD — PARCEL 2A'),
                    subtitle: Text('4.0 ac — Tube well + canal (sample)'),
                  ),
                ),
                AmCard(
                  child: ListTile(
                    leading: Icon(Icons.map),
                    title: Text('SOUTH FIELD — PARCEL 1B'),
                    subtitle: Text('4.5 ac — Canal (sample)'),
                  ),
                ),
              ],
            )
          : FutureBuilder<Result<List<Field>>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) return const BackendStateView.loading();
                return switch (snap.data!) {
                  Ok(:final value) when value.isEmpty =>
                    const BackendStateView.empty(
                      message: 'No fields yet. Add your first field below.',
                    ),
                  Ok(:final value) => ListView(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      for (final f in value)
                        AmCard(
                          child: ListTile(
                            leading: const Icon(Icons.map),
                            title: Text(
                              (f.name.isEmpty ? 'UNNAMED FIELD' : f.name)
                                  .toUpperCase(),
                            ),
                            subtitle: Text(
                              '${f.areaValue ?? '—'} ${f.areaUnit ?? ''} ${f.soilType ?? ''}',
                              style: AppTextStyles.bodyMd(context),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(f),
                              tooltip: 'Delete field',
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      AmPrimaryButton(
                        label: l.fieldsAdd,
                        icon: Icons.add,
                        onPressed: () async {
                          final created = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const _FieldForm(),
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

/// Create-field sheet: name, area value/unit, soil type.
class _FieldForm extends ConsumerStatefulWidget {
  const _FieldForm();

  @override
  ConsumerState<_FieldForm> createState() => _FieldFormState();
}

class _FieldFormState extends ConsumerState<_FieldForm> {
  final _name = TextEditingController();
  final _area = TextEditingController();
  String _unit = 'acre';
  final _soil = TextEditingController();
  bool _saving = false;
  BackendFailure? _error;

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _soil.dispose();
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
        .read(fieldRepositoryProvider)
        .createField(
          Field(
            id: '',
            profileId: session.user.id,
            name: _name.text.trim(),
            areaValue: double.tryParse(_area.text.trim()),
            areaUnit: _unit,
            soilType: _soil.text.trim().isEmpty ? null : _soil.text.trim(),
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
          Text('NEW FIELD', style: AppTextStyles.labelMd(context)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _name,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'FIELD NAME'),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _area,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'AREA VALUE'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _unit,
            decoration: const InputDecoration(labelText: 'AREA UNIT'),
            items: const [
              DropdownMenuItem(value: 'acre', child: Text('ACRE')),
              DropdownMenuItem(value: 'hectare', child: Text('HECTARE')),
              DropdownMenuItem(value: 'bigha', child: Text('BIGHA')),
              DropdownMenuItem(value: 'gunta', child: Text('GUNTA')),
            ],
            onChanged: (v) => setState(() => _unit = v ?? 'acre'),
          ),
          TextField(
            controller: _soil,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'SOIL TYPE'),
          ),
          if (_error != null) BackendStateView.failure(failure: _error!),
          const SizedBox(height: AppSpacing.sm),
          if (_saving)
            const CircularProgressIndicator()
          else
            AmPrimaryButton(
              label: 'SAVE FIELD',
              icon: Icons.save,
              onPressed: _name.text.trim().isEmpty ? null : _save,
            ),
        ],
      ),
    );
  }
}
