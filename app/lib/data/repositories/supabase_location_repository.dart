import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../models/location.dart';
import 'repositories.dart';
import 'supabase_helpers.dart';

/// PostgREST reads over the location reference tables.
/// RLS grants SELECT to authenticated users (migration 0002).
class SupabaseLocationRepository implements LocationRepository {
  SupabaseLocationRepository(this._db);

  final SupabaseClient _db;

  @override
  Future<Result<List<StateItem>>> states() async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    return guard(() async {
      final rows = await _db.from('states').select().order('name');
      return (rows as List).cast<Map<String, dynamic>>().map(StateItem.fromJson).toList();
    });
  }

  @override
  Future<Result<List<District>>> districts(String stateId) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    return guard(() async {
      final rows = await _db
          .from('districts')
          .select()
          .eq('state_id', stateId)
          .order('name');
      return (rows as List).cast<Map<String, dynamic>>().map(District.fromJson).toList();
    });
  }

  @override
  Future<Result<List<Block>>> blocks(String districtId) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    return guard(() async {
      final rows = await _db
          .from('blocks')
          .select()
          .eq('district_id', districtId)
          .order('name');
      return (rows as List).cast<Map<String, dynamic>>().map(Block.fromJson).toList();
    });
  }

  @override
  Future<Result<List<Panchayat>>> panchayats(String blockId) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    return guard(() async {
      final rows = await _db
          .from('panchayats')
          .select()
          .eq('block_id', blockId)
          .order('name');
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(Panchayat.fromJson)
          .toList();
    });
  }

  @override
  Future<Result<List<Village>>> villages(String panchayatId) async {
    if (backendMissing) return const Err(BackendFailure.notConfigured());
    return guard(() async {
      final rows = await _db
          .from('villages')
          .select()
          .eq('panchayat_id', panchayatId)
          .order('name');
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(Village.fromJson)
          .toList();
    });
  }
}
