/// User model for Havenly Solutions
class User {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? profilePhotoUrl;
  final int? age;
  final String? gender;
  final String? province;
  final String? status;
  final String communityId;
  final String communityArea;
  final SubscriptionTier tier;
  final bool pinSet;
  final List<EmergencyContact> emergencyContacts;
  final bool shareLocationWithCommunity;
  final bool showPhoneOnProfile;
  final bool allowContactSearch;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profilePhotoUrl,
    this.age,
    this.gender,
    this.province,
    this.status,
    required this.communityId,
    required this.communityArea,
    this.tier = SubscriptionTier.free,
    this.pinSet = false,
    this.emergencyContacts = const [],
    this.shareLocationWithCommunity = true,
    this.showPhoneOnProfile = false,
    this.allowContactSearch = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      province: json['province'] as String?,
      status: json['status'] as String?,
      communityId: json['communityId'] as String? ?? '',
      communityArea: json['communityArea'] as String,
      tier: SubscriptionTier.values.byName(json['tier'] as String? ?? 'free'),
      pinSet: json['pinSet'] as bool? ?? false,
      emergencyContacts: (json['emergencyContacts'] as List?)
              ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      shareLocationWithCommunity: json['shareLocationWithCommunity'] as bool? ?? true,
      showPhoneOnProfile: json['showPhoneOnProfile'] as bool? ?? false,
      allowContactSearch: json['allowContactSearch'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'profilePhotoUrl': profilePhotoUrl,
      'age': age,
      'gender': gender,
      'province': province,
      'status': status,
      'communityId': communityId,
      'communityArea': communityArea,
      'tier': tier.name,
      'pinSet': pinSet,
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
      'shareLocationWithCommunity': shareLocationWithCommunity,
      'showPhoneOnProfile': showPhoneOnProfile,
      'allowContactSearch': allowContactSearch,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? profilePhotoUrl,
    int? age,
    String? gender,
    String? province,
    String? status,
    String? communityId,
    String? communityArea,
    SubscriptionTier? tier,
    bool? pinSet,
    List<EmergencyContact>? emergencyContacts,
    bool? shareLocationWithCommunity,
    bool? showPhoneOnProfile,
    bool? allowContactSearch,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      province: province ?? this.province,
      status: status ?? this.status,
      communityId: communityId ?? this.communityId,
      communityArea: communityArea ?? this.communityArea,
      tier: tier ?? this.tier,
      pinSet: pinSet ?? this.pinSet,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      shareLocationWithCommunity: shareLocationWithCommunity ?? this.shareLocationWithCommunity,
      showPhoneOnProfile: showPhoneOnProfile ?? this.showPhoneOnProfile,
      allowContactSearch: allowContactSearch ?? this.allowContactSearch,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Emergency contact for SOS dispatch
class EmergencyContact {
  final String name;
  final String surname;
  final String phone;
  final int order; // For reordering contacts

  EmergencyContact({
    required this.name,
    required this.surname,
    required this.phone,
    required this.order,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String,
      surname: json['surname'] as String,
      phone: json['phone'] as String,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'surname': surname,
      'phone': phone,
      'order': order,
    };
  }
}

/// Subscription tier levels
enum SubscriptionTier {
  free,   // Community green
  pro,    // Brand deep
  ngo,    // Authority gold
}
