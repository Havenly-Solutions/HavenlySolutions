/*
 * ─────────────────────────────────────────────────────────────
 * FILE: lib/core/security/encryption_service.dart
 * PHASE: 7 — Security Foundation
 *
 * PURPOSE:
 *   AES-256-GCM encryption and decryption for all sensitive
 *   user data before it touches any storage layer (SQLite or
 *   network). Fields encrypted: ID number, passport number,
 *   emergency contact phone numbers, medical conditions.
 *
 * HOW IT WORKS:
 *   AES-256-GCM is authenticated encryption. It encrypts the
 *   data AND produces a message authentication code (MAC) that
 *   detects tampering. If anyone modifies the ciphertext the
 *   decryption will fail with an authentication error.
 *
 *   The encryption key is stored in flutter_secure_storage
 *   (iOS Keychain / Android Keystore) and is unique per device.
 *   This means encrypted data from one device cannot be decrypted
 *   on another device without the key — protecting against device
 *   theft scenarios.
 *
 * IMPORTANT SECURITY NOTES:
 *   - Never log the key or any plaintext of encrypted fields.
 *   - Never store the key in SharedPreferences or SQLite.
 *   - Never commit a hardcoded key to version control.
 *   - The key is generated once on first install and rotated
 *     when the user changes their PIN (Phase 21).
 *
 * HOW TO EXTEND:
 *   To encrypt a new field: call EncryptionService.encrypt(value)
 *   before inserting to database. Call decrypt(value) after reading.
 *   Add the field name to the ENCRYPTED_FIELDS constant below so
 *   any developer reading the code knows which fields are protected.
 * ─────────────────────────────────────────────────────────────
 */

import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class EncryptionService {
  // ── CONSTANTS ───────────────────────────────────────────────

  /// Fields in the database that are AES-256-GCM encrypted.
  /// This list is documentation — add any new encrypted field here.
  static const encryptedFields = [
    'id_number',
    'passport_number',
    'contact_phone_numbers',
    'medical_conditions', // Phase 2
  ];

  static const _keyStorageKey = 'havenly_data_encryption_key';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static final _algorithm = AesGcm.with256bits();

  // ── KEY MANAGEMENT ───────────────────────────────────────────

  /// Get or generate the device encryption key.
  /// Key is generated once on first install and stored in Keychain/Keystore.
  /// Never exposed outside this class.
  static Future<SecretKey> _getOrCreateKey() async {
    final stored = await _storage.read(key: _keyStorageKey);

    if (stored != null) {
      final bytes = base64Decode(stored);
      return SecretKey(bytes);
    }

    // Generate a cryptographically secure 256-bit key.
    final key = await _algorithm.newSecretKey();
    final bytes = await key.extractBytes();
    await _storage.write(
      key: _keyStorageKey,
      value: base64Encode(bytes),
    );
    return key;
  }

  // ── PUBLIC API ───────────────────────────────────────────────

  /// Encrypt a plain text string. Returns a base64-encoded string
  /// containing the nonce + ciphertext + MAC concatenated.
  /// Store this result in the database instead of the plain value.
  static Future<String> encrypt(String plainText) async {
    try {
      final key = await _getOrCreateKey();
      final nonce = _algorithm.newNonce();
      final secretBox = await _algorithm.encrypt(
        utf8.encode(plainText),
        secretKey: key,
        nonce: nonce,
      );
      // Concatenate nonce + ciphertext + mac for single-field storage.
      final combined = Uint8List.fromList([
        ...secretBox.nonce,
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ]);
      return base64Encode(combined);
    } catch (e) {
      // Fail closed — if encryption fails do not store plaintext.
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// Decrypt a base64-encoded encrypted string produced by encrypt().
  /// Returns null if the value is null (field was not set).
  /// Throws EncryptionException if the data has been tampered with.
  static Future<String?> decrypt(String? encryptedBase64) async {
    if (encryptedBase64 == null || encryptedBase64.isEmpty) return null;
    try {
      final key = await _getOrCreateKey();
      final combined = base64Decode(encryptedBase64);

      // AES-GCM nonce is 12 bytes. MAC is 16 bytes.
      // Layout: [12 nonce][N ciphertext][16 mac]
      const nonceLength = 12;
      const macLength = 16;

      final nonce = combined.sublist(0, nonceLength);
      final mac = Mac(combined.sublist(combined.length - macLength));
      final cipherText = combined.sublist(
        nonceLength,
        combined.length - macLength,
      );

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: mac,
      );

      final plainBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: key,
      );

      return utf8.decode(plainBytes);
    } catch (e) {
      throw EncryptionException('Decryption failed — data may be tampered: $e');
    }
  }
}

class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
