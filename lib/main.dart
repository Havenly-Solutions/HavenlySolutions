import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style for edge-to-edge content
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Firebase must initialize before the app runs.
  // On failure, show a user-facing error screen — do not silently continue.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Log to crash reporter if available, then show error UI
    debugPrint('Firebase initialization failed: \$e\n\$stack');
    runApp(const FirebaseInitErrorApp());
    return;
  }

  runApp(
    const ProviderScope(
      child: HavenlyApp(),
    ),
  );
}

/// Shown only if Firebase fails to initialize.
/// Allows the user to retry or contact support.
class FirebaseInitErrorApp extends StatelessWidget {
  const FirebaseInitErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFCC0000), size: 48),
                const SizedBox(height: 24),
                const Text(
                  'Could not connect to services.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Check your internet connection and try again.',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => main(),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Color(0xFFCC0000)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
