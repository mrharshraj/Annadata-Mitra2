import 'dart:io';

import 'package:annadata_mitra/core/config/supabase_config.dart';
import 'package:annadata_mitra/core/errors/backend_failure.dart';
import 'package:annadata_mitra/data/models/crop.dart';
import 'package:annadata_mitra/data/models/farmer_profile.dart';
import 'package:annadata_mitra/data/models/field.dart';
import 'package:annadata_mitra/data/models/location.dart';
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

  group('models', () {
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

    test('FarmerProfile defaults language to hi', () {
      final p = FarmerProfile.fromJson({'id': 'u1', 'name': 'Ramesh'});
      expect(p.preferredLanguage, 'hi');
      expect(p.copyWith(name: 'Sita').name, 'Sita');
      expect(p.toJson()['id'], 'u1');
    });

    test('FieldCrop parses date-only strings', () {
      final fc = FieldCrop.fromJson({
        'id': 'f1',
        'field_id': 'fld',
        'crop_id': 'c1',
        'sowing_date': '2026-11-12',
        'expected_harvest': null,
        'status': 'active',
      });
      expect(fc.sowingDate?.year, 2026);
      expect(fc.toJson()['sowing_date'], '2026-11-12');
    });

    test('TodoTask defaults incomplete, copyWith completes', () {
      final t = TodoTask.fromJson({
        'id': 't1',
        'farmer_id': 'u1',
        'title': 'Irrigate',
      });
      expect(t.isCompleted, isFalse);
      expect(t.copyWith(isCompleted: true).isCompleted, isTrue);
    });

    test('Crop + advice parse', () {
      final c = Crop.fromJson({'id': 'c1', 'name': 'Wheat'});
      expect(c.name, 'Wheat');
      final a = CropAdvice.fromJson({
        'id': 'a1',
        'crop_id': 'c1',
        'title': 'T',
        'advice_text': 'X',
      });
      expect(a.adviceText, 'X');
    });

    test('Records parse (advisory, message, scan)', () {
      final adv = WeatherAdvisory.fromJson({
        'id': 'w1',
        'village_id': 'v1',
        'advisory_date': '2026-10-07',
        'weather_data': {'rain': 18},
      });
      expect(adv.weatherData?['rain'], 18);
      final m = AiMessage.fromJson({
        'id': 'm1',
        'conversation_id': 'c1',
      });
      expect(m.role, 'user');
      final s = CropScan.fromJson({
        'id': 's1',
        'farmer_id': 'u1',
        'image_path': 'u1/a.jpg',
        'confidence': 0.8,
      });
      expect(s.confidence, 0.8);
    });
  });
}
