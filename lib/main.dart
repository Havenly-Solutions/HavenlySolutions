import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/constants/translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('app_language') ?? 'en';
  AppTranslations.setLanguage(savedLang);

  runApp(const HavenlySolutionsApp());
}