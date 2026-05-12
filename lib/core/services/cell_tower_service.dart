/*
 * ─────────────────────────────────────────────────────────────
 * FILE: lib/core/services/cell_tower_service.dart
 * PHASE: 7 — Cell Tower Triangulation (SOS Layer 2)
 *
 * PURPOSE:
 *   Reads the current cell tower registration data from the
 *   Android telephony system. This data (MCC, MNC, LAC, CID)
 *   identifies which cell tower the device is registered with.
 *   The backend uses this with a tower geolocation database to
 *   triangulate approximate position without GPS or internet.
 *
 *   This is how USSD SOS works for feature phones:
 *   1. User dials *134*PIN#
 *   2. Africa's Talking captures the caller phone number
 *   3. The network provides the cell tower ID
 *   4. The backend maps tower ID to approximate coordinates
 *   5. Emergency services receive that location
 *
 *   Works on: Android, Huawei, Honor (all use Android telephony API)
 *   Works on: iOS — returns null (iOS restricts this API)
 *
 * HOW TO EXTEND:
 *   Phase 20 (Africa's Talking) uses CellTowerData.toMap() as
 *   part of the USSD dispatch payload to the backend.
 * ─────────────────────────────────────────────────────────────
 */

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class CellTowerService {
  static const _channel = MethodChannel('com.theblacksheep.havenly/cell_tower');

  /// Read current cell tower registration data.
  /// Returns null on iOS or if permission is denied.
  static Future<CellTowerData?> read() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getCellInfo',
      );
      if (result == null) return null;
      return CellTowerData.fromMap(result);
    } on PlatformException catch (e) {
      debugPrint('[CellTower] Read failed: $e');
      return null;
    }
  }
}

class CellTowerData {
  final String? mcc;   // Mobile Country Code — 655 for South Africa
  final String? mnc;   // Mobile Network Code — identifies operator
  final String? lac;   // Location Area Code
  final String? cid;   // Cell ID
  final int? signalStrength;
  final String? operator;

  const CellTowerData({
    this.mcc,
    this.mnc,
    this.lac,
    this.cid,
    this.signalStrength,
    this.operator,
  });

  factory CellTowerData.fromMap(Map<String, dynamic> m) {
    return CellTowerData(
      mcc: m['mcc']?.toString(),
      mnc: m['mnc']?.toString(),
      lac: m['lac']?.toString(),
      cid: m['cid']?.toString(),
      signalStrength: m['signal_strength'] as int?,
      operator: m['operator'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'mcc': mcc,
    'mnc': mnc,
    'lac': lac,
    'cid': cid,
    'signal_strength': signalStrength,
    'operator': operator,
  };

  bool get hasData => mcc != null && lac != null && cid != null;
}
