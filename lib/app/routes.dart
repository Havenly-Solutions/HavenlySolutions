import 'package:flutter/material.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/language_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/terms_screen.dart';
import '../features/onboarding/privacy_screen.dart';
import '../features/onboarding/standards_screen.dart';
import '../features/auth/auth_choice_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/pin_screen.dart';
import '../features/auth/forgot_pin_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/sos/sos_active_screen.dart';
import '../features/home/emergency_numbers_screen.dart';


class AppRoutes {
  static const splash     = '/';
  static const language   = '/language';
  static const auth       = '/auth';
  static const signup     = '/signup';
  static const forgotPin  = '/forgot_pin';
  static const onboarding = '/onboarding';
  static const pin        = '/pin';
  static const home       = '/home';
  static const profile    = '/profile';
  static const terms      = '/terms';
  static const privacy    = '/privacy';
  static const standards  = '/standards';
  static const sosActive  = '/sos_active';
  static const emergencyNumbers = '/emergency_numbers';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    language: (_) => const LanguageScreen(),
    auth: (_) => const AuthChoiceScreen(),
    signup: (_) => const SignupScreen(),
    forgotPin: (_) => const ForgotPinScreen(),
    onboarding: (_) => const OnboardingScreen(),
    pin: (_) => const PinScreen(),
    home: (_) => const HomeScreen(),
    profile: (_) => const ProfileScreen(),
    terms: (_) => const TermsScreen(),
    privacy: (_) => const PrivacyScreen(),
    standards: (_) => const StandardsScreen(),
    sosActive: (_) => const SosActiveScreen(),
    emergencyNumbers: (_) => const EmergencyNumbersScreen(),
  };
}
