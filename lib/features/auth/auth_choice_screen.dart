import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/translations.dart';
import '../../core/database/local_db.dart';
import '../../core/providers/language_provider.dart';
import '../../core/security/secure_storage_service.dart';
import '../../app/routes.dart';
import '../../Shared/theme/app_theme.dart';

class AuthChoiceScreen extends StatefulWidget {
  const AuthChoiceScreen({super.key});

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen> {
  bool _hasAccount = false;
  bool _biometricAvailable = false;
  bool _checkingBiometric = true;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkExistingAccount();
  }

  Future<void> _checkExistingAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccount = prefs.getBool('has_account') ?? false;
    final pin = prefs.getString('user_pin') ?? '';
    final canUseBiometric = await _canUseBiometric();
    if (!mounted) return;
    setState(() {
      _hasAccount = hasAccount && pin.isNotEmpty;
      _biometricAvailable = canUseBiometric;
      _checkingBiometric = false;
    });
  }

  Future<bool> _canUseBiometric() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleLoginPressed() async {
    if (_biometricAvailable) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Confirm your identity to continue to Havenly.',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        if (!mounted) return;
        if (authenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
          return;
        }
      } catch (_) {
        if (!mounted) return;
      }
    }
    Navigator.pushNamed(context, AppRoutes.pin);
  }

  Future<void> _loginWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirm it is you, then enter your PIN.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!mounted || !authenticated) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric login is not available right now.'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
    }
  }

  Future<void> _resetDataAndSignup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Start Fresh',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'This will clear saved credentials and allow you to register again.',
          style: GoogleFonts.dmSans(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Continue',
              style: GoogleFonts.dmSans(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await LocalDb.resetForFreshUser();
    await SecureStorageService.clearAll();
    if (!mounted) return;
    setState(() {
      _hasAccount = false;
      _biometricAvailable = false;
      _checkingBiometric = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All saved account data and app settings have been cleared.'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signup, (route) => false);
  }

  void _showGuestWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppTranslations.t('guest_warning_title'),
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          AppTranslations.t('guest_warning_body'),
          style: GoogleFonts.dmSans(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.t('cancel'),
              style: GoogleFonts.dmSans(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.terms);
            },
            child: Text(
              AppTranslations.t('confirm'),
              style: GoogleFonts.dmSans(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/GBV.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.18),
                    Colors.black.withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Havenly Solutions',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppTranslations.t('auth_choice_title'),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppTranslations.t('auth_choice_sub'),
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: screenHeight * 0.70,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Access the app securely with your preferred method.',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _AuthChoiceButton(
                              label: AppTranslations.t('sign_up'),
                              filled: true,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
                            ),
                            const SizedBox(height: 16),
                            _AuthChoiceButton(
                              label: AppTranslations.t('login'),
                              filled: false,
                              disabled: !_hasAccount,
                              onTap: _hasAccount ? _handleLoginPressed : null,
                            ),
                            if (_hasAccount && _biometricAvailable && !_checkingBiometric) ...[
                              const SizedBox(height: 16),
                              _AuthChoiceButton(
                                label: AppTranslations.t('use_biometric'),
                                filled: false,
                                icon: Icons.fingerprint,
                                onTap: _loginWithBiometric,
                              ),
                            ],
                            const SizedBox(height: 16),
                            _AuthChoiceButton(
                              label: AppTranslations.t('guest_mode'),
                              filled: false,
                              onTap: _showGuestWarning,
                            ),
                            if (_hasAccount) ...[
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: _resetDataAndSignup,
                                child: Text(
                                  'Reset Account',
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              _hasAccount
                                  ? 'Secure access with PIN, biometrics, or guest mode.'
                                  : 'Create a new account or continue as a guest to stay connected.',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.textTertiary,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthChoiceButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool disabled;
  final IconData? icon;
  final VoidCallback? onTap;

  const _AuthChoiceButton({
    required this.label,
    required this.filled,
    this.disabled = false,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = disabled
        ? AppColors.inputFill
        : filled
            ? AppColors.primary
            : Colors.white;
    final foregroundColor = disabled
        ? Colors.grey.shade500
        : filled
            ? Colors.white
            : AppColors.textPrimary;
    final borderColor = filled
        ? Colors.transparent
        : disabled
            ? AppColors.divider
            : AppColors.primary;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: filled ? 0 : 0,
          side: BorderSide(color: borderColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
