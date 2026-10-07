// Location hierarchy models mirroring migration 0001.
// `fromJson` is null-tolerant: PostgREST rows always carry these keys, but
// tests and offline fixtures may omit optional ones.

class StateItem {
  const StateItem({required this.id, required this.name, this.code});

  final String id;
  final String name;
  final String? code;

  factory StateItem.fromJson(Map<String, dynamic> json) => StateItem(
    id: json['id'] as String,
    name: json['name'] as String,
    code: json['code'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code};
}

class District {
  const District({required this.id, required this.stateId, required this.name});

  final String id;
  final String stateId;
  final String name;

  factory District.fromJson(Map<String, dynamic> json) => District(
    id: json['id'] as String,
    stateId: json['state_id'] as String,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'state_id': stateId,
    'name': name,
  };
}

class Block {
  const Block({
    required this.id,
    required this.districtId,
    required this.name,
  });

  final String id;
  final String districtId;
  final String name;

  factory Block.fromJson(Map<String, dynamic> json) => Block(
    id: json['id'] as String,
    districtId: json['district_id'] as String,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'district_id': districtId,
    'name': name,
  };
}

class Panchayat {
  const Panchayat({
    required this.id,
    required this.blockId,
    required this.name,
    this.code,
  });

  final String id;
  final String blockId;
  final String name;
  final String? code;

  factory Panchayat.fromJson(Map<String, dynamic> json) => Panchayat(
    id: json['id'] as String,
    blockId: json['block_id'] as String,
    name: json['name'] as String,
    code: json['code'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'block_id': blockId,
    'name': name,
    'code': code,
  };
}

class Village {
  const Village({
    required this.id,
    required this.panchayatId,
    required this.name,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String panchayatId;
  final String name;
  final double? latitude;
  final double? longitude;

  factory Village.fromJson(Map<String, dynamic> json) => Village(
    id: json['id'] as String,
    panchayatId: json['panchayat_id'] as String,
    name: json['name'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'panchayat_id': panchayatId,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
  };
}
