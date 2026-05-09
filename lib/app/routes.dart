import 'package:flutter/material.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/language_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/auth_choice_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/pin_screen.dart';
import '../features/home/home_screen.dart';


class AppRoutes {
  static const splash     = '/';
  static const language   = '/language';
  static const auth       = '/auth';
  static const signup     = '/signup';
  static const onboarding = '/onboarding';
  static const pin        = '/pin';
  static const home       = '/home';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    language: (_) => const LanguageScreen(),
    auth: (_) => const AuthChoiceScreen(),
    signup: (_) => const SignupScreen(),
    onboarding: (_) => const OnboardingScreen(),
    pin: (_) => const PinScreen(),
    home: (_) => const HomeScreen(),
  };
}