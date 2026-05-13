import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SosButton extends StatefulWidget {
  final VoidCallback onTriggered;
  const SosButton({super.key, required this.onTriggered});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _longPressTimer;
  bool _isPressing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isPressing = true);
    _longPressTimer = Timer(const Duration(seconds: 3), () {
      widget.onTriggered();
      _cancelTimer();
    });
  }

  void _cancelTimer() {
    setState(() => _isPressing = false);
    _longPressTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startTimer(),
      onLongPressEnd: (_) => _cancelTimer(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Elegant Pulse Outer
          ...List.generate(2, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final progress = (_pulseController.value + (index * 0.5)) % 1.0;
                return Container(
                  width: 100 + (progress * 80),
                  height: 100 + (progress * 80),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryOrange.withOpacity(0.1 * (1 - progress)),
                  ),
                );
              },
            );
          }),
          
          // Main Button Style
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isPressing ? 120 : 130,
            height: _isPressing ? 120 : 130,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryOrange,
                  AppColors.primaryOrange.withBlue(20),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emergency_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'SOS',
                    style: AppTypography.heading2.copyWith(
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
