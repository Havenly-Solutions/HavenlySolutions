class User {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String province;
  final String community;
  final String race;
  final String? idNumber;
  final String? passportNumber;
  final int age;
  final String role;
  final List<String> emergencyContacts;
  final double? lastLat;
  final double? lastLng;
  final String? fcmToken;
  final String? avatarUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.province,
    required this.community,
    required this.race,
    this.idNumber,
    this.passportNumber,
    required this.age,
    required this.role,
    required this.emergencyContacts,
    this.lastLat,
    this.lastLng,
    this.fcmToken,
    this.avatarUrl,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      province: json['province'] as String,
      community: json['community'] as String,
      race: json['race'] as String,
      idNumber: json['idNumber'] as String?,
      passportNumber: json['passportNumber'] as String?,
      age: json['age'] as int,
      role: json['role'] as String,
      emergencyContacts: List<String>.from(json['emergencyContacts'] ?? []),
      lastLat: (json['lastLat'] as num?)?.toDouble(),
      lastLng: (json['lastLng'] as num?)?.toDouble(),
      fcmToken: json['fcmToken'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'province': province,
      'community': community,
      'race': race,
      'idNumber': idNumber,
      'passportNumber': passportNumber,
      'age': age,
      'role': role,
      'emergencyContacts': emergencyContacts,
      'lastLat': lastLat,
      'last_lng': lastLng,
      'fcmToken': fcmToken,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? province,
    String? community,
    String? race,
    String? idNumber,
    String? passportNumber,
    int? age,
    String? role,
    List<String>? emergencyContacts,
    double? lastLat,
    double? lastLng,
    String? fcmToken,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      province: province ?? this.province,
      community: community ?? this.community,
      race: race ?? this.race,
      idNumber: idNumber ?? this.idNumber,
      passportNumber: passportNumber ?? this.passportNumber,
      age: age ?? this.age,
      role: role ?? this.role,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      lastLat: lastLat ?? this.lastLat,
      lastLng: lastLng ?? this.lastLng,
      fcmToken: fcmToken ?? this.fcmToken,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
