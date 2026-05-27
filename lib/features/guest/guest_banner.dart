import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Guest banner shown at top of guest portal screens
/// Displays:
/// - "You're browsing as a guest" message
/// - Sign Up button
/// - Log In button
class GuestBanner extends StatelessWidget {
  const GuestBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Guest status message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re browsing as a guest',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Create an account for full access',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Action buttons
          Row(
            children: [
              // Sign Up button
              TextButton(
                onPressed: () => context.push('/signup'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.amber.shade100,
                ),
                child: Text(
                  'Sign Up',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              // Log In button
              TextButton(
                onPressed: () => context.push('/login'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  'Log In',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
