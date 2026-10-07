// Crop catalog + advice (authenticated read-only reference data).

class Crop {
  const Crop({
    required this.id,
    required this.name,
    this.cropType,
    this.season,
  });

  final String id;
  final String name;
  final String? cropType;
  final String? season;

  factory Crop.fromJson(Map<String, dynamic> json) => Crop(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    cropType: json['crop_type'] as String?,
    season: json['season'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'crop_type': cropType,
    'season': season,
  };
}

class CropAdvice {
  const CropAdvice({
    required this.id,
    required this.cropId,
    required this.title,
    required this.adviceText,
  });

  final String id;
  final String cropId;
  final String title;
  final String adviceText;

  factory CropAdvice.fromJson(Map<String, dynamic> json) => CropAdvice(
    id: json['id'] as String,
    cropId: json['crop_id'] as String,
    title: json['title'] as String? ?? '',
    adviceText: json['advice_text'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'crop_id': cropId,
    'title': title,
    'advice_text': adviceText,
  };
}
