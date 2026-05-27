import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/services/biometric_service.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/translations.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometries = [];
  bool _isCheckingBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricAvailability();
  }

  Future<void> _loadBiometricAvailability() async {
    final enabled = await BiometricService.instance.isBiometricLoginEnabled();
    if (!enabled) return;
    final types = await BiometricService.instance.getAvailableTypes();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = true;
      _availableBiometries = types;
    });
  }

  Future<void> _authenticateBiometric(BuildContext context) async {
    if (_isCheckingBiometric) return;
    setState(() => _isCheckingBiometric = true);
    final notifier = ref.read(userProvider.notifier);

    final result = await BiometricService.instance.authenticate(
      reason: 'Use biometrics to sign in to Havenly Solutions',
      allowDeviceCredential: true,
    );

    if (!mounted) return;
    setState(() => _isCheckingBiometric = false);

    if (result == BiometricResult.success) {
      final token = await SecureStorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        try {
          await notifier.loginWithToken(token);
          final pinSet = await SecureStorageService.isPinSet();
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          final router = GoRouter.of(context);
          router.go(pinSet ? '/pin-login' : '/pin-creation');
          return;
        } catch (e) {
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(content: Text('Biometric login failed.')),
          );
        }
      } else {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Biometric login failed.')),
        );
      }
    }

    if (result == BiometricResult.notAvailable ||
        result == BiometricResult.notEnrolled) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Biometric login is not available.')),
      );
    }
  }

  String _biometricLabel() {
    if (_availableBiometries.contains(BiometricType.face)) {
      return 'Use Face ID';
    }
    if (_availableBiometries.contains(BiometricType.fingerprint)) {
      return 'Use Fingerprint';
    }
    return 'Use Biometric Login';
  }

  IconData _biometricIcon() {
    if (_availableBiometries.contains(BiometricType.face)) {
      return Icons.face_retouching_natural;
    }
    return Icons.fingerprint;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background - Clean minimalist imagery
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/images/blurry.png'),
                    fit: BoxFit.cover),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo above the text
                  Image.asset('assets/images/logo.png', width: 80, height: 80),
                  const SizedBox(height: 24),
                  // App Name in white
                  Text(
                    AppTranslations.t('app_name'),
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  // Tagline in orange
                  Text(
                    AppTranslations.t('app_tagline'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryOrange),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppTranslations.t('login'),
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3D3D))),
                  const SizedBox(height: 8),
                  Text(AppTranslations.t('welcome_sub'),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 24),
                  if (_biometricAvailable)
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isCheckingBiometric
                              ? null
                              : () => _authenticateBiometric(context),
                          icon: Icon(_biometricIcon(), size: 22),
                          label: Text(_biometricLabel()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  _buildInput(Icons.email_outlined, AppTranslations.t('email')),
                  const SizedBox(height: 16),
                  _buildInput(
                      Icons.lock_outline, AppTranslations.t('confirm_pin'),
                      isObscure: true),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: Text(AppTranslations.t('login'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ),
                  const SizedBox(height: 16),
                  // Sign Up Choice
                  OutlinedButton(
                    onPressed: () => context.push('/signup'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 2),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      AppTranslations.t('sign_up'),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Guest Access
                  TextButton(
                    onPressed: () => context.push('/guest-auth'),
                    child: Text(
                      AppTranslations.t('Guest Access'),
                      style: const TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(IconData icon, String hint, {bool isObscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        obscureText: isObscure,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.grey[400], size: 22),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
