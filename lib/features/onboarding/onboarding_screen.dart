import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/agreement_view.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showAgreement = false;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Rapid Emergency Dispatch',
      body: 'Hold the central SOS button for 3 seconds to alert emergency services and your community instantly.',
      image: 'assets/images/stay_safe.png',
    ),
    OnboardingSlide(
      title: 'Real-Time Community Safety',
      body: 'Stay informed with live alerts and moderated safety feeds from your specific neighbourhood precinct.',
      image: 'assets/images/gbv.png',
    ),
    OnboardingSlide(
      title: 'Reliable Connectivity',
      body: 'Your safety never goes offline. We use GPS, Bluetooth mesh, and direct SMS to keep you protected.',
      image: 'assets/images/blurry.png',
    ),
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      setState(() => _showAgreement = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showAgreement) {
      return AgreementView(
        onAccept: () => context.go('/home'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(image: AssetImage(slide.image), fit: BoxFit.cover),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.white.withOpacity(0.8), Colors.white],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A3D3D), letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? const Color(0xFF003333) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003333),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'GET STARTED' : 'NEXT',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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

class OnboardingSlide {
  final String title;
  final String body;
  final String image;
  OnboardingSlide({required this.title, required this.body, required this.image});
}
