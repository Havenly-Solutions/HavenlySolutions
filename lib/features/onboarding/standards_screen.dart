import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/routes.dart';

class StandardsScreen extends StatefulWidget {
  const StandardsScreen({super.key});

  @override
  State<StandardsScreen> createState() => _StandardsScreenState();
}

class _StandardsScreenState extends State<StandardsScreen> {
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
    await prefs.setBool('seen_standards', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
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
          'Community Standards',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: const Text(
                'COMMUNITY STANDARDS AND WARNINGS\n\n'
                'Havenly Solutions is a platform for genuine safety and community protection. By using this platform you agree to use it honestly and responsibly. The following are strictly prohibited:\n\n'
                '1. FALSE SOS TRIGGERS\n'
                'Triggering a false SOS alert is a criminal offence under South African law. You will be charged for emergency services callout costs and may face criminal prosecution. Havenly Solutions will report all confirmed false SOS triggers to the South African Police Service.\n\n'
                '2. FALSE CASE FILING\n'
                'Filing a false police case — including cases motivated by personal grudges, financial disputes, or revenge — is a criminal offence under South African law. Havenly Solutions conducts verification checks on all filed cases. If a case is found to be false you will face: permanent account suspension, a financial penalty determined by the severity of the false report, and a formal report filed with SAPS. The nature of the false report determines whether the consequence is a financial penalty or criminal prosecution.\n\n'
                '3. MISUSE OF COMMUNITY CHAT\n'
                'Harassment, threats, hate speech, discrimination, or the posting of false information in community chat will result in immediate and permanent account suspension.\n\n'
                '4. MISUSE OF SOS PIN\n'
                'Your 4-digit SOS PIN is personal and confidential. Sharing your PIN with another person or using another person\'s PIN without their consent is a violation of these standards and may result in account suspension.\n\n'
                '5. MINORS\n'
                'Users under the age of 13 are not permitted to use this platform. Users between 13 and 18 must have parental or guardian consent.\n\n'
                'By accepting these standards you confirm that you understand the consequences of misuse and that you will use Havenly Solutions honestly and responsibly at all times.',
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