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
import '../../../data/models/crop.dart';
import '../../../data/models/field.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// 06 — Onboarding step 3/3: register first crop.
/// Live backend: creates a field for the signed-in farmer, picks a crop
/// from the catalog, and writes the planting (field_crops) row.
/// UI-shell mode keeps the prototype sample card.
class AddFirstCropScreen extends ConsumerStatefulWidget {
  const AddFirstCropScreen({super.key});

  @override
  ConsumerState<AddFirstCropScreen> createState() => _AddFirstCropScreenState();
}

class _AddFirstCropScreenState extends ConsumerState<AddFirstCropScreen> {
  final _fieldName = TextEditingController(text: 'North Field');
  List<Crop> _crops = const [];
  String? _cropId;
  bool _loading = false;
  bool _saving = false;
  BackendFailure? _error;

  @override
  void initState() {
    super.initState();
    _fieldName.addListener(() => setState(() {}));
    if (SupabaseConfig.isConfigured) {
      Future.microtask(_loadCrops);
    }
  }

  @override
  void dispose() {
    _fieldName.dispose();
    super.dispose();
  }

  Future<void> _loadCrops() async {
    setState(() => _loading = true);
    final res = await ref.read(cropRepositoryProvider).listCrops();
    if (!mounted) return;
    setState(() => _loading = false);
    switch (res) {
      case Ok(:final value):
        setState(() {
          _crops = value;
          _cropId = value.isEmpty ? null : value.first.id;
        });
      case Err(:final failure):
        setState(() => _error = failure);
    }
  }

  Future<void> _complete() async {
    final session = ref.read(sessionProvider);
    if (!SupabaseConfig.isConfigured || session == null || _cropId == null) {
      if (mounted) context.go(AppRoutes.home);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final fields = ref.read(fieldRepositoryProvider);
    final created = await fields.createField(
      Field(
        id: '',
        profileId: session.user.id,
        name: _fieldName.text.trim(),
      ),
    );
    if (!mounted) return;
    final String? fieldId;
    switch (created) {
      case Ok(:final value):
        fieldId = value.id;
      case Err(:final failure):
        setState(() {
          _saving = false;
          _error = failure;
        });
        return;
    }
    final planted = await fields.createPlanting(
      FieldCrop(id: '', fieldId: fieldId, cropId: _cropId!, status: 'active'),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (planted) {
      case Ok():
        context.go(AppRoutes.home);
      case Err(:final failure):
        setState(() => _error = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.addCropTitle.toUpperCase(),
      subtitle: l.addCropSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          const AmStepsHeader(step: 3, total: 3),
          const SizedBox(height: AppSpacing.md),
          if (!SupabaseConfig.isConfigured)
            const AmCard(
              child: ListTile(
                leading: Icon(Icons.grass),
                title: Text('WHEAT HD-2967'),
                subtitle: Text('Tillering — Day 42 (sample)'),
              ),
            )
          else ...[
            TextField(
              controller: _fieldName,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'FIELD NAME'),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                initialValue: _cropId,
                decoration: const InputDecoration(labelText: 'CROP'),
                items: [
                  for (final c in _crops)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _cropId = v),
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            BackendStateView.failure(failure: _error!),
          ],
          const SizedBox(height: AppSpacing.md),
          if (_saving)
            const Center(child: CircularProgressIndicator())
          else
            AmPrimaryButton(
              label: l.addCropCta,
              icon: Icons.check,
              onPressed: _complete,
            ),
        ],
      ),
    );
  }
}
