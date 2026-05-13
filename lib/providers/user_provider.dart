import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../core/security/secure_storage_service.dart';
import '../models/api_exception.dart';
import '../config/app_config.dart';
import '../core/database/local_db.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/push_notification_service.dart';

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
      final userId = await SecureStorageService.getUserId();
      if (userId == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Offline First: Check local DB first
      final localUser = await LocalDb.getUser(userId);
      if (localUser != null) {
        _currentUser = _mapLocalToModel(localUser);
      }

      // Then attempt to sync with backend if online
      if (!AppConfig.kUseMockData) {
        try {
          final userData = await _apiService.get('/api/auth/me');
          // backend returns { success: true, data: userObject }
          if (userData['data'] != null) {
            _currentUser =
                User.fromJson(userData['data'] as Map<String, dynamic>);
          }
          final accessToken = await SecureStorageService.getAccessToken();
          if (accessToken != null) {
            await SocketService.instance.connect(accessToken);
          }
          await syncFcmToken();
          if (_currentUser != null) {
            PushNotificationService.subscribeToLocalizedTopics(
              province: _currentUser!.province,
              communityId: _currentUser!.community,
            );
          }
        } catch (_) {
          // If network fails but we have a local user, that's fine.
          // Do NOT logout here if it's a transient error.
          if (_currentUser == null) rethrow;
        }
      }
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

  Future<String?> _ensureFcmToken() async {
    final token = await PushNotificationService.getToken();
    if (token == null) return null;
    await SecureStorageService.saveFcmToken(token);
    return token;
  }

  Future<void> syncFcmToken() async {
    if (!isAuthenticated) return;
    final token = await _ensureFcmToken();
    if (token == null) return;

    try {
      await _apiService.post('/api/auth/fcm-token', data: {
        'fcmToken': token,
        'deviceId': await SecureStorageService.getOrCreateDeviceId(),
      });
    } catch (e) {
      debugPrint('[UserProvider] syncFcmToken failed: $e');
    }
  }

  Future<bool> login(
      String identifier, String hashedPin, String deviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (AppConfig.kUseMockData) {
        // Offline login logic
        final localUser = await LocalDb.getUserByPhone(identifier);
        if (localUser != null && localUser['pin_hash'] == hashedPin) {
          _currentUser = _mapLocalToModel(localUser);
          await SecureStorageService.saveUserId(_currentUser!.id);
          _isLoading = false;
          notifyListeners();
          return true;
        }
        throw Exception('Invalid PIN or Phone Number');
      }

      final prefs = await SharedPreferences.getInstance();
      final preferredLanguage = prefs.getString('app_language') ?? 'en';
      final fcmToken = await _ensureFcmToken();

      final response = await _apiService.post('/api/auth/login', data: {
        'identifier': identifier,
        'pinHash': hashedPin,
        'deviceId': deviceId,
        if (fcmToken != null) 'fcmToken': fcmToken,
        'preferredLanguage': preferredLanguage,
      });

      // backend returns { success: true, data: { access_token, refresh_token, user } }
      final data = response['data'];
      await SecureStorageService.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );
      await SecureStorageService.saveUserId(data['user']['id']);

      _currentUser = User.fromJson(data['user']);
      PushNotificationService.subscribeToLocalizedTopics(
        province: _currentUser!.province,
        communityId: _currentUser!.community,
      );
      final accessToken = data['access_token'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          await SocketService.instance.connect(accessToken);
        } catch (e) {
          debugPrint('[UserProvider] Socket connection failed: $e');
        }
      }

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
      if (!AppConfig.kUseMockData) {
        final refreshToken = await SecureStorageService.getRefreshToken();
        await _apiService.post('/api/auth/logout', data: {
          if (refreshToken != null) 'refresh_token': refreshToken,
        });
      }
    } catch (_) {}
    await SocketService.instance.disconnect();
    await SecureStorageService.clearAll();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> register(Map<String, dynamic> registrationData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. ALWAYS save to local database first (Offline Survivability)
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final localUserMap = {
        'id': userId,
        'phone_number': registrationData['phoneNumber'],
        'full_name': registrationData['fullName'],
        'title': registrationData['title'],
        'gender': registrationData['gender'],
        'age': registrationData['age'],
        'race': registrationData['race'],
        'province': registrationData['province'],
        'community_name': registrationData['community'],
        'id_number': registrationData['idNumber'],
        'pin_hash': registrationData['pinHash'],
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'synced': 0,
      };

      await LocalDb.insertUser(localUserMap);
      await SecureStorageService.saveUserId(userId);
      _currentUser = _mapLocalToModel(localUserMap);

      // 2. Attempt backend sync if not in pure mock mode
      if (!AppConfig.kUseMockData) {
        try {
          final response = await _apiService.post('/api/auth/register',
              data: registrationData);
          final data = response['data'];
          await SecureStorageService.saveTokens(
            accessToken: data['access_token'],
            refreshToken: data['refresh_token'],
          );
          await SecureStorageService.saveUserId(data['user']['id']);
          _currentUser = User.fromJson(data['user'] as Map<String, dynamic>);
          PushNotificationService.subscribeToLocalizedTopics(
            province: _currentUser!.province,
            communityId: _currentUser!.community,
          );
          await LocalDb.updateUser(userId, {'synced': 1});
        } catch (e) {
          // If network error, we stay registered LOCALLY.
          // The sync will happen later via OfflineQueue.
          debugPrint(
              '[UserProvider] Registration sync failed, staying offline: $e');
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  User _mapLocalToModel(Map<String, dynamic> m) {
    return User(
      id: m['id'],
      fullName: m['full_name'],
      phoneNumber: m['phone_number'],
      email: m['email'],
      province: m['province'] ?? '',
      community: m['community_name'] ?? '',
      race: m['race'] ?? '',
      idNumber: m['id_number'],
      age: m['age'] ?? 0,
      role: m['tier'] ?? 'USER',
      title: m['title'] as String?,
      gender: m['gender'] as String?,
      emergencyContacts: [],
      profileImagePath: m['profile_image_path'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']),
    );
  }
}
