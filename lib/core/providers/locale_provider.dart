import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/secure_storage_service.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'zu': 'isiZulu',
    'xh': 'isiXhosa',
    'af': 'Afrikaans',
    'nso': 'Sepedi (Sesotho sa Leboa)',
    'tn': 'Setswana',
    'st': 'Sesotho',
    'ts': 'Tsonga (Xitsonga)',
    'ss': 'siSwati',
    've': 'Tshivenda',
    'nr': 'isiNdebele',
  };

  static List<String> get supportedLanguageCodes => supportedLanguages.keys.toList();

  Future<void> _loadLocale() async {
    final savedLocale = await SecureStorageService.getLocale();
    if (savedLocale != null) {
      state = Locale(savedLocale);
    }
  }

  Future<void> setLocale(String languageCode) async {
    await SecureStorageService.saveLocale(languageCode);
    state = Locale(languageCode);
  }
}
