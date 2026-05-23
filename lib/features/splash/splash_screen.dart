import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/storage_service.dart';

/// Splash Screen
///
/// Spec:
/// - Background: stay_safe.png (full bleed, BoxFit.cover)
/// - Content: Havenly Solutions logo + tagline + animated progress bar
/// - Duration: 2.5 seconds
///
/// Routing logic:
/// - If (first launch) → Language Selection
/// - If (returning user + PIN set) → PIN Screen
/// - If (returning user + no PIN) → Auth Screen
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _progressController.forward().then((_) {
      _handleNavigation();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation() async {
    if (!mounted) return;

    try {
      // Check if user has completed onboarding
      final onboarded = await _storage.hasKey('onboarded');

      if (!onboarded) {
        // First launch → Language Selection
        if (mounted) {
          context.go('/language');
        }
      } else {
        // Returning user — check PIN status
        final pinSet = await _storage.hasKey('pin_set');

        if (mounted) {
          if (pinSet) {
            // PIN set → PIN Login Screen
            context.go('/pin-login');
          } else {
            // No PIN → Auth Screen
            context.go('/auth');
          }
        }
      }
    } catch (e) {
      debugPrint('[SplashScreen] Navigation error: $e');
      // Fallback to language selection on error
      if (mounted) {
        context.go('/language');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (stay_safe.png)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/stay_safe.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Semi-transparent overlay for text legibility
          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo + Tagline
              Center(
                child: Column(
                  children: [
                    // Havenly logo
                    Text(
                      'Havenly Solutions',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your Haven. Your Community. Always On.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress bar at bottom
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          minHeight: 4,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.emergency,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Initializing...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.6),
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
