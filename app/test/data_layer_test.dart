import 'dart:io';

import 'package:annadata_mitra/core/config/supabase_config.dart';
import 'package:annadata_mitra/core/errors/backend_failure.dart';
import 'package:annadata_mitra/data/models/crop.dart';
import 'package:annadata_mitra/data/models/field.dart';
import 'package:annadata_mitra/data/models/location.dart';
import 'package:annadata_mitra/data/models/profile.dart';
import 'package:annadata_mitra/data/models/records.dart';
import 'package:annadata_mitra/data/models/task.dart';
import 'package:annadata_mitra/data/repositories/supabase_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseConfig', () {
    test('unconfigured without dart-defines (no hardcoding)', () {
      expect(SupabaseConfig.url, isEmpty);
      expect(SupabaseConfig.anonKey, isEmpty);
      expect(SupabaseConfig.isConfigured, isFalse);
      expect(SupabaseConfig.requireConfigured, throwsStateError);
    });
  });

  group('Result/guard', () {
    test('passes values through as Ok', () async {
      final res = await guard(() async => 42);
      expect(res, isA<Ok<int>>());
      expect((res as Ok<int>).value, 42);
    });

    test('SocketException maps to network', () async {
      final res = await guard<int>(() => throw const SocketException('x'));
      expect(res, isA<Err<int>>());
      expect(
        (res as Err<int>).failure.kind,
        BackendFailureKind.network,
      );
    });

    test('unexpected errors map to unknown', () async {
      final res = await guard<int>(() => throw StateError('boom'));
      expect((res as Err<int>).failure.kind, BackendFailureKind.unknown);
    });

    test('BackendFailure carries kind + message', () {
      const f = BackendFailure.authRequired();
      expect(f.kind, BackendFailureKind.authRequired);
      expect(f.toString(), contains('authRequired'));
    });
  });

  group('models (Phase 2 column contract)', () {
    test('StateItem round trip', () {
      const s = StateItem(id: 's1', name: 'Bihar', code: 'BR');
      expect(StateItem.fromJson(s.toJson()).name, 'Bihar');
    });

    test('Village parses numeric coords', () {
      final v = Village.fromJson({
        'id': 'v1',
        'panchayat_id': 'p1',
        'name': 'Nilokheri',
        'latitude': 29,
        'longitude': 76.9,
      });
      expect(v.latitude, 29.0);
      expect(v.longitude, 76.9);
      expect(v.toJson()['name'], 'Nilokheri');
    });

    test('Profile maps spec columns, defaults hi', () {
      final p = Profile.fromJson({
        'id': 'u1',
        'full_name': 'Ramesh',
        'village_id': 'v1',
      });
      expect(p.preferredLanguage, 'hi');
      expect(p.fullName, 'Ramesh');
      expect(p.toJson()['village_id'], 'v1');
      expect(p.copyWith(fullName: 'Sita').fullName, 'Sita');
    });

    test('Field maps area_value/area_unit + profile_id', () {
      final f = Field.fromJson({
        'id': 'f1',
        'profile_id': 'u1',
        'name': 'North',
        'area_value': 4,
        'area_unit': 'acre',
      });
      expect(f.areaValue, 4.0);
      expect(f.toJson()['profile_id'], 'u1');
    });

    test('FieldCrop parses expected_harvest_date', () {
      final fc = FieldCrop.fromJson({
        'id': 'f1',
        'field_id': 'fld',
        'crop_id': 'c1',
        'sowing_date': '2026-11-12',
        'expected_harvest_date': '2027-03-20',
        'status': 'active',
      });
      expect(fc.expectedHarvestDate?.year, 2027);
      expect(fc.toJson()['expected_harvest_date'], '2027-03-20');
    });

    test('FarmTask status-driven completion', () {
      final t = FarmTask.fromJson({
        'id': 't1',
        'profile_id': 'u1',
        'title': 'Irrigate',
      });
      expect(t.status, 'pending');
      expect(t.isCompleted, isFalse);
      final done = t.copyWith(status: 'done');
      expect(done.isCompleted, isTrue);
      expect(done.toJson()['profile_id'], 'u1');
    });

    test('Crop maps scientific_name/category', () {
      final c = Crop.fromJson({
        'id': 'c1',
        'name': 'Wheat',
        'scientific_name': 'Triticum aestivum',
        'category': 'cereal',
      });
      expect(c.scientificName, contains('Triticum'));
      final a = CropAdvice.fromJson({
        'id': 'a1',
        'crop_id': 'c1',
        'advice_type': 'irrigation',
        'title': 'T',
        'content': 'X',
      });
      expect(a.content, 'X');
    });

    test('Records parse (advisory, conversation, message, scan)', () {
      final adv = WeatherAdvisory.fromJson({
        'id': 'w1',
        'village_id': 'v1',
        'weather_date': '2026-10-07',
        'temperature': 24.5,
        'rainfall': 18,
        'severity': 'watch',
      });
      expect(adv.rainfall, 18.0);
      expect(adv.severity, 'watch');
      final conv = AiConversation.fromJson({
        'id': 'c1',
        'profile_id': 'u1',
      });
      expect(conv.language, 'hi');
      final m = AiMessage.fromJson({
        'id': 'm1',
        'conversation_id': 'c1',
      });
      expect(m.role, 'user');
      final s = CropScan.fromJson({
        'id': 's1',
        'profile_id': 'u1',
        'image_path': 'u1/a.jpg',
        'confidence': 0.8,
      });
      expect(s.status, 'pending');
    });
  });
}
