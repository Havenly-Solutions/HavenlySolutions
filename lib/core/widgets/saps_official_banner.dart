import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SapsOfficialBanner extends StatelessWidget {
  const SapsOfficialBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8), // Very light blue/grey bg
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
      ),
      child: Stack(
        children: [
          // Background Watermark (Police officer placeholder or fade)
          Positioned(
            right: 80,
            top: -10,
            bottom: -10,
            child: Opacity(
              opacity: 0.05,
              child: SvgPicture.asset(
                'assets/images/saps_logo.svg',
                width: 100,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Left: SAPS Logo
                SvgPicture.asset(
                  'assets/images/saps_logo.svg',
                  height: 60,
                ),
                const SizedBox(width: 16),
                // Center: Text
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOUTH AFRICAN POLICE SERVICE',
                        style: TextStyle(
                          color: Color(0xFF002366),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Department of Police',
                        style: TextStyle(
                          color: Color(0xFF002366),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right: SA Flag
                Container(
                  width: 60,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/sa_flag.png',
                    fit: BoxFit.cover,
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
