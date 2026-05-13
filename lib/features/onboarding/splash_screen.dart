import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/routes.dart';
import '../../core/security/secure_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _slidePosition = 0.0;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Force English specifically on this screen initialization to be absolutely sure
  }

  Future<void> _onSlideComplete() async {
    if (_navigated) return;
    _navigated = true;

    final prefs = await SharedPreferences.getInstance();
    final seenLanguage = prefs.getBool('seen_language') ?? false;
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    final hasAccount = prefs.getBool('has_account') ?? false;

    // Check if user is already authenticated
    final userId = await SecureStorageService.getUserId();
    final isAuthenticated = userId != null;

    if (!mounted) return;

    if (!seenLanguage) {
      Navigator.pushReplacementNamed(context, AppRoutes.language);
    } else if (!hasAccount) {
      Navigator.pushReplacementNamed(context, AppRoutes.auth);
    } else if (!seenOnboarding) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else if (isAuthenticated) {
      // User is already logged in, go directly to home
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We don't watch language provider here because splash is always English
    final screenWidth = MediaQuery.of(context).size.width;
    final slideWidth = screenWidth - 64;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/Stay safe.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.4),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Havenly Solutions', // Hardcoded as English for Splash
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Haven. Your Community. Always on.', // Hardcoded as English for Splash
                  style: TextStyle(
                    color: Color(0xFFFF9800),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 3),

                // Slide to begin
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    height: 64,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Text(
                            'SLIDE TO BEGIN', // Hardcoded as English for Splash
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        Positioned(
                          left: _slidePosition,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                _slidePosition += details.delta.dx;
                                if (_slidePosition < 0) _slidePosition = 0;
                                if (_slidePosition > slideWidth - 56) {
                                  _slidePosition = slideWidth - 56;
                                }
                              });
                            },
                            onHorizontalDragEnd: (details) {
                              if (_slidePosition > slideWidth * 0.7) {
                                setState(
                                    () => _slidePosition = slideWidth - 56);
                                _onSlideComplete();
                              } else {
                                setState(() => _slidePosition = 0);
                              }
                            },
                            child: Container(
                              width: 56,
                              height: 56,
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
