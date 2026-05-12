import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/translations.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to 'en' if not set
    _currentLanguage = prefs.getString('app_language') ?? 'en';
    AppTranslations.setLanguage(_currentLanguage);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _currentLanguage = code;
    AppTranslations.setLanguage(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
    notifyListeners();
  }

  // Reset to English for new user scenarios
  Future<void> resetToDefault() async {
    _currentLanguage = 'en';
    AppTranslations.setLanguage('en');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', 'en');
    notifyListeners();
  }
}
