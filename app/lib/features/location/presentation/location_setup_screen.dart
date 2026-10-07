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
import '../../../data/models/profile.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import 'location_selection.dart';

/// 04 — Onboarding step 1/3: farm location.
/// Live backend: cascading State → District → Block → Panchayat → Village
/// from Supabase; continuing saves the village onto the farmer profile.
/// UI-shell mode: the prototype static card is shown.
class LocationSetupScreen extends ConsumerStatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  ConsumerState<LocationSetupScreen> createState() =>
      _LocationSetupScreenState();
}

class _LocationSetupScreenState extends ConsumerState<LocationSetupScreen> {
  bool _started = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && SupabaseConfig.isConfigured) {
      _started = true;
      Future.microtask(
        () => ref.read(locationSelectionProvider.notifier).loadStates(),
      );
    }
  }

  Future<void> _continue() async {
    final sel = ref.read(locationSelectionProvider);
    final villageId = sel.selectedVillageId;
    if (SupabaseConfig.isConfigured &&
        villageId != null &&
        ref.read(sessionProvider) != null) {
      setState(() => _saving = true);
      final repo = ref.read(farmerRepositoryProvider);
      final existing = await repo.profile();
      final base = switch (existing) {
        Ok(:final value) =>
          value ??
              Profile(
                id: ref.read(sessionProvider)!.user.id,
                fullName: '',
              ),
        Err() => Profile(
          id: ref.read(sessionProvider)!.user.id,
          fullName: '',
        ),
      };
      await repo.upsertProfile(
        base.copyWith(
          villageId: villageId,
          stateId: sel.stateId,
          districtId: sel.districtId,
          blockId: sel.blockId,
          panchayatId: sel.panchayatId,
        ),
      );
      if (!mounted) return;
      setState(() => _saving = false);
    }
    if (mounted) context.go(AppRoutes.farmProfile);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.locationTitle.toUpperCase(),
      subtitle: l.locationSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          const AmStepsHeader(step: 1, total: 3),
          const SizedBox(height: AppSpacing.md),
          if (!SupabaseConfig.isConfigured)
            AmCard(
              child: ListTile(
                leading: const Icon(Icons.my_location),
                title: Text(
                  l.locationDetect,
                  style: AppTextStyles.labelMd(context),
                ),
                subtitle: Text(
                  'Nilokheri, Karnal — Indo-Gangetic Plain',
                  style: AppTextStyles.bodyMd(context),
                ),
              ),
            )
          else
            const _CascadeForm(),
          const SizedBox(height: AppSpacing.md),
          if (_saving)
            const Center(child: CircularProgressIndicator())
          else
            AmPrimaryButton(
              label: l.locationNext,
              icon: Icons.arrow_forward,
              onPressed: _continue,
            ),
        ],
      ),
    );
  }
}

class _CascadeForm extends ConsumerWidget {
  const _CascadeForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(locationSelectionProvider);
    final notifier = ref.read(locationSelectionProvider.notifier);
    if (sel.failure != null) {
      return BackendStateView.failure(
        failure: sel.failure!,
        onRetry: notifier.loadStates,
      );
    }
    return AmCard(
      child: Column(
        children: [
          _Level(
            label: 'STATE',
            value: sel.stateId,
            items: {for (final s in sel.states) s.id: s.name},
            onChanged: notifier.selectState,
          ),
          _Level(
            label: 'DISTRICT',
            value: sel.districtId,
            items: {for (final d in sel.districts) d.id: d.name},
            onChanged: notifier.selectDistrict,
          ),
          _Level(
            label: 'BLOCK',
            value: sel.blockId,
            items: {for (final b in sel.blocks) b.id: b.name},
            onChanged: notifier.selectBlock,
          ),
          _Level(
            label: 'PANCHAYAT',
            value: sel.panchayatId,
            items: {for (final p in sel.panchayats) p.id: p.name},
            onChanged: notifier.selectPanchayat,
          ),
          _Level(
            label: 'VILLAGE',
            value: sel.villageId,
            items: {for (final v in sel.villages) v.id: v.name},
            onChanged: notifier.selectVillage,
          ),
          if (sel.loading)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _Level extends StatelessWidget {
  const _Level({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final e in items.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: items.isEmpty ? null : onChanged,
      ),
    );
  }
}
