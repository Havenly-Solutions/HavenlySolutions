import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/routes.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _agreed = false;
  final TextEditingController _controller = TextEditingController();
  bool _canContinue = false;

  void _validate() {
    setState(() {
      _canContinue = _agreed && _controller.text.trim() == 'I AGREE';
    });
  }

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_accepted', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.standards);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: const Text(
                'PRIVACY POLICY\n'
                'Last Updated: April 30, 2026\n'
                'POPIA Compliant\n\n'
                '1. INTRODUCTION\n'
                'Welcome to Havenly Solutions. We respect your privacy and are committed to protecting your personal data in compliance with the Protection of Personal Information Act (POPIA) of South Africa.\n\n'
                '2. DATA WE COLLECT\n'
                'We may collect, use, store and transfer different kinds of personal data about you, including:\n'
                '- Identity Data: Name, ID number for verification, and biometrics (optional).\n'
                '- Contact Data: Email address and telephone numbers.\n'
                '- Technical Data: IP address, login data, browser type, and location data.\n'
                '- SOS Data: Real time location, ambient audio recordings, and incident metadata.\n\n'
                '3. HOW WE USE YOUR DATA\n'
                'We use your data primarily to provide emergency response services. This includes:\n'
                '- Dispatching community responders to your exact location.\n'
                '- Generating Evidence Chain logs for legal proceedings.\n'
                '- Operating the Guardian Mesh Network for offline signal relay.\n\n'
                '4. DATA SHARING AND THIRD PARTIES\n'
                'We only share your personal data with:\n'
                '- Verified Security Partners during an active SOS.\n'
                '- Law Enforcement Agencies only via valid Evidence Chain request.\n'
                '- NGO Partners (anonymized for research and support purposes).\n\n'
                '5. THE GUARDIAN MESH ENCRYPTION\n'
                'When participating in the mesh network, your device acts as a relay. All relayed packets are end-to-end encrypted. We cannot see the content of these packets, and neither can the relaying devices. Your identity is never exposed to the network while relaying.\n\n'
                '6. DATA SOVEREIGNTY AND STORAGE\n'
                'All Havenly Solutions data is stored on secure, encrypted servers located within the Republic of South Africa to ensure compliance with POPIA and local data residency requirements.\n\n'
                '7. YOUR LEGAL RIGHTS\n'
                'Under POPIA, you have the right to:\n'
                '- Request access to your personal data.\n'
                '- Request correction of your personal data.\n'
                '- Request erasure of your personal data (Right to be forgotten).\n'
                '- Object to processing of your personal data.\n\n'
                '8. CONTACT OUR INFORMATION OFFICER\n'
                'privacy@havenly.solutions',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _agreed,
                        activeColor: Colors.red,
                        onChanged: (val) {
                          setState(() => _agreed = val ?? false);
                          _validate();
                        },
                      ),
                      const Text(
                        'I have read and agree',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    onChanged: (_) => _validate(),
                    decoration: const InputDecoration(
                      hintText: 'Type "I AGREE" to confirm',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _canContinue ? _onContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
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