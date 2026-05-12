import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/routes.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
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
    await prefs.setBool('terms_accepted', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.privacy);
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
          'Terms of Service',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: const Text(
                'AGREEMENT TO OUR LEGAL TERMS\n\n'
                'We are Havenly Solutions (Pty) Ltd, doing business as HS, a company registered in South Africa at 36A Benmore Road, Johannesburg, Gauteng 2010.\n\n'
                'We operate the mobile application Havenly Solutions as well as any other related products and services that refer or link to these legal terms.\n\n'
                'You can contact us by phone at 070 368 7327, email at info@havenly.solutions, or by mail to 36A Benmore Road, Johannesburg, Gauteng 2010, South Africa.\n\n'
                'These Legal Terms constitute a legally binding agreement between you and Havenly Solutions (Pty) Ltd concerning your access to and use of the Services. By accessing the Services, you have read, understood, and agreed to be bound by all of these Legal Terms. IF YOU DO NOT AGREE WITH ALL OF THESE LEGAL TERMS, THEN YOU ARE EXPRESSLY PROHIBITED FROM USING THE SERVICES AND YOU MUST DISCONTINUE USE IMMEDIATELY.\n\n'
                'The Services are intended for users who are at least 13 years of age. All users who are minors (generally under the age of 18) must have the permission of, and be directly supervised by, their parent or guardian to use the Services.\n\n'
                'OUR SERVICES\n'
                'The information provided when using the Services is not intended for distribution to or use by any person or entity in any jurisdiction where such distribution or use would be contrary to law or regulation.\n\n'
                'INTELLECTUAL PROPERTY RIGHTS\n'
                'We are the owner or licensee of all intellectual property rights in our Services, including all source code, databases, functionality, software, website designs, audio, video, text, photographs, and graphics in the Services, as well as the trademarks, service marks, and logos contained therein. Our Content and Marks are protected by copyright and trademark laws and treaties around the world.\n\n'
                'SMS TEXT MESSAGING\n'
                'By opting into any text messaging program, you expressly consent to receive text messages to your mobile number. If at any time you wish to stop receiving SMS messages, simply reply STOP. Message and data rates may apply. If you have questions contact us at info@havenly.solutions or call 070 368 7327.\n\n'
                'CONTACT US\n'
                'Havenly Solutions (Pty) Ltd\n'
                '36A Benmore Road, Johannesburg, Gauteng 2010, South Africa\n'
                'Phone: 070 368 7327\n'
                'Email: info@havenly.solutions',
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