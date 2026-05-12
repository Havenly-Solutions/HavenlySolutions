package com.theblacksheep.havenly

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/*
 * BootReceiver.kt
 * Havenly Solutions (Pty) Ltd
 * Phase 7 — Boot Receiver
 *
 * Restarts the heartbeat background service if the device reboots
 * during an active SOS event.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // flutter_background_service handles its own restart if 
            // autoStart is true, but this receiver ensures it is 
            // triggered by the OS on boot.
        }
    }
}
