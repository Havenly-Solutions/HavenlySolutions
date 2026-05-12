import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app/app.dart';
import 'app/routes.dart';
import 'core/constants/translations.dart';
import 'core/services/bluetooth_mesh_service.dart';
import 'services/offline_queue_service.dart';
import 'core/database/local_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── DEVELOPMENT RESET ───────────────────────────────────────
  // Wipe all data and preferences on every startup to ensure 
  // we enter as a fresh user every single time.
  await LocalDb.resetForFreshUser();
  
  final prefs = await SharedPreferences.getInstance();
  
  // Set initial language to 'en' by default for new user
  await prefs.setString('app_language', 'en');
  AppTranslations.setLanguage('en');

  // Start Bluetooth mesh relay listener.
  BluetoothMeshService.startRelayListener(
    onSosReceived: (packet) {
      debugPrint('[Relay] Received SOS from ${packet.userId}');
    },
  );

  // Start Connectivity Listener for Offline Queue
  Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
    if (results.isNotEmpty && results.first != ConnectivityResult.none) {
      OfflineQueueService().processQueue();
    }
  });
  
  // The splash screen should always be the entry point for a fresh user
  const initialRoute = AppRoutes.splash;

  runApp(HavenlySolutionsApp(initialRoute: initialRoute));
}
