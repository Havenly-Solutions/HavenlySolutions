import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../security/secure_storage_service.dart';

/// API Service for authentication and user operations
class ApiService {
  final Dio _dio;

  // Backend base URL — configure per environment
  static const String baseUrl = 'http://localhost:5000'; // Dev

  ApiService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('[API] Error: ${error.message}');
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
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String sosPin,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/signup',
        data: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'password': password,
          'idNumber': idNumber,
          'dateOfBirth': dateOfBirth.toIso8601String(),
          'emergencyContactName': emergencyContactName,
          'emergencyContactPhone': emergencyContactPhone,
          'sosPin': sosPin,
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
      final response = await _dio.post('/api/users/pin', data: {'sosPin': sosPin});
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
      final response = await _dio.post('/api/auth/pin-login', data: {'sosPin': sosPin});
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
}

class AuthResponse {
  final String jwt;
  final User user;
  final String communityId;
  final String communityArea;

  AuthResponse({
    required this.jwt,
    required this.user,
    required this.communityId,
    required this.communityArea,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      jwt: json['jwt'] as String,
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

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
