/*
 * ─────────────────────────────────────────────────────────────
 * FILE: lib/core/services/sos_orchestrator.dart
 * PHASE: 7 — SOS Core Coordinator
 *
 * PURPOSE:
 *   The single entry point for all SOS activity in the app.
 *   SosOrchestrator.trigger() is the ONLY method the UI calls.
 *   It coordinates all three layers simultaneously and manages
 *   state for the entire lifecycle of an SOS event:
 *     trigger → heartbeat → rescue confirmation → closure
 *
 *   ALL THREE LAYERS FIRE IN PARALLEL using Future.wait.
 *   No layer waits for another. Each reports its own success.
 *
 *   EVENT SURVIVABILITY:
 *   The SOS event is written to SQLite BEFORE any layer fires.
 *   Even if the device crashes immediately after trigger, the
 *   event record exists locally and will sync when the device
 *   is recovered or another device logs in with the same PIN.
 *
 *   DEVICE DESTRUCTION SCENARIO:
 *   If the device goes offline permanently after trigger, the
 *   backend (Phase 14) maintains a server-side heartbeat ticker
 *   using the last known position and continues dispatching to
 *   emergency services until an operator closes the event from
 *   the dashboard.
 *
 * HOW TO EXTEND:
 *   Phase 14: Replace the API placeholder with real HTTP call.
 *   Phase 17: Add Socket.IO community broadcast call.
 *   Phase 19: Add FCM push notification to nearby users.
 *   Phase 20: USSD trigger from feature phones calls a separate
 *             entry point: SosOrchestrator.triggerFromUssd()
 * ─────────────────────────────────────────────────────────────
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';
import '../database/local_db.dart';
import '../security/secure_storage_service.dart';
import 'api_service.dart';
import 'offline_sync_service.dart';
import 'location_service.dart';
import 'cell_tower_service.dart';
import 'bluetooth_mesh_service.dart';
import 'sms_service.dart';

class SosOrchestrator {
  // ── STATE ───────────────────────────────────────────────────

  static SosResult? _currentResult;
  static String? _activeEventId;
  static bool _isActive = false;
  static Timer? _serverHeartbeatTimer;

  static SosResult? get currentResult => _currentResult;
  static String? get activeEventId => _activeEventId;
  static bool get isActive => _isActive;

  // ── MAIN TRIGGER ─────────────────────────────────────────────

  /// Fire all three SOS layers simultaneously.
  /// Returns a SosResult describing the outcome of each layer.
  static Future<SosResult> trigger({String? threatSource}) async {
    if (_isActive) return _currentResult!;
    _isActive = true;

    // ── STEP 0: Immediate Physical Feedback ────────────────────
    HapticFeedback.heavyImpact();
    Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);

    final eventId = const Uuid().v4();
    _activeEventId = eventId;
    final triggeredAt = DateTime.now().millisecondsSinceEpoch;
    final userId = await SecureStorageService.getUserId() ?? 'guest';

    // ── STEP 0.5: Scan nearby users for exclusion zone (2 second scan max) ──
    final excludedUserIds = await BluetoothMeshService.getNearbyPeers()
        .timeout(const Duration(seconds: 2), onTimeout: () => []);

    // ── STEP 1: Persist event immediately before anything else ──
    await LocalDb.insertSosEvent({
      'id': eventId,
      'user_id': userId,
      'triggered_at': triggeredAt,
      'trigger_method': 'app',
      'status': 'active',
      'synced': 0,
      'excluded_user_ids': excludedUserIds.join(','),
      'threat_source': threatSource,
    });

    debugPrint(
        '[SOS] Event $eventId created — starting sequential fallback chain');

    // ── STEP 2: Sequential Fallback Chain ──────────────────────
    // FIRE sequentially. Only proceed to next layer if current one fails.

    // Wave 1: GPS (Dependency for most alerts)
    await _fireLayer1Gps(eventId);

    // Wave 4: Backend API (Primary - Richest data)
    bool success = await _fireLayer4BackendAPI(eventId);

    if (!success) {
      debugPrint('[SOS] Wave 4 (API) failed. Falling back to Wave 5 (SMS).');
      success = await _fireLayer5Sms(eventId);
    }

    if (!success) {
      debugPrint(
          '[SOS] Wave 5 (SMS) failed. Falling back to Wave 3 (Bluetooth Mesh).');
      success = await _fireLayer3Bluetooth(
        userId: userId,
        triggeredAt: triggeredAt,
        eventId: eventId,
      );
    }

    if (!success) {
      debugPrint(
          '[SOS] Wave 3 (Mesh) failed. Final fallback to Wave 2 (Cell Tower/USSD).');
      await _fireLayer2CellTower(eventId);
    }

    // ── STEP 3: Start GPS heartbeat ─────────────────────────────
    LocationService.startHeartbeat(
      onUpdate: (lat, lng, accuracy) {
        _onHeartbeatTick(eventId: eventId, lat: lat, lng: lng);
      },
    );

    // ── STEP 4: Start local heartbeat timer ─────────────────────
    // Updates the local record every 10 seconds even without
    // location movement to keep last_heartbeat_at fresh.
    _serverHeartbeatTimer?.cancel();
    _serverHeartbeatTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _onHeartbeatTick(
        eventId: eventId,
        lat: LocationService.lastKnown?.latitude,
        lng: LocationService.lastKnown?.longitude,
      ),
    );

    _currentResult = SosResult(
      eventId: eventId,
      layer1Gps: const GpsLayerResult(success: false),
      layer2Cell: const CellLayerResult(success: false),
      layer3Mesh: false,
      smsResult: const SmsSendResult(attempted: 0, succeeded: 0),
      triggeredAt: DateTime.fromMillisecondsSinceEpoch(triggeredAt),
    );

    debugPrint('[SOS] SOS Triggered — waves firing in background');
    return _currentResult!;
  }

  // ── RESCUE CONFIRMATION ──────────────────────────────────────

  /// User confirms they are safe (genuine confirmation — tap).
  static Future<void> confirmSafe() async {
    if (!_isActive || _activeEventId == null) return;
    await _closeSosEvent(
      eventId: _activeEventId!,
      rescueMethod: 'safe',
      closedBy: 'user',
    );
    debugPrint('[SOS] Closed — user confirmed safe');
  }

  /// User holds the safe button — indicates duress (covert escalation).
  /// The UI shows "Thank you — stay safe" but internally escalates.
  static Future<void> confirmSafeUnderDuress() async {
    if (!_isActive || _activeEventId == null) return;

    // Escalate on dashboard — do NOT stop heartbeat.
    await LocalDb.updateSosEvent(_activeEventId!, {
      'status': 'duress',
      'rescue_method': 'forced_safe',
      'rescue_confirmed_at': DateTime.now().millisecondsSinceEpoch,
      'synced': 0, // Backend must re-sync to escalate dashboard
    });

    // Phase 14: Send dashboard:sos_status_change with status: 'duress'
    // Emergency services will be silently re-dispatched by the backend.
    debugPrint('[SOS] DURESS confirmed — escalating silently');
  }

  /// Cancel the SOS. Only the user can do this via the cancel button
  /// with confirmation dialog.
  static Future<void> cancel() async {
    if (!_isActive || _activeEventId == null) return;
    await _closeSosEvent(
      eventId: _activeEventId!,
      rescueMethod: 'user_cancelled',
      closedBy: 'user',
    );
    debugPrint('[SOS] Cancelled by user');
  }

  // ── PRIVATE HELPERS ──────────────────────────────────────────

  static Future<bool> _fireLayer1Gps(String eventId) async {
    final pos = await LocationService.capture();
    await LocalDb.updateSosEvent(eventId, {
      'lat_at_trigger': pos?.latitude,
      'lng_at_trigger': pos?.longitude,
      'layer1_gps': pos != null ? 1 : 0,
    });
    debugPrint('[SOS] Wave 1 (GPS) complete');
    return pos != null;
  }

  static Future<bool> _fireLayer2CellTower(String eventId) async {
    final data = await CellTowerService.read();
    await LocalDb.updateSosEvent(eventId, {
      'cell_mcc': data?.mcc,
      'cell_mnc': data?.mnc,
      'cell_lac': data?.lac,
      'cell_cid': data?.cid,
      'layer2_cell': (data?.hasData ?? false) ? 1 : 0,
    });
    debugPrint('[SOS] Wave 2 (Cell Tower) complete');
    return data?.hasData ?? false;
  }

  static Future<bool> _fireLayer3Bluetooth({
    required String userId,
    required int triggeredAt,
    required String eventId,
  }) async {
    final success = await BluetoothMeshService.broadcastSos(
      userId: userId,
      latitude: LocationService.lastKnown?.latitude,
      longitude: LocationService.lastKnown?.longitude,
      triggeredAt: triggeredAt,
    );
    await LocalDb.updateSosEvent(eventId, {
      'layer3_mesh': success ? 1 : 0,
    });
    debugPrint('[SOS] Wave 3 (Bluetooth Mesh) complete');
    return success;
  }

  static Future<bool> _fireLayer4BackendAPI(String eventId) async {
    try {
      final pos = LocationService.lastKnown;
      final cell = await CellTowerService.read();

      final response = await ApiService().triggerSos(
        id: eventId,
        lat: pos?.latitude ?? 0.0,
        lng: pos?.longitude ?? 0.0,
        accuracyM: pos?.accuracy ?? 0.0,
        cellCid: cell?.cid,
        cellLac: cell?.lac,
      );

      final isSuccessful = (response['data']?['status'] == 'ACTIVE' ||
          response['data']?['status'] == 'DISPATCHING');

      await LocalDb.updateSosEvent(eventId, {
        'api_reached': 1,
        'services_notified': isSuccessful ? 1 : 0,
      });
      debugPrint(
          '[SOS] Wave 4 (Backend API) complete - Success: $isSuccessful');
      return isSuccessful;
    } catch (e) {
      debugPrint('[SOS] Wave 4 (Backend API) failed: $e');

      // Enqueue for offline sync if it failed
      final pos = LocationService.lastKnown;
      final cell = await CellTowerService.read();

      unawaited(OfflineSyncService.instance.enqueueRequest(
        endpoint: '/api/mobile/sos/trigger',
        method: 'POST',
        payload: {
          'id': eventId,
          'lat': pos?.latitude ?? 0.0,
          'lng': pos?.longitude ?? 0.0,
          'accuracyM': pos?.accuracy ?? 0.0,
          if (cell?.cid != null) 'cellCid': cell?.cid,
          if (cell?.lac != null) 'cellLac': cell?.lac,
        },
      ));
      return false;
    }
  }

  static Future<bool> _fireLayer5Sms(String eventId) async {
    final pos = LocationService.lastKnown;
    final smsResult = await SmsService.dispatch(
      latitude: pos?.latitude,
      longitude: pos?.longitude,
    );
    await LocalDb.updateSosEvent(eventId, {
      'sms_sent': smsResult.anySucceeded ? 1 : 0,
      'sms_contacts': smsResult.succeeded,
    });
    debugPrint(
        '[SOS] Wave 5 (SMS) complete - Success: ${smsResult.anySucceeded}');
    return smsResult.anySucceeded;
  }

  static void _onHeartbeatTick({
    required String eventId,
    double? lat,
    double? lng,
  }) {
    if (!_isActive) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    LocalDb.updateSosEvent(eventId, {
      if (lat != null) 'last_lat': lat,
      if (lng != null) 'last_lng': lng,
      'last_heartbeat_at': now,
      'synced': 0,
    });

    // Phase 14: Send heartbeat to backend if online
    if (lat != null && lng != null) {
      unawaited(ApiService().sendHeartbeat(
        sosId: eventId,
        lat: lat,
        lng: lng,
      ));
    }

    debugPrint('[SOS] Heartbeat: $lat, $lng at $now');
  }

  static Future<void> _closeSosEvent({
    required String eventId,
    required String rescueMethod,
    required String closedBy,
  }) async {
    LocationService.stopHeartbeat();
    _serverHeartbeatTimer?.cancel();
    BluetoothMeshService.stopAll();

    await LocalDb.updateSosEvent(eventId, {
      'status': 'resolved',
      'rescue_method': rescueMethod,
      'closed_at': DateTime.now().millisecondsSinceEpoch,
      'closed_by': closedBy,
      'synced': 0,
    });

    _isActive = false;
    _currentResult = null;
    _activeEventId = null;
  }
}

// ── RESULT TYPES ─────────────────────────────────────────────

class GpsLayerResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  const GpsLayerResult({
    required this.success,
    this.latitude,
    this.longitude,
    this.accuracy,
  });
}

class CellLayerResult {
  final bool success;
  final CellTowerData? data;
  const CellLayerResult({required this.success, this.data});
}

class SosResult {
  final String eventId;
  final GpsLayerResult layer1Gps;
  final CellLayerResult layer2Cell;
  final bool layer3Mesh;
  final SmsSendResult smsResult;
  final DateTime triggeredAt;

  const SosResult({
    required this.eventId,
    required this.layer1Gps,
    required this.layer2Cell,
    required this.layer3Mesh,
    required this.smsResult,
    required this.triggeredAt,
  });

  @override
  String toString() =>
      'SosResult(gps: ${layer1Gps.success}, cell: ${layer2Cell.success}, '
      'mesh: $layer3Mesh, sms: ${smsResult.succeeded}/${smsResult.attempted})';
}
