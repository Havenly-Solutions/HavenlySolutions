class User {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String province;
  final String community;

  String get firstName => fullName.trim().split(' ').first;
  String get surname {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.last : fullName;
  }

  String get welcomeDisplayName {
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final surnamePart = surname.isNotEmpty ? surname : '';
    final titlePart = title?.trim().isNotEmpty == true ? '$title ' : '';
    if (titlePart.isEmpty && initial.isEmpty && surnamePart.isEmpty) {
      return 'Welcome back';
    }
    if (surnamePart.isEmpty) {
      return 'Welcome back $titlePart$initial'.trim();
    }
    return 'Welcome back $titlePart${initial.isNotEmpty ? '$initial ' : ''}$surnamePart'
        .trim();
  }

  final String race;
  final String? idNumber;
  final String? passportNumber;
  final int age;
  final String role;
  final String? title;
  final String? gender;
  final List<String> emergencyContacts;
  final double? lastLat;
  final double? lastLng;
  final String? fcmToken;
  final String? avatarUrl;
  final String? profileImagePath;
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
    this.title,
    this.gender,
    required this.emergencyContacts,
    this.lastLat,
    this.lastLng,
    this.fcmToken,
    this.avatarUrl,
    this.profileImagePath,
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
      title: json['title'] as String?,
      gender: json['gender'] as String?,
      emergencyContacts: List<String>.from(json['emergencyContacts'] ?? []),
      lastLat: (json['lastLat'] as num?)?.toDouble(),
      lastLng: (json['lastLng'] as num?)?.toDouble(),
      fcmToken: json['fcmToken'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      profileImagePath: json['profileImagePath'] as String?,
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
      'title': title,
      'gender': gender,
      'emergencyContacts': emergencyContacts,
      'lastLat': lastLat,
      'last_lng': lastLng,
      'fcmToken': fcmToken,
      'avatarUrl': avatarUrl,
      'profileImagePath': profileImagePath,
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
    String? title,
    String? gender,
    List<String>? emergencyContacts,
    double? lastLat,
    double? lastLng,
    String? fcmToken,
    String? avatarUrl,
    String? profileImagePath,
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
      title: title ?? this.title,
      gender: gender ?? this.gender,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      lastLat: lastLat ?? this.lastLat,
      lastLng: lastLng ?? this.lastLng,
      fcmToken: fcmToken ?? this.fcmToken,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
