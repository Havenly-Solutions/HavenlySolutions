// Havenly Solutions (Pty) Ltd
// 3-slide onboarding — Terms — Privacy — Standards
// User must scroll to bottom + checkbox + type agree word on each legal screen

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/translations.dart';
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
  bool _termsScrolled = false;
  bool _privacyChecked = false;
  bool _privacyScrolled = false;
  bool _standardsChecked = false;
  bool _standardsScrolled = false;
  final _termsAgreeController = TextEditingController();
  final _privacyAgreeController = TextEditingController();
  final _standardsAgreeController = TextEditingController();

  // 0,1,2 = feature slides | 3 = terms | 4 = privacy | 5 = standards
  static const int _totalPages = 6;

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
    Navigator.pushReplacementNamed(context, AppRoutes.home);
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
    if (_page == 3) {
      return _termsChecked &&
          _termsScrolled &&
          _termsAgreeController.text.trim().toUpperCase() ==
              AppTranslations.t('terms_agree_word').toUpperCase();
    }
    if (_page == 4) {
      return _privacyChecked &&
          _privacyScrolled &&
          _privacyAgreeController.text.trim().toUpperCase() ==
              AppTranslations.t('privacy_agree_word').toUpperCase();
    }
    if (_page == 5) {
      return _standardsChecked &&
          _standardsScrolled &&
          _standardsAgreeController.text.trim().toUpperCase() ==
              AppTranslations.t('standards_agree_word').toUpperCase();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _FeatureSlide(
                    title: AppTranslations.t('onboard_1_title'),
                    body: AppTranslations.t('onboard_1_body'),
                    icon: Icons.shield,
                  ),
                  _FeatureSlide(
                    title: AppTranslations.t('onboard_2_title'),
                    body: AppTranslations.t('onboard_2_body'),
                    icon: Icons.people,
                  ),
                  _FeatureSlide(
                    title: AppTranslations.t('onboard_3_title'),
                    body: AppTranslations.t('onboard_3_body'),
                    icon: Icons.folder_open,
                  ),
                  _LegalSlide(
                    title: AppTranslations.t('terms_title'),
                    body: AppTranslations.t('terms_body'),
                    scrollHint: AppTranslations.t('terms_scroll'),
                    checkboxLabel: AppTranslations.t('terms_checkbox'),
                    agreeHint: AppTranslations.t('terms_type_agree'),
                    agreeController: _termsAgreeController,
                    checked: _termsChecked,
                    onChecked: (v) => setState(() => _termsChecked = v ?? false),
                    onScrolled: () => setState(() => _termsScrolled = true),
                  ),
                  _LegalSlide(
                    title: AppTranslations.t('privacy_title'),
                    body: AppTranslations.t('privacy_body'),
                    scrollHint: AppTranslations.t('privacy_scroll'),
                    checkboxLabel: AppTranslations.t('privacy_checkbox'),
                    agreeHint: AppTranslations.t('privacy_type_agree'),
                    agreeController: _privacyAgreeController,
                    checked: _privacyChecked,
                    onChecked: (v) =>
                        setState(() => _privacyChecked = v ?? false),
                    onScrolled: () => setState(() => _privacyScrolled = true),
                  ),
                  _LegalSlide(
                    title: AppTranslations.t('standards_title'),
                    body: AppTranslations.t('standards_body'),
                    scrollHint: AppTranslations.t('standards_scroll'),
                    checkboxLabel: AppTranslations.t('standards_checkbox'),
                    agreeHint: AppTranslations.t('standards_type_agree'),
                    agreeController: _standardsAgreeController,
                    checked: _standardsChecked,
                    onChecked: (v) =>
                        setState(() => _standardsChecked = v ?? false),
                    onScrolled: () =>
                        setState(() => _standardsScrolled = true),
                  ),
                ],
              ),
            ),
            // Dots + button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? const Color(0xFF00BCD4)
                              : Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _canProceed ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        disabledBackgroundColor: Color(0xFFE0E0E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _page >= _totalPages - 1
                            ? AppTranslations.t('done')
                            : AppTranslations.t('next'),
                        style: TextStyle(
                          color: _canProceed
                              ? Colors.white
                              : Color(0xFF9E9E9E),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureSlide extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _FeatureSlide({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 72),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            body,
            style: TextStyle(
              color: Color(0xFF616161),
              fontSize: 15,
              height: 1.6,
            ),
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
  final String scrollHint;
  final String checkboxLabel;
  final String agreeHint;
  final TextEditingController agreeController;
  final bool checked;
  final ValueChanged<bool?> onChecked;
  final VoidCallback onScrolled;

  const _LegalSlide({
    required this.title,
    required this.body,
    required this.scrollHint,
    required this.checkboxLabel,
    required this.agreeHint,
    required this.agreeController,
    required this.checked,
    required this.onChecked,
    required this.onScrolled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            scrollHint,
            style:
                TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (n) {
                if (n.metrics.atEdge && n.metrics.pixels > 0) {
                  onScrolled();
                }
                return false;
              },
              child: SingleChildScrollView(
                child: Text(
                  body,
                  style: TextStyle(
                    color: Color(0xFF616161),
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: onChecked,
                activeColor: const Color(0xFF00BCD4),
                side: BorderSide(color: Color(0xFFBDBDBD)),
              ),
              Expanded(
                child: Text(
                  checkboxLabel,
                  style:
                      TextStyle(color: Color(0xFF616161), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: agreeController,
            style: const TextStyle(color: Color(0xFF000000)),
            onChanged: (_) {},
            decoration: InputDecoration(
              hintText: agreeHint,
              hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
              filled: true,
              fillColor: Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF00BCD4)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}