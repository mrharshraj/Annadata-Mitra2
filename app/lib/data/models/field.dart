// Field + planting (field_crops) models.

class Field {
  const Field({
    required this.id,
    required this.farmerId,
    required this.name,
    this.areaAcres,
    this.latitude,
    this.longitude,
    this.soilType,
  });

  final String id;
  final String farmerId;
  final String name;
  final double? areaAcres;
  final double? latitude;
  final double? longitude;
  final String? soilType;

  factory Field.fromJson(Map<String, dynamic> json) => Field(
    id: json['id'] as String,
    farmerId: json['farmer_id'] as String,
    name: json['name'] as String? ?? '',
    areaAcres: (json['area_acres'] as num?)?.toDouble(),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    soilType: json['soil_type'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'farmer_id': farmerId,
    'name': name,
    'area_acres': areaAcres,
    'latitude': latitude,
    'longitude': longitude,
    'soil_type': soilType,
  };
}

class FieldCrop {
  const FieldCrop({
    required this.id,
    required this.fieldId,
    required this.cropId,
    this.sowingDate,
    this.expectedHarvest,
    this.status,
  });

  final String id;
  final String fieldId;
  final String cropId;
  final DateTime? sowingDate;
  final DateTime? expectedHarvest;
  final String? status;

  factory FieldCrop.fromJson(Map<String, dynamic> json) => FieldCrop(
    id: json['id'] as String,
    fieldId: json['field_id'] as String,
    cropId: json['crop_id'] as String,
    sowingDate: json['sowing_date'] == null
        ? null
        : DateTime.parse(json['sowing_date'] as String),
    expectedHarvest: json['expected_harvest'] == null
        ? null
        : DateTime.parse(json['expected_harvest'] as String),
    status: json['status'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'field_id': fieldId,
    'crop_id': cropId,
    'sowing_date': sowingDate?.toIso8601String().substring(0, 10),
    'expected_harvest': expectedHarvest?.toIso8601String().substring(0, 10),
    'status': status,
  };
}
