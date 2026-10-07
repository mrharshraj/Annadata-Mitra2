// Farmer profile: id IS the Supabase Auth user id (public.profiles).

class Profile {
  const Profile({
    required this.id,
    this.fullName,
    this.phone,
    this.preferredLanguage = 'hi',
    this.stateId,
    this.districtId,
    this.blockId,
    this.panchayatId,
    this.villageId,
    this.avatarUrl,
  });

  final String id;
  final String? fullName;
  final String? phone;
  final String preferredLanguage;
  final String? stateId;
  final String? districtId;
  final String? blockId;
  final String? panchayatId;
  final String? villageId;
  final String? avatarUrl;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    fullName: json['full_name'] as String?,
    phone: json['phone'] as String?,
    preferredLanguage: json['preferred_language'] as String? ?? 'hi',
    stateId: json['state_id'] as String?,
    districtId: json['district_id'] as String?,
    blockId: json['block_id'] as String?,
    panchayatId: json['panchayat_id'] as String?,
    villageId: json['village_id'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );

  /// Insert/update payload (never includes timestamps).
  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'preferred_language': preferredLanguage,
    'state_id': stateId,
    'district_id': districtId,
    'block_id': blockId,
    'panchayat_id': panchayatId,
    'village_id': villageId,
    'avatar_url': avatarUrl,
  };

  Profile copyWith({
    String? fullName,
    String? phone,
    String? preferredLanguage,
    String? stateId,
    String? districtId,
    String? blockId,
    String? panchayatId,
    String? villageId,
  }) => Profile(
    id: id,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    stateId: stateId ?? this.stateId,
    districtId: districtId ?? this.districtId,
    blockId: blockId ?? this.blockId,
    panchayatId: panchayatId ?? this.panchayatId,
    villageId: villageId ?? this.villageId,
    avatarUrl: avatarUrl,
  );
}
