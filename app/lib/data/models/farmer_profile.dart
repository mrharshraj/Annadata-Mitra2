// Farmer profile: id IS the Supabase Auth user id.

class FarmerProfile {
  const FarmerProfile({
    required this.id,
    this.villageId,
    required this.name,
    this.phone,
    this.preferredLanguage = 'hi',
  });

  final String id;
  final String? villageId;
  final String name;
  final String? phone;
  final String preferredLanguage;

  factory FarmerProfile.fromJson(Map<String, dynamic> json) => FarmerProfile(
    id: json['id'] as String,
    villageId: json['village_id'] as String?,
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String?,
    preferredLanguage: json['preferred_language'] as String? ?? 'hi',
  );

  /// Insert/update payload (never includes timestamps).
  Map<String, dynamic> toJson() => {
    'id': id,
    'village_id': villageId,
    'name': name,
    'phone': phone,
    'preferred_language': preferredLanguage,
  };

  FarmerProfile copyWith({
    String? villageId,
    String? name,
    String? phone,
    String? preferredLanguage,
  }) => FarmerProfile(
    id: id,
    villageId: villageId ?? this.villageId,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
  );
}
