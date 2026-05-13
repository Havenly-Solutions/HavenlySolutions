import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SapsBadge extends StatelessWidget {
  const SapsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/images/saps_logo.svg',
            height: 16,
            colorFilter: const ColorFilter.mode(
              Color(0xFF002366),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'SAPS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF002366),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
