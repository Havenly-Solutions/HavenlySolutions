import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/language_provider.dart';
import '../core/providers/auth_provider.dart';
import '../features/feed/feed_provider.dart';
import '../features/chat/chat_provider.dart';
import '../features/cases/case_provider.dart';
import '../providers/metrics_provider.dart';
import '../providers/user_provider.dart';
import '../services/socket_service.dart';
import '../Shared/theme/app_theme.dart';
import 'routes.dart';

class HavenlySolutionsApp extends StatefulWidget {
  final String initialRoute;

  const HavenlySolutionsApp({
    super.key,
    required this.initialRoute,
  });

  @override
  State<HavenlySolutionsApp> createState() => _HavenlySolutionsAppState();
}

class _HavenlySolutionsAppState extends State<HavenlySolutionsApp> {
  final UserProvider _userProvider = UserProvider();

  @override
  void initState() {
    super.initState();
    _userProvider.bootSession();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CaseProvider()),
        ChangeNotifierProvider(create: (_) => MetricsProvider()),
        ChangeNotifierProvider(create: (_) => SocketService.instance),
        ChangeNotifierProvider.value(value: _userProvider),
      ],
      child: Consumer2<LanguageProvider, UserProvider>(
        builder: (context, languageProvider, userProvider, child) {
          // Determine initial route.
          // In development, the database might be wiped on start, so we 
          // default to the splash screen provided by main.dart.
          String startRoute = widget.initialRoute;

          // If the provider has established a user, we can skip to home.
          // But we don't force a rebuild via a Key because that causes 
          // the UI to reset (the issue you reported).
          if (userProvider.isAuthenticated && !userProvider.isLoading) {
            startRoute = AppRoutes.home;
          }

          final routes = AppRoutes.routes;
          if (!routes.containsKey(startRoute)) {
            startRoute = AppRoutes.splash;
          }

          return MaterialApp(
            title: 'Havenly Solutions',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            initialRoute: startRoute,
            routes: routes,
          );
        },
      ),
    );
  }
}
