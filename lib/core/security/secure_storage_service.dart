/*
 * ─────────────────────────────────────────────────────────────
 * FILE: lib/core/security/secure_storage_service.dart
 * PHASE: 7 — Security Foundation
 *
 * PURPOSE:
 *   Single access point for all sensitive key-value data.
 *   Uses flutter_secure_storage (iOS Keychain, Android Keystore).
 *   All authentication tokens, session data, and PIN state go
 *   through this service. Nothing sensitive goes in SharedPrefs.
 *
 * WHAT GOES HERE (sensitive — Keychain/Keystore):
 *   JWT access token, JWT refresh token, device ID, user PIN hash,
 *   encryption key reference, biometric registration flag.
 *
 * WHAT GOES IN SharedPreferences (non-sensitive display state):
 *   app_language, seen_onboarding, seen_language, user_name (display),
 *   user_region (display), has_account flag.
 *
 * HOW TO EXTEND:
 *   Add a typed getter/setter pair for each new secure value.
 *   Never use raw string keys outside this file — use the
 *   constants defined below to prevent typo bugs.
 * ─────────────────────────────────────────────────────────────
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // ── KEY CONSTANTS ────────────────────────────────────────────
  // All storage keys defined here. Never use raw strings elsewhere.

  static const _accessToken   = 'jwt_access_token';
  static const _refreshToken  = 'jwt_refresh_token';
  static const _userId        = 'user_id';
  static const _pinHash       = 'user_pin_bcrypt_hash';
  static const _deviceId      = 'device_unique_id';
  static const _biometricReg  = 'biometric_registered';
  static const _sessionStart  = 'session_started_at';
  static const _twoFaPhone    = 'twofa_phone_number';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── TOKEN MANAGEMENT ─────────────────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessToken, value: accessToken),
      _storage.write(key: _refreshToken, value: refreshToken),
      _storage.write(
        key: _sessionStart,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    ]);
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: _accessToken);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshToken);

  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessToken),
      _storage.delete(key: _refreshToken),
      _storage.delete(key: _sessionStart),
    ]);
  }

  // ── USER IDENTITY ─────────────────────────────────────────

  static Future<void> saveUserId(String id) =>
      _storage.write(key: _userId, value: id);

  static Future<String?> getUserId() =>
      _storage.read(key: _userId);

  // ── PIN MANAGEMENT ───────────────────────────────────────────

  /// Store the bcrypt hash of the user's PIN.
  /// Never store the PIN itself — only ever compare hashes.
  static Future<void> savePinHash(String bcryptHash) =>
      _storage.write(key: _pinHash, value: bcryptHash);

  static Future<String?> getPinHash() =>
      _storage.read(key: _pinHash);

  // ── DEVICE IDENTITY ──────────────────────────────────────────

  static Future<void> saveDeviceId(String id) =>
      _storage.write(key: _deviceId, value: id);

  static Future<String?> getDeviceId() =>
      _storage.read(key: _deviceId);

  // ── BIOMETRIC ────────────────────────────────────────────────

  static Future<void> setBiometricRegistered(bool value) =>
      _storage.write(
        key: _biometricReg,
        value: value.toString(),
      );

  static Future<bool> isBiometricRegistered() async {
    final val = await _storage.read(key: _biometricReg);
    return val == 'true';
  }

  // ── TWO-FACTOR ───────────────────────────────────────────────

  static Future<void> saveTwoFaPhone(String phone) =>
      _storage.write(key: _twoFaPhone, value: phone);

  static Future<String?> getTwoFaPhone() =>
      _storage.read(key: _twoFaPhone);

  // ── FULL WIPE ────────────────────────────────────────────────

  /// Delete all secure storage. Called on sign out and dev reset.
  static Future<void> wipeAll() => _storage.deleteAll();
}
