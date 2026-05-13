import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/app_background.dart';
import '../../Shared/theme/app_theme.dart';

class EmergencyNumbersScreen extends StatelessWidget {
  const EmergencyNumbersScreen({super.key});

  Future<void> _call(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch dialer for $number');
    }
  }

  @override
  Widget build(BuildContext context) {
    final numbers = [
      {'name': 'Police (SAPS)', 'number': '10111'},
      {'name': 'Ambulance', 'number': '10177'},
      {'name': 'Emergency (Cell Phone)', 'number': '112'},
      {'name': 'Fire Department', 'number': '10177'},
      {'name': 'Childline South Africa', 'number': '0800055555'},
      {'name': 'Poison Information Centre', 'number': '0861555777'},
    ];

    return AppBackground(
      headerTitle: 'Emergency Numbers',
      headerSubtitle: 'Havenly Solutions',
      showBackButton: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        itemCount: numbers.length,
        itemBuilder: (context, index) {
          final n = numbers[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              title: Text(
                n['name']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Space Grotesk',
                  color: Color(0xFF1A1A2E), // Fix A: High visibility Deep Navy
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  n['number']!,
                  style: const TextStyle(
                    color:
                        Color(0xFF1A1A2E), // Fix A: High visibility Deep Navy
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              trailing: GestureDetector(
                onTap: () => _call(n['number']!),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 22),
                ),
              ),
              onTap: () =>
                  _call(n['number']!), // Fix B: Enable tap-to-dial on tile
            ),
          );
        },
      ),
    );
  }
}
