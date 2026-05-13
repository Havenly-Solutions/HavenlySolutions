/*
 * ─────────────────────────────────────────────────────────────
 * FILE: mobile/lib/core/services/push_notification_service.dart
 * PHASE: 17 — Topic-Based Targeting
 *
 * PURPOSE:
 *   Handles FCM push messages in all app states and manages
 *   localized topic subscriptions (Province/Community).
 * ─────────────────────────────────────────────────────────────
 */

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'alarm_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final type = message.data['type'];
  if (type == 'sos_amber_alert') {
    await AlarmService.instance.playAlarm();
    debugPrint('[Push] Background SOS alarm triggered');
  }
}

class PushNotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static Map<String, String>? _pendingAlertData;
  static Map<String, String>? get pendingAlertData => _pendingAlertData;
  static void Function(Map<String, String> data)? onAlertReceived;

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    // Nationwide fallback topic
    _messaging.subscribeToTopic('sos_alerts');

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  /// Subscribe to specific community and province topics
  static Future<void> subscribeToLocalizedTopics({
    required String province,
    required String communityId,
  }) async {
    try {
      final provinceTopic =
          'province_${province.toLowerCase().replaceAll(' ', '_')}';
      final communityTopic = 'community_${communityId.replaceAll('-', '_')}';

      await _messaging.subscribeToTopic(provinceTopic);
      await _messaging.subscribeToTopic(communityTopic);

      debugPrint(
          '[Push] Subscribed to localized topics: $provinceTopic, $communityTopic');
    } catch (e) {
      debugPrint('[Push] Topic subscribe error: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      debugPrint('[Push] Get token error: $e');
      return null;
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'sos_amber_alert') {
      final data = Map<String, String>.from(message.data);
      _pendingAlertData = data;
      AlarmService.instance.playAlarm();
      onAlertReceived?.call(data);
      debugPrint('[Push] Foreground SOS alarm triggered');
    }
  }

  static void _handleMessageTap(RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'sos_amber_alert') {
      final data = Map<String, String>.from(message.data);
      _pendingAlertData = data;
      onAlertReceived?.call(data);
    }
  }
}
