import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  bool _showButton = false;
  String _nextRoute = '/language';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    _checkAutoNavigate();
  }

  Future<void> _checkAutoNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final onboarded = await SecureStorageService.isOnboarded();
    final hasAccount = await _hasSavedAccount();

    if (hasAccount && onboarded) {
      _nextRoute = '/auth';
      _navigate();
      return;
    }

    _nextRoute = onboarded ? '/auth' : '/language';
    if (!mounted) return;
    setState(() {
      _showButton = true;
    });
  }

  Future<bool> _hasSavedAccount() async {
    final token = await SecureStorageService.getAccessToken();
    final pinSet = await SecureStorageService.isPinSet();
    return (token != null && token.isNotEmpty) || pinSet;
  }

  void _navigate() {
    context.go(_nextRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Background image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/stay_safe.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Overlay for content - centered in middle
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'HAVENLY SOLUTIONS',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Haven. Your Community. Always On.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(179, 255, 0, 0),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            // Get started button
            if (_showButton)
              Positioned(
                bottom: 32,
                left: 24,
                right: 24,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _navigate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: const Text(
                      'Get started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
