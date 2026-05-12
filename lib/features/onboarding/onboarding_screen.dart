import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/translations.dart';
import '../../core/providers/language_provider.dart';
import '../../core/widgets/app_background.dart';
import '../../app/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  // Legal acceptance state
  bool _termsChecked = false;
  bool _privacyChecked = false;
  bool _standardsChecked = false;
  final _termsAgreeController = TextEditingController();
  final _privacyAgreeController = TextEditingController();
  final _standardsAgreeController = TextEditingController();

  static const int _totalPages = 9;

  @override
  void dispose() {
    _pageController.dispose();
    _termsAgreeController.dispose();
    _privacyAgreeController.dispose();
    _standardsAgreeController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.pin);
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  bool get _canProceed {
    if (_page == 6) {
      return _termsChecked &&
          _termsAgreeController.text.trim().toUpperCase() == AppTranslations.t('terms_agree_word').toUpperCase();
    }
    if (_page == 7) {
      return _privacyChecked &&
          _privacyAgreeController.text.trim().toUpperCase() == AppTranslations.t('privacy_agree_word').toUpperCase();
    }
    if (_page == 8) {
      return _standardsChecked &&
          _standardsAgreeController.text.trim().toUpperCase() == AppTranslations.t('standards_agree_word').toUpperCase();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return AppBackground(
      headerTitle: 'Havenly Solutions',
      headerSubtitle: 'Your Haven. Your Community. Always on.',
      cardHeightFactor: 0.8,
      isCleanMode: true, // KEEP ONBOARDING IN CLEAN MODE (WHITE BG)
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) => setState(() => _page = p),
              children: [
                _FeatureSlide(
                  title: 'Welcome to Safety',
                  body: 'Your safety is our top priority. Havenly Solutions helps you move through safety tools step by step.',
                  icon: Icons.security_outlined,
                ),
                _FeatureSlide(
                  title: 'Choose Your Language',
                  body: 'Instructions and safety messages are available in your preferred language for better understanding.',
                  icon: Icons.language_outlined,
                ),
                _FeatureSlide(
                  title: 'Create Your Account',
                  body: 'Sign up to access community features and set up your private 4-digit PIN for secure access.',
                  icon: Icons.account_circle_outlined,
                ),
                _FeatureSlide(
                  title: 'Your PIN Matters',
                  body: 'Your PIN protects your safety tools. It ensures only you can manage your emergency settings.',
                  icon: Icons.lock_outline,
                ),
                _FeatureSlide(
                  title: 'Home and SOS',
                  body: 'The Home screen gives you quick access to the SOS button. Hold it only when you need immediate help.',
                  icon: Icons.emergency_outlined,
                ),
                _FeatureSlide(
                  title: 'Stay Connected',
                  body: 'Communicate with your community and stay informed about safety incidents in your area.',
                  icon: Icons.chat_bubble_outline,
                ),
                _LegalSlide(
                  title: AppTranslations.t('terms_title'),
                  body: AppTranslations.t('terms_body'),
                  checkboxLabel: AppTranslations.t('terms_checkbox'),
                  agreeHint: AppTranslations.t('terms_type_agree'),
                  agreeController: _termsAgreeController,
                  checked: _termsChecked,
                  onChecked: (v) => setState(() => _termsChecked = v ?? false),
                  onAgreeChanged: () => setState(() {}),
                ),
                _LegalSlide(
                  title: AppTranslations.t('privacy_title'),
                  body: AppTranslations.t('privacy_body'),
                  checkboxLabel: AppTranslations.t('privacy_checkbox'),
                  agreeHint: AppTranslations.t('privacy_type_agree'),
                  agreeController: _privacyAgreeController,
                  checked: _privacyChecked,
                  onChecked: (v) => setState(() => _privacyChecked = v ?? false),
                  onAgreeChanged: () => setState(() {}),
                ),
                _LegalSlide(
                  title: AppTranslations.t('standards_title'),
                  body: AppTranslations.t('standards_body'),
                  checkboxLabel: AppTranslations.t('standards_checkbox'),
                  agreeHint: AppTranslations.t('standards_type_agree'),
                  agreeController: _standardsAgreeController,
                  checked: _standardsChecked,
                  onChecked: (v) => setState(() => _standardsChecked = v ?? false),
                  onAgreeChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalPages, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? Colors.black : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canProceed ? _next : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _page >= _totalPages - 1 ? AppTranslations.t('done') : AppTranslations.t('next'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureSlide extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  const _FeatureSlide({required this.title, required this.body, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
            child: Icon(icon, size: 64, color: Colors.black),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            body,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LegalSlide extends StatelessWidget {
  final String title;
  final String body;
  final String checkboxLabel;
  final String agreeHint;
  final TextEditingController agreeController;
  final bool checked;
  final ValueChanged<bool?> onChecked;
  final VoidCallback onAgreeChanged;

  const _LegalSlide({
    required this.title,
    required this.body,
    required this.checkboxLabel,
    required this.agreeHint,
    required this.agreeController,
    required this.checked,
    required this.onChecked,
    required this.onAgreeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                child: Text(body, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.6)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(value: checked, onChanged: onChecked, activeColor: Colors.black),
              Expanded(child: Text(checkboxLabel, style: const TextStyle(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: agreeController,
            onChanged: (_) => onAgreeChanged(),
            decoration: InputDecoration(
              hintText: agreeHint,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
