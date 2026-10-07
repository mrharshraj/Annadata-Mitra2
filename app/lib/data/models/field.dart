// Field + planting (field_crops) models.

class Field {
  const Field({
    required this.id,
    required this.profileId,
    this.villageId,
    required this.name,
    this.areaValue,
    this.areaUnit = 'acre',
    this.latitude,
    this.longitude,
    this.soilType,
    this.notes,
  });

  final String id;
  final String profileId;
  final String? villageId;
  final String name;
  final double? areaValue;
  final String? areaUnit;
  final double? latitude;
  final double? longitude;
  final String? soilType;
  final String? notes;

  factory Field.fromJson(Map<String, dynamic> json) => Field(
    id: json['id'] as String,
    profileId: json['profile_id'] as String,
    villageId: json['village_id'] as String?,
    name: json['name'] as String? ?? '',
    areaValue: (json['area_value'] as num?)?.toDouble(),
    areaUnit: json['area_unit'] as String? ?? 'acre',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    soilType: json['soil_type'] as String?,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'profile_id': profileId,
    'village_id': villageId,
    'name': name,
    'area_value': areaValue,
    'area_unit': areaUnit,
    'latitude': latitude,
    'longitude': longitude,
    'soil_type': soilType,
    'notes': notes,
  };
}

class FieldCrop {
  const FieldCrop({
    required this.id,
    required this.fieldId,
    required this.cropId,
    this.sowingDate,
    this.expectedHarvestDate,
    this.status,
    this.notes,
  });

  final String id;
  final String fieldId;
  final String cropId;
  final DateTime? sowingDate;
  final DateTime? expectedHarvestDate;
  final String? status;
  final String? notes;

  factory FieldCrop.fromJson(Map<String, dynamic> json) => FieldCrop(
    id: json['id'] as String,
    fieldId: json['field_id'] as String,
    cropId: json['crop_id'] as String,
    sowingDate: json['sowing_date'] == null
        ? null
        : DateTime.parse(json['sowing_date'] as String),
    expectedHarvestDate: json['expected_harvest_date'] == null
        ? null
        : DateTime.parse(json['expected_harvest_date'] as String),
    status: json['status'] as String?,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'field_id': fieldId,
    'crop_id': cropId,
    'sowing_date': sowingDate?.toIso8601String().substring(0, 10),
    'expected_harvest_date': expectedHarvestDate
        ?.toIso8601String()
        .substring(0, 10),
    'status': status,
    'notes': notes,
  };
}
