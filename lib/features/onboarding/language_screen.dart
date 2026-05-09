// First screen new users see after splash — language selection

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/language_provider.dart';
import '../../core/constants/translations.dart';
import '../../app/routes.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'en';

  Future<void> _confirm() async {
    await context.read<LanguageProvider>().setLanguage(_selected);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_language', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                AppTranslations.t('choose_language'),
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppTranslations.t('choose_language_sub'),
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: AppTranslations.languageNames.entries.map((entry) {
                    final code = entry.key;
                    final name = entry.value;
                    final isSelected = _selected == code;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = code),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00BCD4).withOpacity(0.12)
                              : Color(0xFFF5F5F5),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00BCD4)
                                : Color(0xFFE0E0E0),
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: isSelected
                                    ? Color(0xFF000000)
                                    : Color(0xFF616161),
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF00BCD4),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppTranslations.t('continue_btn'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}