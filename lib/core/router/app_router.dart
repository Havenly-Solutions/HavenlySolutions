import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/language/language_selection_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/pin/pin_creation_screen.dart';
import '../../features/pin/pin_login_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/guided_tour_screen.dart';
import '../../features/home/main_navigation_screen.dart';
import '../../features/profile/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/language',
        name: 'language',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/pin-login',
        name: 'pinLogin',
        builder: (context, state) => const PinLoginScreen(),
      ),
      GoRoute(
        path: '/pin-creation',
        name: 'pinCreation',
        builder: (context, state) => const PinCreationScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/tour',
        name: 'onboardingTour',
        builder: (context, state) => const GuidedTourScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/emergency',
        name: 'emergency',
        builder: (context, state) {
          // Emergency mode screen - placeholder
          return const Placeholder();
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
