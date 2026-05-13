import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/language_provider.dart';
import '../features/chat/chat_provider.dart';
import '../features/cases/providers/case_provider.dart';
import '../features/feed/news_provider.dart';
import '../providers/user_provider.dart';
import '../providers/metrics_provider.dart';
import '../services/socket_service.dart';
import '../services/geo_location_service.dart';
import '../Shared/theme/app_theme.dart';
import 'routes.dart';

class HavenlyApp extends StatelessWidget {
  const HavenlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
            create: (_) => LanguageProvider()..loadSavedLanguage()),
        ChangeNotifierProvider(create: (_) => UserProvider()..bootSession()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()..loadPosts()),
        ChangeNotifierProvider(create: (_) => CaseProvider()..loadCases()),
        ChangeNotifierProvider(create: (_) => MetricsProvider()),
        ChangeNotifierProvider(create: (_) => GeoLocationService()),
        ChangeNotifierProvider(create: (_) => SocketService()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, lang, _) {
          return MaterialApp(
            title: 'Havenly Solutions',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
            locale: Locale(lang.currentLanguage),
          );
        },
      ),
    );
  }
}
