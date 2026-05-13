import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/translations.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

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
                image: DecorationImage(image: AssetImage('assets/images/blurry.png'), fit: BoxFit.cover),
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
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  // Tagline in orange
                  Text(
                    AppTranslations.t('app_tagline'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
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
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppTranslations.t('login'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A3D3D))),
                  const SizedBox(height: 8),
                  Text(AppTranslations.t('welcome_sub'), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 48),
                  
                  _buildInput(Icons.email_outlined, AppTranslations.t('email')),
                  const SizedBox(height: 16),
                  _buildInput(Icons.lock_outline, AppTranslations.t('confirm_pin'), isObscure: true),
                  
                  const SizedBox(height: 40),
                  
                  ElevatedButton(
                    onPressed: () => context.go('/onboarding'), // New user flow: Auth -> Onboarding
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: Text(AppTranslations.t('login'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: RichText(
                      text: TextSpan(
                        text: AppTranslations.t('auth_choice_sub') + " ",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        children: [
                          TextSpan(
                            text: AppTranslations.t('sign_up'),
                            style: const TextStyle(color: Color(0xFF003333), fontWeight: FontWeight.bold),
                          ),
                        ],
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
