import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/language_provider.dart';
import '../core/constants/translations.dart';
import '../core/providers/auth_provider.dart';
import '../shared/theme/app_theme.dart';
import 'routes.dart';

class HavenlySolutionsApp extends StatelessWidget {
  const HavenlySolutionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Havenly Solutions',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
