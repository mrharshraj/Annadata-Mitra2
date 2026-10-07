import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/backend_failure.dart';
import '../../../../data/models/location.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../core/providers/supabase_providers.dart';

/// Cascading selection down the hierarchy. Each level loads from the
/// repository; choosing a parent clears everything below it.
class LocationSelectionState {
  const LocationSelectionState({
    this.states = const [],
    this.districts = const [],
    this.blocks = const [],
    this.panchayats = const [],
    this.villages = const [],
    this.stateId,
    this.districtId,
    this.blockId,
    this.panchayatId,
    this.villageId,
    this.loading = false,
    this.failure,
  });

  final List<StateItem> states;
  final List<District> districts;
  final List<Block> blocks;
  final List<Panchayat> panchayats;
  final List<Village> villages;
  final String? stateId;
  final String? districtId;
  final String? blockId;
  final String? panchayatId;
  final String? villageId;
  final bool loading;
  final BackendFailure? failure;

  String? get selectedVillageId => villageId;

  LocationSelectionState copyWith({
    List<StateItem>? states,
    List<District>? districts,
    List<Block>? blocks,
    List<Panchayat>? panchayats,
    List<Village>? villages,
    String? Function()? stateId,
    String? Function()? districtId,
    String? Function()? blockId,
    String? Function()? panchayatId,
    String? Function()? villageId,
    bool? loading,
    BackendFailure? Function()? failure,
  }) => LocationSelectionState(
    states: states ?? this.states,
    districts: districts ?? this.districts,
    blocks: blocks ?? this.blocks,
    panchayats: panchayats ?? this.panchayats,
    villages: villages ?? this.villages,
    stateId: stateId == null ? this.stateId : stateId(),
    districtId: districtId == null ? this.districtId : districtId(),
    blockId: blockId == null ? this.blockId : blockId(),
    panchayatId: panchayatId == null ? this.panchayatId : panchayatId(),
    villageId: villageId == null ? this.villageId : villageId(),
    loading: loading ?? this.loading,
    failure: failure == null ? this.failure : failure(),
  );
}

class LocationSelectionNotifier extends Notifier<LocationSelectionState> {
  LocationRepository get _repo => ref.read(locationRepositoryProvider);

  @override
  LocationSelectionState build() => const LocationSelectionState();

  Future<void> loadStates() async {
    state = state.copyWith(loading: true, failure: () => null);
    switch (await _repo.states()) {
      case Ok(:final value):
        state = state.copyWith(states: value, loading: false);
      case Err(:final failure):
        state = state.copyWith(loading: false, failure: () => failure);
    }
  }

  Future<void> selectState(String? id) async {
    state = state.copyWith(
      stateId: () => id,
      districts: const [],
      blocks: const [],
      panchayats: const [],
      villages: const [],
      districtId: () => null,
      blockId: () => null,
      panchayatId: () => null,
      villageId: () => null,
      loading: id != null,
      failure: () => null,
    );
    if (id == null) {
      state = state.copyWith(loading: false);
      return;
    }
    switch (await _repo.districts(id)) {
      case Ok(:final value):
        state = state.copyWith(districts: value, loading: false);
      case Err(:final failure):
        state = state.copyWith(loading: false, failure: () => failure);
    }
  }

  Future<void> selectDistrict(String? id) async {
    state = state.copyWith(
      districtId: () => id,
      blocks: const [],
      panchayats: const [],
      villages: const [],
      blockId: () => null,
      panchayatId: () => null,
      villageId: () => null,
      loading: id != null,
      failure: () => null,
    );
    if (id == null) {
      state = state.copyWith(loading: false);
      return;
    }
    switch (await _repo.blocks(id)) {
      case Ok(:final value):
        state = state.copyWith(blocks: value, loading: false);
      case Err(:final failure):
        state = state.copyWith(loading: false, failure: () => failure);
    }
  }

  Future<void> selectBlock(String? id) async {
    state = state.copyWith(
      blockId: () => id,
      panchayats: const [],
      villages: const [],
      panchayatId: () => null,
      villageId: () => null,
      loading: id != null,
      failure: () => null,
    );
    if (id == null) {
      state = state.copyWith(loading: false);
      return;
    }
    switch (await _repo.panchayats(id)) {
      case Ok(:final value):
        state = state.copyWith(panchayats: value, loading: false);
      case Err(:final failure):
        state = state.copyWith(loading: false, failure: () => failure);
    }
  }

  Future<void> selectPanchayat(String? id) async {
    state = state.copyWith(
      panchayatId: () => id,
      villages: const [],
      villageId: () => null,
      loading: id != null,
      failure: () => null,
    );
    if (id == null) {
      state = state.copyWith(loading: false);
      return;
    }
    switch (await _repo.villages(id)) {
      case Ok(:final value):
        state = state.copyWith(villages: value, loading: false);
      case Err(:final failure):
        state = state.copyWith(loading: false, failure: () => failure);
    }
  }

  void selectVillage(String? id) {
    state = state.copyWith(villageId: () => id);
  }
}

final locationSelectionProvider =
    NotifierProvider<LocationSelectionNotifier, LocationSelectionState>(
      LocationSelectionNotifier.new,
    );
