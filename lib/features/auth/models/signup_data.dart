class SignupData {
  final String title;
  final String firstName;
  final String surname;
  final String gender;
  final String race;
  final DateTime dateOfBirth;
  final String idNumber;
  final String phoneNumber;
  final String email;
  final String address;
  final String postalCode;
  final String province;
  final String community;
  final String? faceImageHash;
  final String? faceImageUrl;
  final String? verificationToken;

  SignupData({
    required this.title,
    required this.firstName,
    required this.surname,
    required this.gender,
    required this.race,
    required this.dateOfBirth,
    required this.idNumber,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.postalCode,
    required this.province,
    required this.community,
    this.faceImageHash,
    this.faceImageUrl,
    this.verificationToken,
  });

  SignupData copyWith({
    String? title,
    String? firstName,
    String? surname,
    String? gender,
    String? race,
    DateTime? dateOfBirth,
    String? idNumber,
    String? phoneNumber,
    String? email,
    String? address,
    String? postalCode,
    String? province,
    String? community,
    String? faceImageHash,
    String? faceImageUrl,
    String? verificationToken,
  }) {
    return SignupData(
      title: title ?? this.title,
      firstName: firstName ?? this.firstName,
      surname: surname ?? this.surname,
      gender: gender ?? this.gender,
      race: race ?? this.race,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      idNumber: idNumber ?? this.idNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      postalCode: postalCode ?? this.postalCode,
      province: province ?? this.province,
      community: community ?? this.community,
      faceImageHash: faceImageHash ?? this.faceImageHash,
      faceImageUrl: faceImageUrl ?? this.faceImageUrl,
      verificationToken: verificationToken ?? this.verificationToken,
    );
  }

  String get fullName => '$title ${firstName.trim()} ${surname.trim()}'.trim();

  String get formattedPhone {
    final trimmed = phoneNumber.trim();
    if (trimmed.startsWith('+')) return trimmed;
    return '+27 $trimmed'.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
