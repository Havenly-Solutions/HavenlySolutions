// Login (grayed if no account), Sign Up, Guest

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/language_provider.dart';
import '../../core/constants/translations.dart';
import '../../app/routes.dart';

class AuthChoiceScreen extends StatefulWidget {
  const AuthChoiceScreen({super.key});

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen> {
  bool _hasAccount = false;

  @override
  void initState() {
    super.initState();
    _checkExistingAccount();
  }

  Future<void> _checkExistingAccount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasAccount = prefs.getBool('has_account') ?? false;
    });
  }

  void _showGuestWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        title: Text(
          AppTranslations.t('guest_warning_title'),
          style: const TextStyle(
            color: Color(0xFF000000),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppTranslations.t('guest_warning_body'),
          style: TextStyle(color: Color(0xFF616161), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.t('cancel'),
              style: TextStyle(color: Color(0xFF757575)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
            },
            child: Text(
              AppTranslations.t('guest_warning_confirm'),
              style: const TextStyle(color: Color(0xFF00BCD4)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image (top 55%)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/auth_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // White card sliding up from bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      // Logo mark
                      const Center(
                        child: Icon(
                          Icons.shield,
                          color: Color(0xFF00BCD4),
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: Text(
                          AppTranslations.t('auth_choice_title'),
                          style: const TextStyle(
                            color: Color(0xFF000000),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          AppTranslations.t('auth_choice_sub'),
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Spacer(),
                      // Sign Up — always active
                      _AuthButton(
                        label: AppTranslations.t('sign_up'),
                        filled: true,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.signup),
                      ),
                      const SizedBox(height: 14),
                      // Login — grayed out if no account
                      _AuthButton(
                        label: AppTranslations.t('login'),
                        filled: false,
                        disabled: !_hasAccount,
                        disabledHint: AppTranslations.t('login_disabled'),
                        onTap: _hasAccount
                            ? () => Navigator.pushNamed(context, AppRoutes.pin)
                            : null,
                      ),
                      const SizedBox(height: 14),
                      // Guest
                      _AuthButton(
                        label: AppTranslations.t('guest_mode'),
                        filled: false,
                        ghost: true,
                        onTap: _showGuestWarning,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool disabled;
  final bool ghost;
  final String? disabledHint;
  final VoidCallback? onTap;

  const _AuthButton({
    required this.label,
    required this.filled,
    this.disabled = false,
    this.ghost = false,
    this.disabledHint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled
          ? () {
              if (disabledHint != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(disabledHint!),
                    backgroundColor: Color(0xFFF5F5F5),
                  ),
                );
              }
            }
          : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: disabled
              ? Color(0xFFF5F5F5)
              : filled
                  ? const Color(0xFF00BCD4)
                  : Colors.white,
          border: Border.all(
            color: disabled
                ? Color(0xFFE0E0E0)
                : ghost
                    ? Color(0xFF9E9E9E)
                    : const Color(0xFF00BCD4),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: disabled
                ? Color(0xFF9E9E9E)
                : filled
                    ? Colors.white
                    : ghost
                        ? Color(0xFF616161)
                        : const Color(0xFF00BCD4),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}