package com.theblacksheep.havenly

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.telephony.TelephonyManager
import android.telephony.CellInfoGsm
import android.telephony.CellInfoLte
import android.telephony.CellInfoWcdma
import androidx.core.content.ContextCompat

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/*
 * MainActivity.kt
 * Havenly Solutions (Pty) Ltd
 * Phase 7 — Cell Tower Service native bridge
 *
 * Provides the getCellInfo method to the Flutter cell_tower_service.dart
 * via a MethodChannel. Returns MCC, MNC, LAC, CID, and signal strength
 * from the device telephony subsystem. Works on all Android forks
 * including Huawei HarmonyOS which preserves the Android telephony API.
 */
class MainActivity : FlutterActivity() {
  private val CHANNEL = "com.theblacksheep.havenly_solutions/cell_tower"

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL,
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "getCellInfo" -> result.success(getCellInfo())
        else -> result.notImplemented()
      }
    }
  }

  private fun getCellInfo(): Map<String, Any?> {
    val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager

    if (ContextCompat.checkSelfPermission(
        this, Manifest.permission.READ_PHONE_STATE
      ) != PackageManager.PERMISSION_GRANTED
    ) {
      return emptyMap()
    }

    try {
      val cells = tm.allCellInfo ?: return emptyMap()
      for (cell in cells) {
        when (cell) {
          is CellInfoLte -> {
            val id = cell.cellIdentity
            return mapOf(
              "mcc" to id.mccString,
              "mnc" to id.mncString,
              "lac" to id.tac.toString(),
              "cid" to id.ci.toString(),
              "signal_strength" to cell.cellSignalStrength.dbm,
              "operator" to tm.networkOperatorName,
            )
          }
          is CellInfoGsm -> {
            val id = cell.cellIdentity
            return mapOf(
              "mcc" to id.mccString,
              "mnc" to id.mncString,
              "lac" to id.lac.toString(),
              "cid" to id.cid.toString(),
              "signal_strength" to cell.cellSignalStrength.dbm,
              "operator" to tm.networkOperatorName,
            )
          }
          is CellInfoWcdma -> {
            val id = cell.cellIdentity
            return mapOf(
              "mcc" to id.mccString,
              "mnc" to id.mncString,
              "lac" to id.lac.toString(),
              "cid" to id.cid.toString(),
              "signal_strength" to cell.cellSignalStrength.dbm,
              "operator" to tm.networkOperatorName,
            )
          }
        }
      }
    } catch (e: Exception) {
      return emptyMap()
    }
    return emptyMap()
  }
}
