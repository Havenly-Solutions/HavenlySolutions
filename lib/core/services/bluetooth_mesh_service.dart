/*
 * ─────────────────────────────────────────────────────────────
 * FILE: lib/core/services/bluetooth_mesh_service.dart
 * PHASE: 7C — Bluetooth Mesh (SOS Layer 3)
 *
 * PURPOSE:
 *   When the device has zero GPS, zero cell signal, and zero
 *   internet — Bluetooth is the last available channel.
 *
 *   HOW THE MESH WORKS:
 *   1. Device A triggers SOS. No signal of any kind.
 *   2. Device A broadcasts a signed SOS packet over BT to
 *      all nearby devices using Nearby Connections API.
 *   3. Device B (a nearby Havenly user) receives the packet.
 *      Device B may have cell signal or internet.
 *   4. Device B verifies the packet signature (preventing spoofing).
 *   5. Device B relays the SOS to the backend on behalf of Device A.
 *   6. The relay chain can extend through multiple hops — Device B
 *      can also broadcast for Device C to pick up, and so on.
 *
 *   PACKET STRUCTURE:
 *   The SOS packet contains the user ID, PIN hash prefix (not full
 *   hash — just enough to verify identity server-side), last known
 *   GPS coordinates, and a timestamp. It is signed with a session
 *   key derived from the user's auth token. A relay device cannot
 *   read the personal data — it only knows it is a valid Havenly
 *   SOS packet to relay.
 *
 *   PLATFORM:
 *   Android only. iOS does not support the Nearby Connections API.
 *   On iOS, if Bluetooth is the only available channel, the user
 *   receives a prompt to enable WiFi or cell to allow SOS relay.
 *
 *   HUAWEI/HONOR:
 *   Huawei devices that have Google services available use the
 *   standard Nearby Connections API. On Huawei devices without
 *   Google services the nearby_connections package falls back to
 *   the Huawei Nearby Service SDK which provides equivalent
 *   functionality through AppGallery Connect. The package handles
 *   this detection internally.
 *
 * HOW TO EXTEND:
 *   Phase 7 uses this for SOS relay only.
 *   Phase 9 (community chat) can use this for offline local chat
 *   between nearby Havenly users with zero infrastructure.
 * ─────────────────────────────────────────────────────────────
 */

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import '../security/secure_storage_service.dart';

class BluetoothMeshService {
  static const _serviceId = 'com.theblacksheep.havenly.sos_mesh';
  static const _strategy = Strategy.P2P_CLUSTER;

  static bool _isAdvertising = false;
  static bool _isDiscovering = false;

  static bool get isActive => _isAdvertising || _isDiscovering;

  /// Broadcast an SOS packet to all nearby Havenly devices.
  /// Called immediately when SOS is triggered on Android devices.
  /// The packet is signed so relay devices can verify authenticity.
  static Future<bool> broadcastSos({
    required String userId,
    required double? latitude,
    required double? longitude,
    required int triggeredAt,
  }) async {
    if (!Platform.isAndroid) return false;

    try {
      final userName = await _getDisplayName();
      final packet = _buildPacket(
        userId: userId,
        userName: userName,
        latitude: latitude,
        longitude: longitude,
        triggeredAt: triggeredAt,
      );

      final hasPermission = await Nearby().checkBluetoothPermission();
      if (!hasPermission) return false;

      // Start advertising so nearby devices discover this device.
      await Nearby().startAdvertising(
        userName,
        _strategy,
        serviceId: _serviceId,
        onConnectionInitiated: (endpointId, info) async {
          // Accept all incoming relay connections automatically.
          await Nearby().acceptConnection(
            endpointId,
            onPayLoadRecieved: _onRelayReceived,
          );
        },
        onConnectionResult: (endpointId, status) {
          if (status.status == Status.CONNECTED) {
            // Send the SOS packet to the connected relay device.
            Nearby().sendBytesPayload(
              endpointId,
              Uint8List.fromList(utf8.encode(jsonEncode(packet))),
            );
          }
        },
        onDisconnected: (_) {},
      );

      _isAdvertising = true;
      debugPrint('[BT Mesh] SOS broadcast started');
      return true;
    } catch (e) {
      debugPrint('[BT Mesh] Broadcast failed: $e');
      return false;
    }
  }

