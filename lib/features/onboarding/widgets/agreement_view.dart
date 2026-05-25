import 'package:flutter/material.dart';

class AgreementView extends StatefulWidget {
  final VoidCallback onAccept;
  const AgreementView({super.key, required this.onAccept});

  @override
  State<AgreementView> createState() => _AgreementViewState();
}

class _AgreementViewState extends State<AgreementView> {
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _agreedToGuidelines = false;

  bool get _canProceed =>
      _agreedToTerms && _agreedToPrivacy && _agreedToGuidelines;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('User Agreements',
            style: TextStyle(
                color: Color(0xFF1A3D3D),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Final Step',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A3D3D),
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            const Text('Terms & Standards',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3D3D))),
            const SizedBox(height: 12),
            Text(
              'Please review and accept our legal agreements to activate your Havenly Solutions protection.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 32),
            _buildAgreementCard(
              'Terms of Service',
              'Legal guidelines regarding your use of the Havenly Solutions platform.',
              _agreedToTerms,
              (val) => setState(() => _agreedToTerms = val ?? false),
            ),
            const SizedBox(height: 16),
            _buildAgreementCard(
              'Privacy Policy',
              'How we collect, encrypt and protect your personal safety data.',
              _agreedToPrivacy,
              (val) => setState(() => _agreedToPrivacy = val ?? false),
            ),
            const SizedBox(height: 16),
            _buildAgreementCard(
              'User Guidelines',
              'Critical rules on preventing false alarms and proper SOS usage.',
              _agreedToGuidelines,
              (val) => setState(() => _agreedToGuidelines = val ?? false),
            ),
            const SizedBox(height: 48),
            const Text('COMMUNITY SAFETY RULES',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey,
                    letterSpacing: 1)),
            const SizedBox(height: 16),
            _buildRuleItem(Icons.warning_amber_rounded, 'No False Triggers',
                'Intentional false alarms may lead to account suspension.'),
            _buildRuleItem(null, 'Accurate Info',
                'Ensure your profile data is always current for emergency services.',
                logo: true),
            const SizedBox(height: 64),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _canProceed ? widget.onAccept : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003333),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: const Text(
                  'ACCEPT & ACTIVATE',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementCard(String title, String subtitle, bool value,
      ValueChanged<bool?> onChanged) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: value ? const Color(0xFF003333) : Colors.grey[200]!,
            width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A3D3D))),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF003333),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: const Row(
              children: [
                Text('Read Document',
                    style: TextStyle(
                        color: Color(0xFF003333),
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Icon(Icons.open_in_new, size: 14, color: Color(0xFF003333)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(IconData? icon, String title, String body,
      {bool logo = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (logo)
            Image.asset('assets/images/logo.png', width: 18, height: 18)
          else
            Icon(icon, size: 18, color: Colors.orange[800]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
