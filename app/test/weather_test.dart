import 'package:annadata_mitra/core/errors/backend_failure.dart';
import 'package:annadata_mitra/data/models/weather.dart';
import 'package:annadata_mitra/data/repositories/weather_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Raw Open-Meteo payload shape (direct provider integration).
Map<String, dynamic> _payload() => {
  'current': {
    'temperature_2m': 24.0,
    'relative_humidity_2m': 90.0,
    'weather_code': 61,
    'wind_speed_10m': 35.0,
  },
  'hourly': {
    'precipitation_probability': [80],
  },
  'daily': {
    'time': ['2026-10-07', '2026-10-08'],
    'temperature_2m_max': [27.0, 26.0],
    'temperature_2m_min': [14.0, 15.0],
    'precipitation_sum': [2.0, 18.0],
    'precipitation_probability_max': [40, 78],
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('live fetch parses + caches', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = OpenMeteoWeatherRepository(
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
    final repo = OpenMeteoWeatherRepository(
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
    final live = OpenMeteoWeatherRepository(
      fetcher: ({required lat, required lon}) async => _payload(),
      prefs: prefs,
      clock: () => now,
    );
    await live.forecast(lat: 1.0, lon: 2.0);
    final offline = OpenMeteoWeatherRepository(
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
    final live = OpenMeteoWeatherRepository(
      fetcher: ({required lat, required lon}) async => _payload(),
      prefs: prefs,
      clock: () => now,
    );
    await live.forecast(lat: 1.0, lon: 2.0);
    final offline = OpenMeteoWeatherRepository(
      fetcher: ({required lat, required lon}) => throw Exception('down'),
      prefs: prefs,
      clock: () => now.add(const Duration(hours: 7)),
    );
    final res = await offline.forecast(lat: 1.0, lon: 2.0);
    expect(res, isA<Err<Forecast>>());
  });

  test('fromOpenMeteo normalizes + fires rules', () {
    final fc = Forecast.fromOpenMeteo(_payload());
    expect(fc.current.summary, 'Light rain');
    expect(fc.daily.length, 2);
    expect(
      fc.advisories.map((a) => a.kind),
      containsAll(['rain', 'wind', 'humidity']),
    );
  });

  test('fromOpenMeteo tolerates missing keys', () {
    final fc = Forecast.fromOpenMeteo({});
    expect(fc.current.temperatureC, 0);
    expect(fc.daily, isEmpty);
    // 0°C default trips the cold rule — same as the backend rules.
    expect(fc.advisories.map((a) => a.kind), ['cold']);
  });

  test('calm day yields info-only advisory', () {
    final fc = Forecast.fromOpenMeteo({
      'current': {'temperature_2m': 24, 'weather_code': 0},
      'daily': {
        'time': ['2026-10-07'],
        'precipitation_sum': [0.0],
      },
    });
    expect(fc.advisories.map((a) => a.kind), ['irrigation']);
  });
}
