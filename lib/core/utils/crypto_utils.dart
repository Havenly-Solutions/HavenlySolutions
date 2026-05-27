import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class CryptoUtils {
  CryptoUtils._();

  static String sha256Hex(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  static String hashPhone(String phone) {
    // Normalize phone number (remove all non-digits, keep leading + if present)
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return sha256Hex(normalized);
  }

  // AES-256-GCM encrypt — returns base64(nonce + ciphertext + tag)
  static String encrypt(String plaintext, List<int> keyBytes) {
    final key = Key(Uint8List.fromList(keyBytes));
    final iv = IV.fromSecureRandom(12); // 96-bit nonce for GCM
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    // Prepend nonce to ciphertext for storage — nonce is non-secret
    final combined = [...iv.bytes, ...encrypted.bytes];
    return base64Encode(combined);
  }

  static String decrypt(String ciphertext, List<int> keyBytes) {
    final combined = base64Decode(ciphertext);
    final iv = IV(Uint8List.fromList(combined.sublist(0, 12)));
    final ciphertextOnly = combined.sublist(12);
    final key = Key(Uint8List.fromList(keyBytes));
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    return encrypter.decrypt(Encrypted(Uint8List.fromList(ciphertextOnly)), iv: iv);
  }
}
