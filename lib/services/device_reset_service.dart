/**
 * FILE: lib/services/device_reset_service.dart
 * PURPOSE: Wipes all local device data for this app
 * Used for: account deletion, deactivation, dev testing reset
 *
 * Clears: SQLite DB, SecureStorage, SharedPreferences,
 *         image cache, offline queue, all local files
 * Does NOT affect: backend data (handled separately)
 */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../core/database/local_db.dart';

class DeviceResetService {
  static Future<void> wipeAllLocalData() async {
    try {
      // 1. Clear SecureStorage (JWTs, PIN hash, device ID)
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();
      debugPrint('[Reset] SecureStorage cleared');

      // 2. Clear SharedPreferences (language, preferences, flags)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('[Reset] SharedPreferences cleared');

      // 3. Drop and recreate all SQLite tables
      await LocalDb().wipeDatabase();
      debugPrint('[Reset] SQLite database wiped');

      // 4. Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      debugPrint('[Reset] Image cache cleared');

      // 5. Delete local files (profile photos, evidence, downloads)
      final appDir = await getApplicationDocumentsDirectory();
      if (appDir.existsSync()) {
        appDir.listSync().forEach((entity) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        });
      }

      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.listSync().forEach((entity) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        });
      }
      debugPrint('[Reset] Local files cleared');

      debugPrint('[Reset] Full device wipe complete');
    } catch (e) {
      debugPrint('[Reset] Wipe error: $e');
      rethrow;
    }
  }
}
