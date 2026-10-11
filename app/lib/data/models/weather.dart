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

  /// Build from a raw Open-Meteo payload (direct client integration —
  /// no backend hop). Tolerates missing keys with nulls, never throws.
  factory Forecast.fromOpenMeteo(Map<String, dynamic> json) {
    final current = (json['current'] as Map? ?? {}).cast<String, dynamic>();
    final hourly = (json['hourly'] as Map? ?? {}).cast<String, dynamic>();
    final daily = (json['daily'] as Map? ?? {}).cast<String, dynamic>();
    final probs = hourly['precipitation_probability'];
    double? firstNum(List? xs) =>
        (xs != null && xs.isNotEmpty && xs.first is num)
        ? (xs.first as num).toDouble()
        : null;
    double? atNum(List? xs, int i) =>
        (xs != null && i < xs.length && xs[i] is num)
        ? (xs[i] as num).toDouble()
        : null;
    String codeSummary(int? code) => const {
      0: 'Clear', 1: 'Mainly clear', 2: 'Partly cloudy', 3: 'Overcast',
      45: 'Fog', 48: 'Icy fog', 51: 'Light drizzle', 53: 'Drizzle',
      55: 'Heavy drizzle', 61: 'Light rain', 63: 'Rain', 65: 'Heavy rain',
      71: 'Light snow', 73: 'Snow', 75: 'Heavy snow', 80: 'Light showers',
      81: 'Showers', 82: 'Violent showers', 95: 'Thunderstorm',
      96: 'Storm with hail', 99: 'Storm with hail',
    }[code ?? 0] ?? 'Unknown';
    double numOr(num? v, double dflt) => v == null ? dflt : v.toDouble();
    final cur = CurrentWeather(
      temperatureC: numOr(current['temperature_2m'] as num?, 0),
      humidityPct: (current['relative_humidity_2m'] as num?)?.toDouble(),
      windKmh: (current['wind_speed_10m'] as num?)?.toDouble(),
      rainProbPct: firstNum(probs as List?),
      summary: codeSummary(current['weather_code'] as int?),
    );
    final dates = daily['time'];
    final days = <DayForecast>[
      for (var i = 0; i < (dates is List ? dates.length : 0); i++)
        DayForecast(
          date: '${dates[i]}',
          maxC: atNum(daily['temperature_2m_max'] as List?, i),
          minC: atNum(daily['temperature_2m_min'] as List?, i),
          rainMm: atNum(daily['precipitation_sum'] as List?, i),
          rainProbPct:
              atNum(daily['precipitation_probability_max'] as List?, i),
        ),
    ];
    return Forecast(
      current: cur,
      daily: days,
      advisories: buildAgriAdvisories(cur, days),
    );
  }
}

/// Deterministic agricultural rules (Dart port of the backend rules —
/// identical thresholds; AI explanations layer on top in Phase 9+).
List<WeatherAdvisoryItem> buildAgriAdvisories(
  CurrentWeather current,
  List<DayForecast> days,
) {
  final out = <WeatherAdvisoryItem>[];
  final tomorrow = days.length > 1 ? days[1] : (days.isEmpty ? null : days[0]);
  if (tomorrow != null && (tomorrow.rainMm ?? 0) >= 10) {
    out.add(
      WeatherAdvisoryItem(
        kind: 'rain',
        severity: 'warning',
        title: 'Postpone irrigation',
        text:
            '${tomorrow.rainMm!.toStringAsFixed(0)} mm rain expected '
            '${tomorrow.date}; irrigating now risks waterlogging.',
      ),
    );
  }
  if (current.temperatureC >= 40) {
    out.add(
      const WeatherAdvisoryItem(
        kind: 'heat',
        severity: 'warning',
        title: 'Heat stress risk',
        text: 'Above 40°C: irrigate early morning, mulch exposed soil.',
      ),
    );
  }
  if (current.temperatureC <= 5) {
    out.add(
      const WeatherAdvisoryItem(
        kind: 'cold',
        severity: 'watch',
        title: 'Cold night risk',
        text: 'Near 5°C or below: protect seedlings, delay sowing.',
      ),
    );
  }
  if ((current.windKmh ?? 0) >= 30) {
    out.add(
      const WeatherAdvisoryItem(
        kind: 'wind',
        severity: 'watch',
        title: 'Strong wind',
        text: 'Above 30 km/h: pause spraying, secure young plants.',
      ),
    );
  }
  if ((current.humidityPct ?? 0) >= 85) {
    out.add(
      const WeatherAdvisoryItem(
        kind: 'humidity',
        severity: 'watch',
        title: 'Disease-favourable humidity',
        text: 'Above 85% humidity: scout for fungal disease and pests.',
      ),
    );
  }
  if (out.isEmpty) {
    out.add(
      const WeatherAdvisoryItem(
        kind: 'irrigation',
        severity: 'info',
        title: 'Conditions normal',
        text: 'No weather warnings. Follow the regular irrigation plan.',
      ),
    );
  }
  return out;
}
