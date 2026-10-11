import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/backend_failure.dart';
import '../models/weather.dart';

/// Fetch function injected for testability (production: direct Open-Meteo
/// HTTPS GET — keyless, no backend hop). Returns the RAW provider payload;
/// normalization + advisory rules run in [Forecast.fromOpenMeteo].
typedef WeatherFetcher =
    Future<Map<String, dynamic>> Function({
      required double lat,
      required double lon,
    });

/// Contract: live forecast with stale-cache fallback.
abstract class WeatherRepository {
  Future<Result<Forecast>> forecast({
    required double lat,
    required double lon,
  });
}

/// FastAPI-backed forecasts. Strategy: try network, persist to cache;
/// on failure serve cache younger than [ttl], else a typed network error.
/// Nothing here fabricates weather — stale payloads are flagged.
class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository({
    required this.fetcher,
    required this.prefs,
    this.ttl = const Duration(hours: 6),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final WeatherFetcher fetcher;
  final SharedPreferences prefs;
  final Duration ttl;
  final DateTime Function() _clock;

  String _key(double lat, double lon) =>
      'wx_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';

  @override
  Future<Result<Forecast>> forecast({
    required double lat,
    required double lon,
  }) async {
    try {
      final raw = await fetcher(lat: lat, lon: lon).timeout(
        const Duration(seconds: 10),
      );
      final live = Forecast.fromOpenMeteo(raw);
      await prefs.setString(
        _key(lat, lon),
        jsonEncode({
          ...live.toJson(),
          'cached_at': _clock().toIso8601String(),
        }),
      );
      return Ok(live);
    } on TimeoutException {
      return _fromCache(lat, lon) ??
          const Err(
            BackendFailure(BackendFailureKind.network, 'Request timed out.'),
          );
    } catch (_) {
      return _fromCache(lat, lon) ??
          const Err(
            BackendFailure(
              BackendFailureKind.network,
              'Weather unavailable and no cached data.',
            ),
          );
    }
  }

  Result<Forecast>? _fromCache(double lat, double lon) {
    final raw = prefs.getString(_key(lat, lon));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.parse(json['cached_at'] as String);
      if (_clock().difference(at) > ttl) return null;
      return Ok(Forecast.fromJson(json).asStale());
    } catch (_) {
      return null;
    }
  }
}
