import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/location_service.dart';
import '../core/services/sms_service.dart';
import '../core/services/bluetooth_mesh_service.dart';
import '../core/security/secure_storage_service.dart';
import '../core/database/local_db.dart';
import 'api_service.dart';

enum SOSTriggerType {
  manualButton,
  failedLogin,
  panicShake,
  bluetoothRelay,
  ussd
}

class SOSService {
  final ApiService _apiService = ApiService();
  static final SOSService _instance = SOSService._internal();

  factory SOSService() => _instance;
  SOSService._internal();

  Future<void> triggerSOS({required SOSTriggerType triggerType}) async {
    // Step 1: Haptic feedback immediately
    HapticFeedback.heavyImpact();

    // Step 2: Capture GPS (with 5s timeout -> fallback to last known)
    final position = await _captureGPS();

    // Step 3: Save SOS to local SQLite IMMEDIATELY (offline survivability)
    final userId = await SecureStorageService.getUserId() ?? 'unknown';
    final triggeredAt = DateTime.now().millisecondsSinceEpoch;
    
    // We use the existing SosOrchestrator for local persistence for now
    // but we can extend it or replace it.
    // Let's use the logic from SosOrchestrator.trigger() but adapted.
    
    final eventId = await _saveSOSLocally(position, triggerType, userId, triggeredAt);

    // Step 4: Fire all layers simultaneously
    await Future.wait([
      _fireDirectSMS(position),
      _fireBTMesh(position, userId, triggeredAt),
      _fireBackendAPI(position, triggerType, eventId),
    ], eagerError: false);

    // Step 5: Start GPS heartbeat
    _startHeartbeat(eventId);
  }

  Future<Position?> _captureGPS() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  Future<String> _saveSOSLocally(Position? position, SOSTriggerType type, String userId, int triggeredAt) async {
    final eventId = DateTime.now().millisecondsSinceEpoch.toString(); // Simple ID for now or UUID
    await LocalDb.insertSosEvent({
      'id': eventId,
      'user_id': userId,
      'triggered_at': triggeredAt,
      'trigger_method': type.toString().split('.').last,
      'lat_at_trigger': position?.latitude,
      'lng_at_trigger': position?.longitude,
      'status': 'active',
      'synced': 0,
    });
    return eventId;
  }

  Future<void> _fireDirectSMS(Position? position) async {
    if (position == null) return;
    await SmsService.dispatch(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> _fireBTMesh(Position? position, String userId, int triggeredAt) async {
    await BluetoothMeshService.broadcastSos(
      userId: userId,
      latitude: position?.latitude,
      longitude: position?.longitude,
      triggeredAt: triggeredAt,
    );
  }

  Future<void> _fireBackendAPI(Position? position, SOSTriggerType type, String localId) async {
    try {
      await _apiService.post('/api/sos/trigger', data: {
        'localId': localId,
        'triggerType': type.toString().split('.').last,
        'lat': position?.latitude,
        'lng': position?.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Offline queue will handle retry if integrated in ApiService
    }
  }

  void _startHeartbeat(String sosId) {
    LocationService.startHeartbeat(
      onUpdate: (lat, lng, accuracy) async {
        try {
          await _apiService.patch('/api/sos/$sosId/location', data: {
            'lat': lat,
            'lng': lng,
            'accuracy': accuracy,
            'timestamp': DateTime.now().toIso8601String(),
          });
        } catch (_) {
          // Silent failure for heartbeat, next tick will try again
        }
      },
    );
  }

  Future<void> cancelSOS(String sosId) async {
    LocationService.stopHeartbeat();
    BluetoothMeshService.stopAll();
    try {
      await _apiService.delete('/api/sos/$sosId');
    } catch (_) {}
    
    await LocalDb.updateSosEvent(sosId, {
      'status': 'resolved',
      'closed_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
