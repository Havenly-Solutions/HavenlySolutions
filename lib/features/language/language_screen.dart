import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/constants/translations.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  late String _selectedLanguageCode;

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'Afrikaans', 'code': 'af'},
    {'name': 'isiNdebele', 'code': 'nr'},
    {'name': 'isiXhosa', 'code': 'xh'},
    {'name': 'isiZulu', 'code': 'zu'},
    {'name': 'Sepedi', 'code': 'nso'},
    {'name': 'Sesotho', 'code': 'st'},
    {'name': 'Setswana', 'code': 'tn'},
    {'name': 'siSwati', 'code': 'ss'},
    {'name': 'Tshivenda', 'code': 've'},
    {'name': 'Xitsonga', 'code': 'ts'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedLanguageCode = ref.read(localeProvider).languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 20, height: 20),
            const SizedBox(width: 8),
            Text(AppTranslations.t('app_name'), style: AppTypography.heading2.copyWith(fontSize: 18, color: const Color(0xFF003333))),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            AppTranslations.t('choose_language'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003333)),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.t('choose_language_sub'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _languages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected = _selectedLanguageCode == lang['code'];
                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedLanguageCode = lang['code']!;
                    });
                    // Instant system-wide feedback
                    AppTranslations.setLanguage(_selectedLanguageCode);
                    await ref.read(localeProvider.notifier).setLocale(_selectedLanguageCode);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF003333) : Colors.grey[200]!,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lang['name']!,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF003333) : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Color(0xFF003333), size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
            ),
            child: ElevatedButton(
              onPressed: () async {
                await SecureStorageService.setOnboarded(true);
                if (mounted) {
                  context.go('/auth');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003333),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppTranslations.t('continue_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
