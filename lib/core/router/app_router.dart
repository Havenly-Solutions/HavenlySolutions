import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/language/language_screen.dart';
import '../../features/auth/account_creation_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/models/signup_data.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/biometric_scan_screen.dart';
import '../../features/pin/pin_creation_screen.dart';
import '../../features/pin/pin_login_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/guided_tour_screen.dart';
import '../../features/home/main_navigation_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/pin_management_screen.dart';
import '../../features/news/missing_person_post_screen.dart';
import '../../features/guest/guest_portal_screen.dart';
import '../../features/guest/guest_sos_screen.dart';
import '../../features/auth/guest_auth_screen.dart';
import '../providers/auth_state_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Allow specific critical paths during guest/unauthenticated state
      if (state.matchedLocation == '/' ||
          state.matchedLocation == '/language' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/auth' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/login') {
        return null;
      }

      // Handle guest route redirects
      if (authState == AuthState.guest) {
        // Guest user can see home/feed but not private sections
        if (state.matchedLocation == '/profile' ||
            state.matchedLocation == '/pin-setup' ||
            state.matchedLocation == '/account-creation') {
          return '/guest';
        }
      }

      // Registered user shouldn't see guest portal
      if (authState == AuthState.authenticated) {
        if (state.matchedLocation == '/guest' ||
            state.matchedLocation == '/guest/sos') {
          return '/home';
        }
      }

      return null; // No redirect
    },
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
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/guest-auth',
        name: 'guestAuth',
        builder: (context, state) => const GuestAuthScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/biometric-scan',
        name: 'biometricScan',
        builder: (context, state) => const BiometricScanScreen(),
      ),
      GoRoute(
        path: '/account-creation',
        name: 'accountCreation',
        builder: (context, state) {
          final signupData =
              state.extra is SignupData ? state.extra as SignupData : null;
          return AccountCreationScreen(signupData: signupData);
        },
      ),
      GoRoute(
        path: '/pin-entry',
        name: 'pinEntry',
        builder: (context, state) => const PINLoginScreen(),
      ),
      GoRoute(
        path: '/pin-setup',
        name: 'pinSetup',
        builder: (context, state) => const PINCreationScreen(),
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
        routes: [
          GoRoute(
            path: 'edit',
            name: 'editProfile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'pin',
            name: 'pinManagement',
            builder: (context, state) => const PINManagementScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/feed/missing-person/post',
        name: 'missingPersonPost',
        builder: (context, state) => const MissingPersonPostScreen(),
      ),
      // Guest routes
      GoRoute(
        path: '/guest',
        name: 'guestPortal',
        builder: (context, state) => const GuestPortalScreen(),
      ),
      GoRoute(
        path: '/guest/sos',
        name: 'guestSos',
        builder: (context, state) => const GuestSosScreen(),
      ),
    ],
  );
});
