import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../security/secure_storage_service.dart';


final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier(ref.watch(apiServiceProvider));
});

class UserNotifier extends StateNotifier<User?> {
  final ApiService _apiService;

  UserNotifier(this._apiService) : super(null) {
    _init();
  }

  Future<void> _init() async {
    await fetchCurrentUser();
  }

  Future<void> fetchCurrentUser() async {
    final token = await SecureStorageService.getAccessToken();
    if (token != null) {
      try {
        final user = await _apiService.getCurrentUser();
        state = user;
      } catch (e) {
        await SecureStorageService.clearTokens();
        state = null;
      }
    }
  }

  Future<void> login(String email, String password) async {
    final response = await _apiService.login(email: email, password: password);
    state = response.user;
    await SecureStorageService.saveUserId(response.user.id);
  }

  Future<void> loginWithToken(String accessToken) async {
    await SecureStorageService.saveTokens(
      accessToken: accessToken,
      refreshToken: '',
    );
    final user = await _apiService.getCurrentUser();
    state = user;
    await SecureStorageService.saveUserId(user.id);
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String idNumber,
    required DateTime dateOfBirth,
    required String address,
    required String postalCode,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String sosPin,
    int? age,
    String? gender,
    String? province,
    String? community,
    String? faceImageHash,
    String? faceImageUrl,
    String? verificationToken,
  }) async {
    final response = await _apiService.signup(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      idNumber: idNumber,
      dateOfBirth: dateOfBirth,
      address: address,
      postalCode: postalCode,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      sosPin: sosPin,
      age: age,
      gender: gender,
      province: province,
      community: community,
      faceImageHash: faceImageHash,
      faceImageUrl: faceImageUrl,
      verificationToken: verificationToken,
    );
    state = response.user;
    await SecureStorageService.saveUserId(response.user.id);
    await SecureStorageService.savePinHash(
        BCrypt.hashpw(sosPin, BCrypt.gensalt(logRounds: 10)));
    await SecureStorageService.setPinSet(true);
  }

  Future<void> loginAsGuest() async {
    await _apiService.loginAsGuest();
    // Guest user might not have a full profile yet, so state might remain null or a dummy user
    // For now, let's just assume guest state is handled differently or we fetch a temp user
  }

  Future<void> logout() async {
    await _apiService.logout();
    state = null;
  }

  Future<void> pinLogin(String pin) async {
    final response = await _apiService.pinLogin(sosPin: pin);
    state = response.user;
  }
}
