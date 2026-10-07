// Crop catalog + advice (authenticated read-only reference data).

class Crop {
  const Crop({
    required this.id,
    required this.name,
    this.scientificName,
    this.category,
    this.season,
    this.description,
  });

  final String id;
  final String name;
  final String? scientificName;
  final String? category;
  final String? season;
  final String? description;

  factory Crop.fromJson(Map<String, dynamic> json) => Crop(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    scientificName: json['scientific_name'] as String?,
    category: json['category'] as String?,
    season: json['season'] as String?,
    description: json['description'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'scientific_name': scientificName,
    'category': category,
    'season': season,
    'description': description,
  };
}

class CropAdvice {
  const CropAdvice({
    required this.id,
    required this.cropId,
    this.fieldId,
    this.profileId,
    this.adviceType,
    required this.title,
    required this.content,
    this.severity = 'info',
  });

  final String id;
  final String cropId;
  final String? fieldId;
  final String? profileId;
  final String? adviceType;
  final String title;
  final String content;
  final String? severity;

  factory CropAdvice.fromJson(Map<String, dynamic> json) => CropAdvice(
    id: json['id'] as String,
    cropId: json['crop_id'] as String,
    fieldId: json['field_id'] as String?,
    profileId: json['profile_id'] as String?,
    adviceType: json['advice_type'] as String?,
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    severity: json['severity'] as String? ?? 'info',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'crop_id': cropId,
    'field_id': fieldId,
    'profile_id': profileId,
    'advice_type': adviceType,
    'title': title,
    'content': content,
    'severity': severity,
  };
}
