import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../news/news_feed_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/customer_care_screen.dart';
import '../../core/theme/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const NewsFeedScreen(),
    const ChatScreen(),
    const Placeholder(), // Placeholder for Alerts if needed, using Chat context
    const CustomerCareScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _screens[
              _currentIndex == 3 ? 2 : (_currentIndex > 3 ? 4 : _currentIndex)],
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.grid_view_rounded, 'Home'),
                  _buildNavItem(1, Icons.newspaper_rounded, 'News'),
                  _buildNavItem(2, Icons.chat_bubble_outline_rounded, 'Chat'),
                  _buildNavItem(3, Icons.sensors_rounded, 'Alerts'),
                  _buildNavItem(4, Icons.help_outline_rounded, 'Support'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D4F4F) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
