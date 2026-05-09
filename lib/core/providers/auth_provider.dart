import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccount = prefs.getBool('has_account') ?? false;
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    _isLoggedIn = hasAccount && seenOnboarding;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    notifyListeners();
  }
}
