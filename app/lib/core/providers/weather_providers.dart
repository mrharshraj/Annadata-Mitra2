import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/backend_failure.dart';
import '../../core/providers/api_providers.dart';
import '../../data/models/weather.dart';
import '../../data/repositories/weather_repository.dart';

/// Injected in main() after SharedPreferences init; overridden in tests.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('bootstrap in main()'),
);

/// Prototype farm coordinates (Nilokheri, Karnal) until the profile's
/// village geo is wired in — matches seeded sample data.
const double homeLat = 29.9368;
const double homeLon = 76.9237;

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return FastApiWeatherRepository(
    fetcher: ({required double lat, required double lon}) async {
      final res = await dio.get<Map<String, dynamic>>(
        '/weather/forecast',
        queryParameters: {'lat': lat, 'lon': lon},
      );
      return (res.data ?? {}).cast<String, dynamic>();
    },
    prefs: prefs,
  );
});

/// Live forecast for the home farm; UI falls back to prototype copy
/// while loading or on failure (backend optional in Phase 8).
final weatherProvider = FutureProvider<Forecast>((ref) async {
  final repo = ref.watch(weatherRepositoryProvider);
  switch (await repo.forecast(lat: homeLat, lon: homeLon)) {
    case Ok(:final value):
      return value;
    case Err(:final failure):
      throw failure;
  }
});
