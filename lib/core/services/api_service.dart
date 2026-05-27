import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../constants/translations.dart';
import '../models/user.dart';
import '../security/secure_storage_service.dart';

/// API Service for authentication and user operations
class ApiService {
  final Dio _dio;

  // Backend base URL — configure per environment
  static const String baseUrl = AppConfig.baseUrl;

  ApiService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService.getAccessToken() ??
              await SecureStorageService.getGuestToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept-Language'] = AppTranslations.currentLanguage;
          return handler.next(options);
        },
        onError: (error, handler) {
          String message = error.message ?? 'Unknown network error';
          if (error.type == DioExceptionType.connectionError) {
            message =
                'Connection failed. Ensure backend is running and reachable.';
          }
          debugPrint('[API] Error: $message');
          return handler.next(error);
        },
      ),
    );
  }

  Future<AuthResponse> signup({
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
    String? deviceId, // For guest conversion
  }) async {
    try {
      final response = await _dio.post(
        '/api/mobile/auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'password': password,
          'idNumber': idNumber,
          'dateOfBirth': dateOfBirth.toIso8601String(),
          'address': address,
          'postalCode': postalCode,
          'emergencyContactName': emergencyContactName,
          'emergencyContactPhone': emergencyContactPhone,
          'pin': sosPin,
          'age': age ?? 25, // Fallback if missing
          'gender': gender ?? 'prefer_not_to_say',
          'province': province ?? 'Gauteng',
          'community': community ?? 'Johannesburg',
          'faceImageHash': faceImageHash,
          'faceImageUrl': faceImageUrl,
          'verificationToken': verificationToken,
          if (deviceId != null) 'deviceId': deviceId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        await SecureStorageService.saveTokens(
          accessToken: authResponse.jwt,
          refreshToken: '', // Backend doesn't return refresh token yet
        );
        return authResponse;
      } else {
        throw ApiException(
          message: response.data['error'] ?? 'Signup failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data['error'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        await SecureStorageService.saveTokens(
          accessToken: authResponse.jwt,
          refreshToken: '',
        );
        return authResponse;
      } else {
        throw ApiException(
          message: response.data['error'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data['error'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<GuestAuthResponse> loginAsGuest() async {
    try {
      final response = await _dio.post('/api/auth/guest');

      if (response.statusCode == 200) {
        final guestResponse = GuestAuthResponse.fromJson(response.data);
        await SecureStorageService.saveTokens(
          accessToken: guestResponse.sessionToken,
          refreshToken: '',
        );
        return guestResponse;
      } else {
        throw ApiException(
          message: response.data['error'] ?? 'Guest login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Issue guest JWT token with device fingerprint
  /// Called on first app open to get anonymous access
  Future<GuestTokenResponse> issueGuestToken({required String deviceId}) async {
    try {
      final response = await _dio.post(
        '/api/auth/guest',
        options: Options(
          headers: {
            'x-device-id': deviceId,
          },
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final tokenResponse = GuestTokenResponse.fromJson(response.data);
        return tokenResponse;
      } else {
        throw ApiException(
          message: response.data['error'] ?? 'Failed to issue guest token',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data['error'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Send OTP for registration
  Future<void> sendOtp(String phone) async {
    try {
      await _dio.post('/api/mobile/auth/otp/send', data: {'phone': phone});
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data['error'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Verify OTP and get verification token
  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    try {
      final response = await _dio.post(
        '/api/mobile/auth/otp/verify',
        data: {'phone': phone, 'code': code},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data['error'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get pre-signed URL for face scan upload
  Future<Map<String, dynamic>> getFaceUploadUrl(
      String verificationToken) async {
    try {
      final response = await _dio.get(
        '/api/mobile/auth/face-upload-url',
        options: Options(
          headers: {
            'Authorization': 'Bearer $verificationToken',
          },
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data['error'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Upload face scan directly to storage
  Future<void> uploadFace(String uploadUrl, File file) async {
    try {
      final bytes = await file.readAsBytes();
      await Dio().put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': 'image/jpeg',
            'Content-Length': bytes.length,
          },
        ),
      );
    } catch (e) {
      throw ApiException(message: 'Upload failed: $e');
    }
  }

  /// Discover which contacts are registered users
  Future<Map<String, dynamic>> discoverContacts(List<String> hashes) async {
    try {
      final response = await _dio.post(
        '/api/contacts/discover',
        data: {'hashes': hashes},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data['error'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get feed posts
  Future<Map<String, dynamic>> getPosts(
      {int page = 1, int limit = 20, String? type}) async {
    try {
      final response = await _dio.get(
        '/api/posts',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (type != null) 'type': type,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data['error'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Create a new post
  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/posts', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data['error'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Update user profile basic information
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    int? age,
    String? gender,
    String? province,
    String? communityId,
  }) async {
    try {
      final response = await _dio.put(
        '/api/profile',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (age != null) 'age': age,
          if (gender != null) 'gender': gender,
          if (province != null) 'province': province,
          if (communityId != null) 'communityId': communityId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data['error'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Change user SOS PIN
  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    try {
      await _dio.post(
        '/api/profile/change-pin',
        data: {
          'currentPin': currentPin,
          'newPin': newPin,
        },
      );
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data['error'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/users/me');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else {
        throw ApiException(
          message: 'Failed to fetch user',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
      await SecureStorageService.clearTokens();
    } catch (e) {
      debugPrint('[API] Logout error: $e');
      await SecureStorageService.clearTokens();
    }
  }

  Future<void> setPin({required String sosPin}) async {
    try {
      final response =
          await _dio.post('/api/users/pin', data: {'sosPin': sosPin});
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        throw ApiException(
            message: response.data['error'] ?? 'Failed to set PIN',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(
          message: e.response?.data['error'] ?? e.message ?? 'Network error',
          statusCode: e.response?.statusCode);
    }
  }

  Future<AuthResponse> pinLogin({required String sosPin}) async {
    try {
      final response =
          await _dio.post('/api/auth/pin-login', data: {'sosPin': sosPin});
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        await SecureStorageService.saveTokens(
          accessToken: authResponse.jwt,
          refreshToken: '',
        );
        return authResponse;
      } else {
        throw ApiException(
            message: response.data['error'] ?? 'PIN login failed',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(
          message: e.response?.data['error'] ?? e.message ?? 'Network error',
          statusCode: e.response?.statusCode);
    }
  }

  /// Trigger SOS alert on the backend
  Future<Map<String, dynamic>> triggerSos({
    String? id,
    required double lat,
    required double lng,
    required double accuracyM,
    String? cellCid,
    String? cellLac,
  }) async {
    try {
      final response = await _dio.post(
        '/api/mobile/sos/trigger',
        data: {
          if (id != null) 'id': id,
          'lat': lat,
          'lng': lng,
          'accuracyM': accuracyM,
          if (cellCid != null) 'cellCid': cellCid,
          if (cellLac != null) 'cellLac': cellLac,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: response.data['error'] ?? 'Failed to trigger SOS',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data['error'] ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Send GPS heartbeat during active SOS
  Future<void> sendHeartbeat({
    required String sosId,
    required double lat,
    required double lng,
    double? accuracyM,
  }) async {
    try {
      await _dio.post(
        '/api/mobile/sos/heartbeat',
        data: {
          'sosId': sosId,
          'lat': lat,
          'lng': lng,
          if (accuracyM != null) 'accuracyM': accuracyM,
        },
      );
    } catch (e) {
      debugPrint('[API] Heartbeat failed: $e');
    }
  }
}

class AuthResponse {
  final String jwt;
  final String? refreshToken;
  final User user;
  final String communityId;
  final String communityArea;

  AuthResponse({
    required this.jwt,
    this.refreshToken,
    required this.user,
    required this.communityId,
    required this.communityArea,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      jwt: json['jwt'] as String,
      refreshToken: json['refreshToken'] as String?,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      communityId: json['communityId'] as String? ?? '',
      communityArea: json['communityArea'] as String? ?? '',
    );
  }
}

class GuestAuthResponse {
  final String sessionToken;
  final String tempUserId;

  GuestAuthResponse({
    required this.sessionToken,
    required this.tempUserId,
  });

  factory GuestAuthResponse.fromJson(Map<String, dynamic> json) {
    return GuestAuthResponse(
      sessionToken: json['sessionToken'] as String,
      tempUserId: json['tempUserId'] as String,
    );
  }
}

/// Guest token response from POST /api/auth/guest
class GuestTokenResponse {
  final String token;
  final String tier;
  final int expiresIn;
  final String? source;

  GuestTokenResponse({
    required this.token,
    required this.tier,
    required this.expiresIn,
    this.source,
  });

  factory GuestTokenResponse.fromJson(Map<String, dynamic> json) {
    return GuestTokenResponse(
      token: json['token'] as String,
      tier: json['tier'] as String? ?? 'GUEST',
      expiresIn: json['expiresIn'] as int? ?? 3600,
      source: json['source'] as String?,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
