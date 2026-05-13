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
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/emergency_contacts_screen.dart';
import '../features/feed/news_screen.dart';
import '../features/support/ui/leader_support_chat_screen.dart';
import '../features/feed/ui/nationwide_feed_screen.dart';
import '../features/sos/sos_active_screen.dart';
import '../features/home/emergency_numbers_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/cases/cases_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const language = '/language';
  static const auth = '/auth';
  static const signup = '/signup';
  static const forgotPin = '/forgot_pin';
  static const onboarding = '/onboarding';
  static const pin = '/pin';
  static const home = '/home';
  static const profile = '/profile';
  static const editProfile = '/edit_profile';
  static const emergencyContacts = '/emergency_contacts';
  static const news = '/news';
  static const chat = '/chat';
  static const cases = '/cases';
  static const nationwideFeed = '/nationwide_feed';
  static const leaderSupportChat = '/leader_support_chat';
  static const terms = '/terms';
  static const privacy = '/privacy';
  static const standards = '/standards';
  static const sosActive = '/sos_active';
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
        editProfile: (_) => const EditProfileScreen(),
        emergencyContacts: (_) => const EmergencyContactsScreen(),
        news: (_) => const NewsScreen(),
        chat: (_) => const ChatScreen(),
        cases: (_) => const CasesScreen(),
        nationwideFeed: (_) => const NationwideFeedScreen(),
        leaderSupportChat: (_) => const LeaderSupportChatScreen(),
        terms: (_) => const TermsScreen(),
        privacy: (_) => const PrivacyScreen(),
        standards: (_) => const StandardsScreen(),
        sosActive: (_) => const SosActiveScreen(),
        emergencyNumbers: (_) => const EmergencyNumbersScreen(),
      };
}
