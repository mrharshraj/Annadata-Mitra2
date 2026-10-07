import 'package:annadata_mitra/core/errors/backend_failure.dart';
import 'package:annadata_mitra/core/providers/supabase_providers.dart';
import 'package:annadata_mitra/data/models/location.dart';
import 'package:annadata_mitra/data/repositories/repositories.dart';
import 'package:annadata_mitra/features/location/presentation/location_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocationRepository implements LocationRepository {
  var failDistricts = false;

  @override
  Future<Result<List<StateItem>>> states() async => const Ok([
    StateItem(id: 's-br', name: 'Bihar', code: 'BR'),
    StateItem(id: 's-hr', name: 'Haryana', code: 'HR'),
  ]);

  @override
  Future<Result<List<District>>> districts(String stateId) async {
    if (failDistricts) {
      return const Err(BackendFailure(BackendFailureKind.network, 'offline'));
    }
    return Ok([
      District(id: 'd-$stateId-1', stateId: stateId, name: 'D1'),
      District(id: 'd-$stateId-2', stateId: stateId, name: 'D2'),
    ]);
  }

  @override
  Future<Result<List<Block>>> blocks(String districtId) async => Ok([
    Block(id: 'b-$districtId', districtId: districtId, name: 'B1'),
  ]);

  @override
  Future<Result<List<Panchayat>>> panchayats(String blockId) async => Ok([
    Panchayat(id: 'p-$blockId', blockId: blockId, name: 'P1'),
  ]);

  @override
  Future<Result<List<Village>>> villages(String panchayatId) async => Ok([
    Village(id: 'v-$panchayatId', panchayatId: panchayatId, name: 'V1'),
  ]);
}

ProviderContainer _container(FakeLocationRepository fake) =>
    ProviderContainer(
      overrides: [locationRepositoryProvider.overrideWithValue(fake)],
    );

void main() {
  test('loads states on start', () async {
    final c = _container(FakeLocationRepository());
    addTearDown(c.dispose);
    await c.read(locationSelectionProvider.notifier).loadStates();
    expect(c.read(locationSelectionProvider).states.length, 2);
  });

  test('selecting a state loads districts and clears below', () async {
    final c = _container(FakeLocationRepository());
    addTearDown(c.dispose);
    final n = c.read(locationSelectionProvider.notifier);
    await n.loadStates();
    await n.selectState('s-br');
    var s = c.read(locationSelectionProvider);
    expect(s.stateId, 's-br');
    expect(s.districts.length, 2);
    // Drill one level then switch state: children must clear.
    await n.selectDistrict('d-s-br-1');
    await n.selectState('s-hr');
    s = c.read(locationSelectionProvider);
    expect(s.stateId, 's-hr');
    expect(s.districtId, isNull);
    expect(s.blocks, isEmpty);
  });

  test('full drill-down reaches a village', () async {
    final c = _container(FakeLocationRepository());
    addTearDown(c.dispose);
    final n = c.read(locationSelectionProvider.notifier);
    await n.loadStates();
    await n.selectState('s-br');
    await n.selectDistrict('d-s-br-1');
    await n.selectBlock('b-d-s-br-1');
    await n.selectPanchayat('p-b-d-s-br-1');
    n.selectVillage('v-p-b-d-s-br-1');
    expect(
      c.read(locationSelectionProvider).selectedVillageId,
      'v-p-b-d-s-br-1',
    );
  });

  test('repository failure surfaces on state', () async {
    final fake = FakeLocationRepository()..failDistricts = true;
    final c = _container(fake);
    addTearDown(c.dispose);
    final n = c.read(locationSelectionProvider.notifier);
    await n.loadStates();
    await n.selectState('s-br');
    final s = c.read(locationSelectionProvider);
    expect(s.failure?.kind, BackendFailureKind.network);
    expect(s.loading, isFalse);
  });
}
