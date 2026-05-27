import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'guest_banner.dart';
import 'guest_upgrade_cta.dart';
import '../../core/providers/feed_provider.dart';
import '../../core/providers/sos_provider.dart';
import '../../core/models/feed_post.dart';
// For reusing NewsWidget, etc.

/// Guest portal screen
///
/// Main entry point for anonymous users. Provides a preview of Havenly features:
/// ✅ News feed — full read access (no auth required)
/// ✅ SOS button — functional, rate-limited to 3/hour per device
/// 🔒 Chat tab — visible but locked, shows upgrade CTA
/// 🔒 Profile tab — visible but locked, shows upgrade CTA
///
/// Top banner: "You're browsing as a guest | Sign Up | Log In"
/// Bottom nav: News (active) | SOS (with icon) | Chat (locked) | Profile (locked)
class GuestPortalScreen extends ConsumerStatefulWidget {
  const GuestPortalScreen({super.key});

  @override
  ConsumerState<GuestPortalScreen> createState() => _GuestPortalScreenState();
}

class _GuestPortalScreenState extends ConsumerState<GuestPortalScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Havenly Solutions'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Guest banner at top
          const GuestBanner(),

          // Tab content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency),
            label: 'SOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        // News tab - full access, no auth required
        return _buildNewsTab();

      case 1:
        // SOS tab - guest can trigger SOS (rate limited 3/hour)
        return _buildSosTab();

      case 2:
        // Chat tab - locked for guests
        return const GuestUpgradeCta(
          featureName: 'Messaging',
          featureIcon: '💬',
          description: 'Connect with your community and get real-time support.',
        );

      case 3:
        // Profile tab - locked for guests
        return const GuestUpgradeCta(
          featureName: 'Profile',
          featureIcon: '👤',
          description:
              'Create your profile to set up emergency contacts and preferences.',
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNewsTab() {
    final newsState = ref.watch(feedProvider);

    if (newsState.isLoading && newsState.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (newsState.error != null && newsState.posts.isEmpty) {
      return Center(
        child: Text('Error loading news: ${newsState.error}'),
      );
    }

    final newsList = newsState.posts;

    if (newsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.newspaper, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No news yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: newsList.length,
      itemBuilder: (context, index) {
        final item = newsList[index];
        return _buildNewsCard(item);
      },
    );
  }

  Widget _buildNewsCard(FeedPost item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.type == PostType.missingPerson
                  ? 'Missing Person: ${item.mpName}'
                  : 'Update',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              item.body,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSosTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large SOS button
          GestureDetector(
            onTap: () {
              // Trigger SOS
              _triggerSos();
            },
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade600,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emergency_share,
                        size: 64, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      'SOS',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Tap to trigger emergency alert',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Guest limit: 3 per hour',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.orange.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSos() async {
    // Call SOS service to trigger alert
    try {
      await ref.read(sosProvider.notifier).triggerSOS();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency alert sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
