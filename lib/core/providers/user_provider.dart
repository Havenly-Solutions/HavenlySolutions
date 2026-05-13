import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../security/secure_storage_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier(ref.watch(apiServiceProvider));
});

class UserNotifier extends StateNotifier<User?> {
  final ApiService _apiService;

  UserNotifier(this._apiService) : super(null) {
    _init();
  }

  Future<void> _init() async {
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
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String idNumber,
    required DateTime dateOfBirth,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String sosPin,
  }) async {
    final response = await _apiService.signup(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      idNumber: idNumber,
      dateOfBirth: dateOfBirth,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      sosPin: sosPin,
    );
    state = response.user;
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
