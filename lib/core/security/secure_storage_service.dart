import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SecureStorageService {
  // ── KEY CONSTANTS ────────────────────────────────────────────
  // All storage keys defined here. Never use raw strings elsewhere.

  static const kAccessToken = 'access_token';
  static const kRefreshToken = 'refresh_token';
  static const kUserId = 'user_id';
  static const kUserRole = 'user_role';
  static const kPinHash = 'pin_hash';
  static const kDeviceId = 'device_id';
  static const kFcmToken = 'fcm_token';

  // Legacy/Internal keys (preserved for internal usage if needed)
  static const _biometricReg = 'biometric_registered';
  static const _sessionStart = 'session_started_at';
  static const _twoFaPhone = 'twofa_phone_number';

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
      _storage.write(key: kAccessToken, value: accessToken),
      _storage.write(key: kRefreshToken, value: refreshToken),
      _storage.write(
        key: _sessionStart,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    ]);
  }

  static Future<String?> getAccessToken() => _storage.read(key: kAccessToken);

  static Future<String?> getRefreshToken() => _storage.read(key: kRefreshToken);

  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: kAccessToken),
      _storage.delete(key: kRefreshToken),
      _storage.delete(key: _sessionStart),
    ]);
  }

  // ── USER IDENTITY ─────────────────────────────────────────

  static Future<void> saveUserId(String id) =>
      _storage.write(key: kUserId, value: id);

  static Future<String?> getUserId() => _storage.read(key: kUserId);

  static Future<void> saveUserRole(String role) =>
      _storage.write(key: kUserRole, value: role);

  static Future<String?> getUserRole() => _storage.read(key: kUserRole);

  // ── PIN MANAGEMENT ───────────────────────────────────────────

  /// Store the bcrypt hash of the user's PIN.
  /// Never store the PIN itself — only ever compare hashes.
  static Future<void> savePinHash(String bcryptHash) =>
      _storage.write(key: kPinHash, value: bcryptHash);

  static Future<String?> getPinHash() => _storage.read(key: kPinHash);

  // ── DEVICE IDENTITY ──────────────────────────────────────────

  static Future<void> saveDeviceId(String id) =>
      _storage.write(key: kDeviceId, value: id);

  static Future<String?> getDeviceId() => _storage.read(key: kDeviceId);

  static Future<String> getOrCreateDeviceId() async {
    String? id = await getDeviceId();
    if (id == null) {
      id = const Uuid().v4();
      await saveDeviceId(id);
    }
    return id;
  }

  // ── FCM TOKEN ────────────────────────────────────────────────

  static Future<void> saveFcmToken(String token) =>
      _storage.write(key: kFcmToken, value: token);

  static Future<String?> getFcmToken() => _storage.read(key: kFcmToken);

  // ── BIOMETRIC ────────────────────────────────────────────────

  static Future<void> setBiometricRegistered(bool value) => _storage.write(
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

  static Future<String?> getTwoFaPhone() => _storage.read(key: _twoFaPhone);

  // ── FULL WIPE ────────────────────────────────────────────────

  /// Delete all secure storage. Called on sign out and dev reset.
  static Future<void> clearAll() => _storage.deleteAll();

  @Deprecated('Use clearAll instead')
  static Future<void> wipeAll() => clearAll();
}
