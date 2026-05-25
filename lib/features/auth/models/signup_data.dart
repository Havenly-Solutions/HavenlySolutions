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
  final String community;

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
    required this.community,
  });

  String get fullName => '$title ${firstName.trim()} ${surname.trim()}'.trim();

  String get formattedPhone {
    final trimmed = phoneNumber.trim();
    if (trimmed.startsWith('+')) return trimmed;
    return '+27 $trimmed'.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
