// Havenly Solutions (Pty) Ltd
// Main home screen with bottom navigation

import 'package:flutter/material.dart';
import '../../core/constants/translations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield, color: Color(0xFF00BCD4), size: 56),
            const SizedBox(height: 20),
            Text(
              AppTranslations.t('home'),
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Home screen — Phase 6',
              style: TextStyle(color: Color(0xFF757575), fontSize: 13),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Color(0xFF000000),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00BCD4),
        unselectedItemColor: Color(0xFF616161),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}