import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Guest upgrade CTA widget
/// Shows a feature as locked with blurred/dimmed preview
/// Displayed on locked tabs (Chat, Profile) when guest user views them
class GuestUpgradeCta extends StatelessWidget {
  final String featureName;
  final String featureIcon;
  final String description;
  final Widget? preview;

  const GuestUpgradeCta({
    super.key,
    required this.featureName,
    required this.featureIcon,
    required this.description,
    this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dimmed/blurred preview (optional)
        if (preview != null)
          Opacity(
            opacity: 0.3,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.grey.shade300,
                BlendMode.lighten,
              ),
              child: preview!,
            ),
          ),

        // Center CTA overlay
        Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Feature icon (simple text emoji or icon)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: Center(
                    child: Text(
                      featureIcon,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Feature name
                Text(
                  'Unlock $featureName',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // Sign Up button (primary)
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => context.push('/signup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Sign Up Free',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Log In link (secondary)
                GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Text(
                    'Already have an account? Log In',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.blue.shade600,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
