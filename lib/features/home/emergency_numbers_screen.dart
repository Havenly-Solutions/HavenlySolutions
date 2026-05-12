import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/translations.dart';
import '../../core/widgets/app_background.dart';

class EmergencyNumbersScreen extends StatelessWidget {
  const EmergencyNumbersScreen({super.key});

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
      headerSubtitle: AppTranslations.t('app_name'),
      showBackButton: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(32),
        itemCount: numbers.length,
        itemBuilder: (context, index) {
          final n = numbers[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(n['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(n['number']!, style: TextStyle(color: Colors.grey.shade600)),
              trailing: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                child: const Icon(Icons.phone, color: Colors.white, size: 20),
              ),
              onTap: () => _call(n['number']!),
            ),
          );
        },
      ),
    );
  }
}
