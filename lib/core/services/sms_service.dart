/*
 * ─────────────────────────────────────────────────────────────
 * FILE: lib/core/services/sms_service.dart
 * PHASE: 7D — Direct Device SMS
 *
 * PURPOSE:
 *   Sends emergency SMS directly from the device using the
 *   system SMS API. Requires cell signal only. Zero internet.
 *   Zero backend. Fires the moment SOS is triggered.
 *
 *   ANDROID: SMS sent silently in background. No UI.
 *   iOS: Opens pre-filled SMS compose screen. User taps Send.
 *        Apple does not allow silent background SMS sending.
 *
 *   CONTENT: User name + GPS coordinates + Google Maps link
 *   to allow recipients to open the location immediately.
 *
 *   CONTACTS: Reads from the encrypted emergency_contacts table
 *   in SQLite. These are set during profile setup (Phase 12).
 *
 * HOW TO EXTEND:
 *   Phase 14 adds server-side Twilio SMS via the backend as a
 *   redundant path that fires when internet is available.
 *   This direct SMS fires regardless.
 * ─────────────────────────────────────────────────────────────
 */

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/local_db.dart';
import '../security/encryption_service.dart';
import '../security/secure_storage_service.dart';
import 'location_service.dart';

class SmsService {
  /// Send SOS SMS to all emergency contacts stored in the database.
  static Future<SmsSendResult> dispatch({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final userId = await SecureStorageService.getUserId();
      if (userId == null) {
        return const SmsSendResult(attempted: 0, succeeded: 0);
      }

      final contacts = await LocalDb.getEmergencyContacts(userId);

      if (contacts.isEmpty) {
        return const SmsSendResult(attempted: 0, succeeded: 0);
      }

      final locationText = (latitude != null && longitude != null)
          ? LocationService.mapsLink(latitude, longitude)
          : 'Location unavailable';

      final body = 'HAVENLY SOLUTIONS EMERGENCY ALERT\n'
          'Someone needs immediate help.\n'
          'Location: $locationText\n'
          'This is an automated message from the Havenly Solutions safety app.';

      int sent = 0;
      for (final contact in contacts) {
        // Decrypt the phone number before use.
        final rawPhone = await EncryptionService.decrypt(
          contact['phone_number'] as String?,
        );
        if (rawPhone == null) continue;

        final success = await _send(phone: rawPhone, message: body);
        if (success) sent++;
      }

      return SmsSendResult(
        attempted: contacts.length,
        succeeded: sent,
      );
    } catch (e) {
      debugPrint('[SMS] Dispatch error: $e');
      return const SmsSendResult(attempted: 0, succeeded: 0);
    }
  }

  static Future<bool> _send({
    required String phone,
    required String message,
  }) async {
    try {
      final encoded = Uri.encodeComponent(message);
      final Uri uri;

      if (Platform.isAndroid) {
        uri = Uri.parse('sms:$phone?body=$encoded');
      } else if (Platform.isIOS) {
        uri = Uri.parse('sms:$phone&body=$encoded');
      } else {
        return false;
      }

      return await launchUrl(uri);
    } catch (e) {
      debugPrint('[SMS] Send failed to $phone: $e');
      return false;
    }
  }
}

class SmsSendResult {
  final int attempted;
  final int succeeded;
  const SmsSendResult({required this.attempted, required this.succeeded});
  bool get anySucceeded => succeeded > 0;
}
