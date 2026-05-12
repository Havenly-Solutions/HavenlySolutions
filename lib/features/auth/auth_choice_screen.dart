import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/language_provider.dart';
import '../../core/constants/translations.dart';
import '../../core/widgets/app_background.dart';
import '../../app/routes.dart';

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
      Navigator.pushNamed(context, AppRoutes.pin);
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

  void _showGuestWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppTranslations.t('guest_warning_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppTranslations.t('guest_warning_body'),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.t('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.terms);
            },
            child: Text(AppTranslations.t('confirm'), style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return AppBackground(
      headerTitle: 'Havenly Solutions',
      headerSubtitle: 'Your Haven. Your Community. Always on.',
      cardHeightFactor: 0.6,
      isCleanMode: false, // Use Mountain Background
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Spacer(),
            Text(
              AppTranslations.t('auth_choice_title'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppTranslations.t('auth_choice_sub'),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (!_hasAccount) ...[
              _AuthButton(
                label: AppTranslations.t('sign_up'),
                filled: true,
                onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
              ),
              const SizedBox(height: 16),
            ],
            _AuthButton(
              label: AppTranslations.t('login'),
              filled: _hasAccount,
              disabled: !_hasAccount,
              onTap: _hasAccount ? () => Navigator.pushNamed(context, AppRoutes.pin) : null,
            ),
            if (_hasAccount && _biometricAvailable && !_checkingBiometric) ...[
              const SizedBox(height: 16),
              _AuthButton(
                label: AppTranslations.t('use_biometric'),
                filled: false,
                icon: Icons.fingerprint,
                onTap: _loginWithBiometric,
              ),
            ],
            const SizedBox(height: 16),
            _AuthButton(
              label: AppTranslations.t('guest_mode'),
              filled: false,
              onTap: _showGuestWarning,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool disabled;
  final IconData? icon;
  final VoidCallback? onTap;

  const _AuthButton({
    required this.label,
    required this.filled,
    this.disabled = false,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? Colors.black : Colors.white,
          foregroundColor: filled ? Colors.white : Colors.black,
          disabledBackgroundColor: Colors.grey.shade100,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: filled ? BorderSide.none : BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
