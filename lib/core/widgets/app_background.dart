import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final String? headerTitle;
  final String? headerSubtitle;
  final double cardHeightFactor;
  final bool showBackButton;

  const AppBackground({
    super.key,
    required this.child,
    this.headerTitle,
    this.headerSubtitle,
    this.cardHeightFactor = 0.65,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/mountain top view.png',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Header Content
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  if (showBackButton)
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      ),
                    ),
                  const SizedBox(height: 40),
                  if (headerTitle != null)
                    Text(
                      headerTitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (headerSubtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      headerSubtitle!,
                      style: const TextStyle(
                        color: Color(0xFFFF9800), // Orange accent like "Evernotes"
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // White Bottom Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: screenHeight * cardHeightFactor,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
