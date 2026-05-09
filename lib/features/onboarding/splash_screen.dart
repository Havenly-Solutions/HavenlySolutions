import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/constants/translations.dart';
import '../../app/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _textController;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/GBV.png'), context);
    });

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Welcome text fades in after 500ms delay
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    // Start animation after 500ms delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  Future<void> _route() async {
    try {
      if (!mounted) return;

      //load language into Provider
      await context.read<LanguageProvider>().loadSavedLanguage();
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final seenLanguage = prefs.getBool('seen_language') ?? false;
      final auth = context.read<AuthProvider>();
      await auth.tryAutoLogin();
      if (!mounted) return;

      if (!seenLanguage) {
        Navigator.pushReplacementNamed(context, AppRoutes.language);
      } else if (auth.isLoggedIn) {
        Navigator.pushReplacementNamed(context, AppRoutes.pin);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.auth);
      }
    } catch (e) {
      debugPrint('Error in splash screen routing: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with cover fit
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.9),
                BlendMode.lighten,
              ),
              child: Image.asset(
                'assets/images/GBV.png',
                fit: BoxFit.cover,
                cacheWidth: 800,
              ),
            ),
            
            // Light overlay
            Container(
              color: Colors.white.withOpacity(0.7),
            ),

          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome text with fade animation
              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    const Text(
                      'Havenly Solutions',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your Haven. Your Community. Always On.',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Slide to begin widget at bottom
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _SlideToBeginWidget(
              onSlideComplete: _route,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SlideToBeginWidget extends StatefulWidget {
  final VoidCallback onSlideComplete;

  const _SlideToBeginWidget({required this.onSlideComplete});

  @override
  State<_SlideToBeginWidget> createState() => _SlideToBeginWidgetState();
}

class _SlideToBeginWidgetState extends State<_SlideToBeginWidget> {
  double _dragOffset = 0.0;
  late double _maxDragDistance;
  bool _completed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maxDragDistance = MediaQuery.of(context).size.width - 60 - 60; // width - left/right padding - thumb width
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_completed) return;

    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, _maxDragDistance);
    });

    // Check if slider has reached the end
    if (_dragOffset >= _maxDragDistance * 0.9) {
      _complete();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_completed) return;

    // Snap back if not completed
    if (_dragOffset < _maxDragDistance * 0.9) {
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  void _complete() {
    setState(() {
      _completed = true;
      _dragOffset = _maxDragDistance;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      widget.onSlideComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Track background
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5), // Light track
              borderRadius: BorderRadius.circular(25),
            ),
          ),

          // Center text
          Center(
            child: Text(
              'Slide to Begin',
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Draggable thumb
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Container(
              height: 50,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4), // Teal thumb
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}