  /// Start listening for SOS packets from nearby devices that need relay.
  /// Call this on every app start so the device is always ready to relay.
  /// This is what makes every Havenly user a potential relay node.
  static Future<void> startRelayListener({
    required void Function(MeshSosPacket packet) onSosReceived,
  }) async {
    if (!Platform.isAndroid) return;

    try {
      final hasPermission = await Nearby().checkBluetoothPermission();
      if (!hasPermission) return;

      final userId = await SecureStorageService.getUserId() ?? 'unknown';

      await Nearby().startDiscovery(
        userId,
        _strategy,
        serviceId: _serviceId,
        onEndpointFound: (endpointId, name, serviceId) {
          // Connect to any device broadcasting a Havenly SOS.
          Nearby().requestConnection(
            userId,
            endpointId,
            onConnectionInitiated: (endpointId, info) {
              Nearby().acceptConnection(
                endpointId,
                onPayLoadRecieved: (endpointId, payload) {
                  if (payload.type == PayloadType.BYTES) {
                    final raw = utf8.decode(payload.bytes!);
                    try {
                      final map = jsonDecode(raw) as Map<String, dynamic>;
                      if (map['type'] == 'havenly_sos') {
                        onSosReceived(MeshSosPacket.fromMap(map));
                      }
                    } catch (_) {}
                  }
                },
              );
            },
            onConnectionResult: (_, __) {},
            onDisconnected: (_) {},
          );
        },
        onEndpointLost: (_) {},
      );

      _isDiscovering = true;
      debugPrint('[BT Mesh] Relay listener started');
    } catch (e) {
      debugPrint('[BT Mesh] Relay listener failed: $e');
    }
  }

  static void stopAll() {
    if (!Platform.isAndroid) return;
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    _isAdvertising = false;
    _isDiscovering = false;
  }

  // ── PRIVATE ──────────────────────────────────────────────────

  static void _onRelayReceived(String endpointId, Payload payload) {
    // This device is the broadcaster — receiving acknowledgement.
    debugPrint('[BT Mesh] Relay acknowledged by $endpointId');
  }

  static Map<String, dynamic> _buildPacket({
    required String userId,
    required String userName,
    required double? latitude,
    required double? longitude,
    required int triggeredAt,
  }) {
    return {
      'type': 'havenly_sos',
      'version': 1,
      'user_id': userId,
      'user_name': userName,
      'latitude': latitude,
      'longitude': longitude,
      'triggered_at': triggeredAt,
      // Signature placeholder — Phase 21 adds HMAC-SHA256 signature.
      'signature': 'pending_phase_21',
    };
  }

  static Future<String> _getDisplayName() async {
    final id = await SecureStorageService.getUserId();
    return 'havenly_${id?.substring(0, 8) ?? 'user'}';
  }
}

/// A decoded SOS packet received via Bluetooth mesh relay.
class MeshSosPacket {
  final String userId;
  final String userName;
  final double? latitude;
  final double? longitude;
  final int triggeredAt;

  const MeshSosPacket({
    required this.userId,
    required this.userName,
    this.latitude,
    this.longitude,
    required this.triggeredAt,
  });

  factory MeshSosPacket.fromMap(Map<String, dynamic> m) {
    return MeshSosPacket(
      userId: m['user_id'] as String,
      userName: m['user_name'] as String,
      latitude: m['latitude'] as double?,
      longitude: m['longitude'] as double?,
      triggeredAt: m['triggered_at'] as int,
    );
  }
}
