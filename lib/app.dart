import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/translations.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/services/offline_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/locale_provider.dart';

class HavenlyApp extends ConsumerWidget {
  const HavenlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    // Listen to connectivity changes and sync pending requests
    ref.listen(connectivityProvider, (_, connectivityStatus) {
      if (connectivityStatus == ConnectivityStatus.online) {
        OfflineSyncService.instance.syncPendingRequests();
      }
    });

    AppTranslations.setLanguage(locale.languageCode);

    return MaterialApp.router(
      title: 'Havenly Solutions',
      theme: AppTheme.lightTheme,
      routerConfig: ref.watch(appRouterProvider),
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        _MaterialLocalizationsFallbackDelegate(),
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zu'),
        Locale('xh'),
        Locale('af'),
        Locale('nso'),
        Locale('tn'),
        Locale('st'),
        Locale('ts'),
        Locale('ss'),
        Locale('ve'),
        Locale('nr'),
      ],
    );
  }
}

class _MaterialLocalizationsFallbackDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLocalizationsFallbackDelegate();

  @override
  bool isSupported(Locale locale) => [
        'zu',
        'xh',
        'nso',
        'tn',
        'st',
        'ts',
        'ss',
        've',
        'nr'
      ].contains(locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // Fallback to English Material strings to prevent crashes for unsupported SA languages
    return GlobalMaterialLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(_MaterialLocalizationsFallbackDelegate old) => false;
}
