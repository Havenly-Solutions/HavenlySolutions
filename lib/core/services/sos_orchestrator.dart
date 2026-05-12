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
  /// This is the only public trigger — never bypass this method.
  static Future<SosResult> trigger() async {
    if (_isActive) return _currentResult!;
    _isActive = true;

    // ── STEP 0: Immediate Physical Feedback ────────────────────
    HapticFeedback.heavyImpact();
    Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);

    final eventId = const Uuid().v4();
    _activeEventId = eventId;
    final triggeredAt = DateTime.now().millisecondsSinceEpoch;
    final userId = await SecureStorageService.getUserId() ?? 'guest';

    // ── STEP 1: Persist event immediately before anything else ──
    // This guarantees the event is recorded even if the device
    // crashes during the trigger sequence.
    await LocalDb.insertSosEvent({
      'id': eventId,
      'user_id': userId,
      'triggered_at': triggeredAt,
      'trigger_method': 'app',
      'status': 'active',
      'synced': 0,
    });

    debugPrint('[SOS] Event $eventId created — firing all layers');

    // ── STEP 2: Fire all layers simultaneously ──────────────────
    // Future.wait starts all three immediately with no sequencing.
    final results = await Future.wait([
      _fireLayer1Gps(),
      _fireLayer2CellTower(),
      _fireLayer3Bluetooth(userId: userId, triggeredAt: triggeredAt),
    ]);

    final gpsResult   = results[0] as GpsLayerResult;
    final cellResult  = results[1] as CellLayerResult;
    final meshResult  = results[2] as bool;

    // ── STEP 3: Dispatch SMS immediately ───────────────────────
    // Runs after GPS so we can include coordinates in the message.
    final smsResult = await SmsService.dispatch(
      latitude: gpsResult.latitude,
      longitude: gpsResult.longitude,
    );

    // ── STEP 4: Update local record with layer results ──────────
    await LocalDb.updateSosEvent(eventId, {
      'lat_at_trigger': gpsResult.latitude,
      'lng_at_trigger': gpsResult.longitude,
      'cell_mcc': cellResult.data?.mcc,
      'cell_mnc': cellResult.data?.mnc,
      'cell_lac': cellResult.data?.lac,
      'cell_cid': cellResult.data?.cid,
      'layer1_gps': gpsResult.success ? 1 : 0,
      'layer2_cell': cellResult.success ? 1 : 0,
      'layer3_mesh': meshResult ? 1 : 0,
      'sms_sent': smsResult.anySucceeded ? 1 : 0,
      'sms_contacts': smsResult.succeeded,
    });

    // ── STEP 5: Start GPS heartbeat ─────────────────────────────
    LocationService.startHeartbeat(
      onUpdate: (lat, lng, accuracy) {
        _onHeartbeatTick(eventId: eventId, lat: lat, lng: lng);
      },
    );

    // ── STEP 6: Start local heartbeat timer ─────────────────────
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
      layer1Gps: gpsResult,
      layer2Cell: cellResult,
      layer3Mesh: meshResult,
      smsResult: smsResult,
      triggeredAt: DateTime.fromMillisecondsSinceEpoch(triggeredAt),
    );

    debugPrint('[SOS] All layers complete — $_currentResult');
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

  static Future<GpsLayerResult> _fireLayer1Gps() async {
    final pos = await LocationService.capture();
    return GpsLayerResult(
      success: pos != null,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      accuracy: pos?.accuracy,
    );
  }

  static Future<CellLayerResult> _fireLayer2CellTower() async {
    final data = await CellTowerService.read();
    return CellLayerResult(
      success: data?.hasData ?? false,
      data: data,
    );
  }

  static Future<bool> _fireLayer3Bluetooth({
    required String userId,
    required int triggeredAt,
  }) async {
    return BluetoothMeshService.broadcastSos(
      userId: userId,
      latitude: LocationService.lastKnown?.latitude,
      longitude: LocationService.lastKnown?.longitude,
      triggeredAt: triggeredAt,
    );
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
    // Phase 14 sends each tick to the backend here.
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
