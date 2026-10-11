import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/backend_failure.dart';
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

/// Direct Open-Meteo client (keyless HTTPS, no backend hop).
final openMeteoDioProvider = Provider<Dio>(
  (_) => Dio(
    BaseOptions(
      baseUrl: 'https://api.open-meteo.com',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
    ),
  ),
);

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final dio = ref.watch(openMeteoDioProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return OpenMeteoWeatherRepository(
    fetcher: ({required double lat, required double lon}) async {
      final res = await dio.get<Map<String, dynamic>>(
        '/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current':
              'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
          'hourly': 'precipitation_probability',
          'daily':
              'temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max',
          'timezone': 'auto',
          'forecast_days': 3,
        },
      );
      return (res.data ?? {}).cast<String, dynamic>();
    },
    prefs: prefs,
  );
});

/// Live forecast for the home farm; UI falls back to prototype copy
/// while loading or on failure (weather is backend-optional).
final weatherProvider = FutureProvider<Forecast>((ref) async {
  final repo = ref.watch(weatherRepositoryProvider);
  switch (await repo.forecast(lat: homeLat, lon: homeLon)) {
    case Ok(:final value):
      return value;
    case Err(:final failure):
      throw failure;
  }
});
