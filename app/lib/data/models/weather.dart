// Normalized weather models matching backend /api/v1/weather/* contracts.

class CurrentWeather {
  const CurrentWeather({
    required this.temperatureC,
    this.humidityPct,
    this.windKmh,
    this.rainProbPct,
    this.summary = '',
  });

  final double temperatureC;
  final double? humidityPct;
  final double? windKmh;
  final double? rainProbPct;
  final String summary;

  factory CurrentWeather.fromJson(Map<String, dynamic> json) =>
      CurrentWeather(
        temperatureC: (json['temperature_c'] as num).toDouble(),
        humidityPct: (json['humidity_pct'] as num?)?.toDouble(),
        windKmh: (json['wind_kmh'] as num?)?.toDouble(),
        rainProbPct: (json['rain_prob_pct'] as num?)?.toDouble(),
        summary: json['summary'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'temperature_c': temperatureC,
    'humidity_pct': humidityPct,
    'wind_kmh': windKmh,
    'rain_prob_pct': rainProbPct,
    'summary': summary,
  };
}

class DayForecast {
  const DayForecast({
    required this.date,
    this.maxC,
    this.minC,
    this.rainMm,
    this.rainProbPct,
  });

  final String date;
  final double? maxC;
  final double? minC;
  final double? rainMm;
  final double? rainProbPct;

  factory DayForecast.fromJson(Map<String, dynamic> json) => DayForecast(
    date: json['date'] as String? ?? '',
    maxC: (json['max_c'] as num?)?.toDouble(),
    minC: (json['min_c'] as num?)?.toDouble(),
    rainMm: (json['rain_mm'] as num?)?.toDouble(),
    rainProbPct: (json['rain_prob_pct'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'date': date,
    'max_c': maxC,
    'min_c': minC,
    'rain_mm': rainMm,
    'rain_prob_pct': rainProbPct,
  };
}

class WeatherAdvisoryItem {
  const WeatherAdvisoryItem({
    required this.kind,
    required this.severity,
    required this.title,
    required this.text,
  });

  final String kind;
  final String severity;
  final String title;
  final String text;

  factory WeatherAdvisoryItem.fromJson(Map<String, dynamic> json) =>
      WeatherAdvisoryItem(
        kind: json['kind'] as String? ?? 'info',
        severity: json['severity'] as String? ?? 'info',
        title: json['title'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'severity': severity,
    'title': title,
    'text': text,
  };
}

class Forecast {
  const Forecast({
    required this.current,
    this.daily = const [],
    this.advisories = const [],
    this.stale = false,
  });

  final CurrentWeather current;
  final List<DayForecast> daily;
  final List<WeatherAdvisoryItem> advisories;

  /// True when served from cache because the network failed.
  final bool stale;

  factory Forecast.fromJson(Map<String, dynamic> json) => Forecast(
    current: CurrentWeather.fromJson(
      (json['current'] as Map).cast<String, dynamic>(),
    ),
    daily: [
      for (final d in (json['daily'] as List? ?? []))
        DayForecast.fromJson((d as Map).cast<String, dynamic>()),
    ],
    advisories: [
      for (final a in (json['advisories'] as List? ?? []))
        WeatherAdvisoryItem.fromJson((a as Map).cast<String, dynamic>()),
    ],
  );

  Map<String, dynamic> toJson() => {
    'current': current.toJson(),
    'daily': [for (final d in daily) d.toJson()],
    'advisories': [for (final a in advisories) a.toJson()],
  };

  Forecast asStale() =>
      Forecast(current: current, daily: daily, advisories: advisories, stale: true);
}
