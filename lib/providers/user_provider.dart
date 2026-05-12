import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../core/security/secure_storage_service.dart';
import '../models/api_exception.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final ApiService _apiService = ApiService();

  Future<void> bootSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await SecureStorageService.getAccessToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userData = await _apiService.get('/auth/me');
      _currentUser = User.fromJson(userData);
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await logout();
      } else {
        _errorMessage = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String identifier, String hashedPin, String deviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/login', data: {
        'identifier': identifier,
        'pinHash': hashedPin,
        'deviceId': deviceId,
      });

      await SecureStorageService.saveTokens(
        accessToken: response['access_token'],
        refreshToken: response['refresh_token'],
      );
      await SecureStorageService.saveUserId(response['user']['id']);
      // Assuming SecureStorageService will be extended to handle user_role
      // await SecureStorageService.saveUserRole(response['user']['role']);

      _currentUser = User.fromJson(response['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout');
    } catch (_) {
      // Ignore logout errors
    } finally {
      await SecureStorageService.clearTokens();
      // await SecureStorageService.clearUserId();
      // await SecureStorageService.clearUserRole();
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<bool> register(Map<String, dynamic> registrationData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/register', data: registrationData);

      await SecureStorageService.saveTokens(
        accessToken: response['access_token'],
        refreshToken: response['refresh_token'],
      );
      await SecureStorageService.saveUserId(response['user']['id']);

      _currentUser = User.fromJson(response['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
