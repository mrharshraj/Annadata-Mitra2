import 'package:annadata_mitra/core/errors/backend_failure.dart';
import 'package:annadata_mitra/data/models/weather.dart';
import 'package:annadata_mitra/data/repositories/weather_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _payload() => {
  'current': {
    'temperature_c': 24.0,
    'humidity_pct': 62.0,
    'wind_kmh': 11.0,
    'rain_prob_pct': 80.0,
    'summary': 'Light rain',
  },
  'daily': [
    {
      'date': '2026-10-07',
      'max_c': 27.0,
      'min_c': 14.0,
      'rain_mm': 2.0,
      'rain_prob_pct': 40.0,
    },
  ],
  'advisories': [
    {'kind': 'rain', 'severity': 'watch', 'title': 'T', 'text': 'X'},
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('live fetch parses + caches', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = FastApiWeatherRepository(
      fetcher: ({required lat, required lon}) async => _payload(),
      prefs: prefs,
    );
    final res = await repo.forecast(lat: 29.9, lon: 76.9);
    expect(res, isA<Ok<Forecast>>());
    final fc = (res as Ok<Forecast>).value;
    expect(fc.stale, isFalse);
    expect(fc.current.temperatureC, 24.0);
    expect(fc.advisories.first.kind, 'rain');
    expect(prefs.getString('wx_29.9000_76.9000'), isNotNull);
  });

  test('network failure without cache is a typed error', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = FastApiWeatherRepository(
      fetcher: ({required lat, required lon}) => throw Exception('down'),
      prefs: prefs,
    );
    final res = await repo.forecast(lat: 1.0, lon: 2.0);
    expect(res, isA<Err<Forecast>>());
    expect(
      (res as Err<Forecast>).failure.kind,
      BackendFailureKind.network,
    );
  });

  test('fresh cache serves stale-flagged payload on failure', () async {
    final now = DateTime(2026, 10, 7, 8);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final live = FastApiWeatherRepository(
      fetcher: ({required lat, required lon}) async => _payload(),
      prefs: prefs,
      clock: () => now,
    );
    await live.forecast(lat: 1.0, lon: 2.0);
    final offline = FastApiWeatherRepository(
      fetcher: ({required lat, required lon}) => throw Exception('down'),
      prefs: prefs,
      clock: () => now.add(const Duration(hours: 2)),
    );
    final res = await offline.forecast(lat: 1.0, lon: 2.0);
    expect((res as Ok<Forecast>).value.stale, isTrue);
  });

  test('expired cache is ignored', () async {
    final now = DateTime(2026, 10, 7, 8);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final live = FastApiWeatherRepository(
      fetcher: ({required lat, required lon}) async => _payload(),
      prefs: prefs,
      clock: () => now,
    );
    await live.forecast(lat: 1.0, lon: 2.0);
    final offline = FastApiWeatherRepository(
      fetcher: ({required lat, required lon}) => throw Exception('down'),
      prefs: prefs,
      clock: () => now.add(const Duration(hours: 7)),
    );
    final res = await offline.forecast(lat: 1.0, lon: 2.0);
    expect(res, isA<Err<Forecast>>());
  });
}
