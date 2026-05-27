import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../services/api_service.dart';
import '../security/secure_storage_service.dart';

/// Authentication state enum
enum AuthState {
  none, // No session, no guest token
  guest, // Anonymous guest with JWT
  authenticated, // Registered user with full account
}

/// Guest token model
class GuestToken {
  final String token;
  final String tier;
  final int expiresIn;
  final String? source;

  GuestToken({
    required this.token,
    required this.tier,
    required this.expiresIn,
    this.source,
  });

  factory GuestToken.fromJson(Map<String, dynamic> json) {
    return GuestToken(
      token: json['token'] as String,
      tier: json['tier'] as String? ?? 'GUEST',
      expiresIn: json['expiresIn'] as int? ?? 3600,
      source: json['source'] as String?,
    );
  }

  bool get isExpired {
    // Check if token was issued more than expiresIn seconds ago
    // For now, assume it's valid if we have it (backend handles expiry)
    return false;
  }
}

/// Auth state notifier — manages guest and registered authentication
class AuthStateNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  String? _guestToken;
  String? _guestDeviceId;

  AuthStateNotifier(this._apiService) : super(AuthState.none) {
    _initialize();
  }

  /// Initialize auth state on app startup
  Future<void> _initialize() async {
    try {
      // Check if user is already authenticated
      final accessToken = await SecureStorageService.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        state = AuthState.authenticated;
        return;
      }

      // Check for cached guest token
      final cachedGuestToken = await SecureStorageService.getGuestToken();
      if (cachedGuestToken != null && cachedGuestToken.isNotEmpty) {
        _guestToken = cachedGuestToken;
        state = AuthState.guest;
        return;
      }

      // No session found — will issue guest token on first action
      state = AuthState.none;
    } catch (e) {
      state = AuthState.none;
    }
  }

  /// Get device fingerprint (SHA-256 hash of device ID + model)
  Future<String> _getDeviceFingerprint() async {
    if (_guestDeviceId != null) {
      return _guestDeviceId!;
    }

    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String rawId = '';

      // Get platform-specific device ID
      if (true) {
        // This is simplified; in real app, check target platform
        try {
          final androidInfo = await deviceInfo.androidInfo;
          rawId = androidInfo.id; // device ID
        } catch (_) {
          try {
            final iosInfo = await deviceInfo.iosInfo;
            rawId = iosInfo.identifierForVendor ?? 'unknown';
          } catch (_) {
            rawId = 'unknown-device';
          }
        }
      }

      // Hash the raw ID for privacy (SHA-256)
      final fingerprint = sha256.convert(utf8.encode(rawId)).toString();
      _guestDeviceId = fingerprint;
      return fingerprint;
    } catch (e) {
      // Fallback if device info unavailable
      return sha256.convert(utf8.encode('fallback-device')).toString();
    }
  }

  /// Issue guest token on first app open
  /// Called by splash screen or home screen guard
  Future<void> issueGuestToken() async {
    if (state == AuthState.guest && _guestToken != null) {
      // Already have guest token
      return;
    }

    try {
      final deviceId = await _getDeviceFingerprint();

      // Call backend to issue guest token
      final response = await _apiService.issueGuestToken(deviceId: deviceId);

      // Store guest token
      _guestToken = response.token;
      await SecureStorageService.saveGuestToken(response.token);

      state = AuthState.guest;
    } catch (e) {
      print('[AUTH] Failed to issue guest token: $e');
      // Even if guest token fails, app can continue in limited mode
      state = AuthState.none;
    }
  }

  /// Login with email and password
  /// Returns null on success, error message on failure
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Call backend login endpoint
      final response =
          await _apiService.login(email: email, password: password);

      // Save tokens
      await SecureStorageService.saveTokens(
        accessToken: response.jwt,
        refreshToken: response.refreshToken ?? '',
      );

      state = AuthState.authenticated;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Register new account and convert guest to user
  /// Includes deviceId to link guest SOS history
  Future<String?> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
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
    try {
      // Get device ID for guest conversion
      final deviceId = _guestDeviceId ?? await _getDeviceFingerprint();

      // Call backend signup endpoint
      final response = await _apiService.signup(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
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
        deviceId: deviceId, // Include device ID for guest conversion
      );

      // Save tokens
      await SecureStorageService.saveTokens(
        accessToken: response.jwt,
        refreshToken: response.refreshToken ?? '',
      );

      // Clear guest token
      _guestToken = null;
      await SecureStorageService.clearGuestToken();

      state = AuthState.authenticated;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Get current guest token if authenticated as guest
  String? getGuestToken() {
    if (state == AuthState.guest) {
      return _guestToken;
    }
    return null;
  }

  /// Logout user and clear all tokens
  Future<void> logout() async {
    _guestToken = null;
    await SecureStorageService.clearTokens();
    await SecureStorageService.clearGuestToken();
    state = AuthState.none;
  }
}

/// Provider for auth state notifier
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthStateNotifier(apiService);
});

/// Convenient provider to get guest token
final guestTokenProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState == AuthState.guest) {
    final notifier = ref.read(authStateProvider.notifier);
    return notifier.getGuestToken();
  }
  return null;
});
