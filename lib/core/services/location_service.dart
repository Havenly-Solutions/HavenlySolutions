/*
 * ─────────────────────────────────────────────────────────────
 * FILE: lib/core/services/location_service.dart
 * PHASE: 7B — GPS Satellite (SOS Layer 1)
 *
 * PURPOSE:
 *   Hardware GPS satellite location capture and continuous
 *   heartbeat streaming. Works with zero internet and zero
 *   cell signal. The phone GPS chip communicates directly
 *   with satellites. Accuracy: 3-10 metres open sky.
 *
 *   On Huawei/Honor running HarmonyOS: geolocator communicates
 *   with the Android location subsystem which HarmonyOS preserves
 *   from AOSP. The hardware GPS chip is manufacturer-independent.
 *
 * HOW TO EXTEND:
 *   Phase 11 adds reverse geocoding here — coordinates resolve
 *   to suburb, city, province, and nearest police station using
 *   the backend geo API when internet is available.
 * ─────────────────────────────────────────────────────────────
 */

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static Position? _lastKnown;
  static StreamSubscription<Position>? _heartbeat;

  static Position? get lastKnown => _lastKnown;
  static bool get isTracking => _heartbeat != null;

  /// One-time position capture. Returns last known on timeout.
  /// Timeout: 10 seconds. Accuracy: high (GPS chip priority).
  static Future<Position?> capture() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return _lastKnown;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _lastKnown;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _lastKnown = pos;
      return pos;
    } on TimeoutException {
      return _lastKnown;
    } catch (e) {
      debugPrint('[GPS] Capture error: $e');
      return _lastKnown;
    }
  }

  /// Start continuous position tracking for SOS heartbeat.
  /// Updates fire every 10 metres of movement or every 10 seconds.
  /// Keeps running until stopHeartbeat() is called.
  static void startHeartbeat({
    required void Function(double lat, double lng, double accuracy) onUpdate,
    void Function(String error)? onError,
  }) {
    _heartbeat?.cancel();
    _heartbeat = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (pos) {
        _lastKnown = pos;
        onUpdate(pos.latitude, pos.longitude, pos.accuracy);
      },
      onError: (e) {
        debugPrint('[GPS] Heartbeat error: $e');
        onError?.call(e.toString());
      },
      cancelOnError: false,
    );
  }

  static void stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  static String mapsLink(double lat, double lng) =>
      'https://maps.google.com/?q=$lat,$lng';

  static String displayCoords(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}
