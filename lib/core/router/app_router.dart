import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/language/language_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/pin/pin_creation_screen.dart';
import '../../features/pin/pin_login_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/main_navigation_screen.dart';
import '../../features/emergency/emergency_mode_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/customer_care_screen.dart';
import '../../features/chat/chat_detail_screen.dart';
import '../../features/emergency/full_map_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/pin-creation',
      builder: (context, state) => const PINCreationScreen(),
    ),
    GoRoute(
      path: '/pin-login',
      builder: (context, state) => const PINLoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const EmergencyModeScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => const CustomerCareScreen(),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final title = state.uri.queryParameters['title'] ?? 'Direct Message';
        final subtitle = state.uri.queryParameters['subtitle'];
        return ChatDetailScreen(title: title, subtitle: subtitle);
      },
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const FullMapScreen(),
    ),
  ],
);
