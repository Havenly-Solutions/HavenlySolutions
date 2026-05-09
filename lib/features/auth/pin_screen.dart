// Returning user PIN login — 3 wrong = silent SOS + lockout

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/translations.dart';
import '../../app/routes.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final List<String> _pin = ['', '', '', ''];
  int _attempts = 0;
  bool _locked = false;
  bool _sosTriggered = false;
  int _sosCountdown = 40;
  int _lockCountdown = 120;

  void _onDigit(String d) {
    if (_locked) return;
    final idx = _pin.indexOf('');
    if (idx == -1) return;
    setState(() => _pin[idx] = d);
    if (_pin.every((c) => c.isNotEmpty)) {
      Future.delayed(const Duration(milliseconds: 150), _checkPin);
    }
  }

  void _onDelete() {
    final last = _pin.lastIndexWhere((c) => c.isNotEmpty);
    if (last == -1) return;
    setState(() => _pin[last] = '');
  }

  Future<void> _checkPin() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_pin') ?? '';
    final entered = _pin.join();

    if (entered == saved) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    }

    _attempts++;
    setState(() => _pin.fillRange(0, 4, ''));

    if (_attempts >= 3) {
      _triggerSOS();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _attempts == 2
                ? AppTranslations.t('pin_wrong_2')
                : AppTranslations.t('pin_wrong'),
          ),
          backgroundColor: Color(0xFF323232),
        ),
      );
    }
  }

  void _triggerSOS() {
    setState(() {
      _locked = true;
      _sosTriggered = true;
      _sosCountdown = 40;
    });
    _startSOSCountdown();
    _startLockCountdown();
  }

  void _startSOSCountdown() async {
    while (_sosCountdown > 0 && _sosTriggered && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _sosCountdown--);
    }
    if (_sosTriggered && mounted) {
      setState(() => _sosTriggered = false);
      // SOS dispatches here — backend call goes in Phase 7
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.t('sos_dispatched')),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  void _startLockCountdown() async {
    while (_lockCountdown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _lockCountdown--);
    }
    if (mounted) {
      setState(() {
        _locked = false;
        _attempts = 0;
        _lockCountdown = 120;
      });
    }
  }

  void _cancelSOS() {
    setState(() {
      _sosTriggered = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTranslations.t('sos_cancelled')),
        backgroundColor: Color(0xFF323232),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image (top 55%)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/auth_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // White card sliding up from bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(
                    children: [
                      const Spacer(),
                      Text(
                        AppTranslations.t('enter_pin'),
                        style: const TextStyle(
                          color: Color(0xFF000000),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) {
                          final filled = _pin[i].isNotEmpty;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _locked
                                  ? Color(0xFFE0E0E0)
                                  : filled
                                      ? const Color(0xFF00BCD4)
                                      : Color(0xFFE0E0E0),
                            ),
                          );
                        }),
                      ),
                      if (_locked) ...[
                        const SizedBox(height: 28),
                        Text(
                          AppTranslations.t('pin_lockout_title'),
                          style: const TextStyle(
                            color: Color(0xFF000000),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppTranslations.t('retry_in')} $_lockCountdown ${AppTranslations.t('seconds')}',
                          style: TextStyle(color: Color(0xFF757575), fontSize: 14),
                        ),
                        if (_sosTriggered) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFFFFCDD2)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  AppTranslations.t('pin_sos_warning'),
                                  style: const TextStyle(
                                    color: Color(0xFF000000),
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '$_sosCountdown ${AppTranslations.t('seconds')}',
                                  style: const TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _cancelSOS,
                                  child: Text(
                                    AppTranslations.t('cancel_sos'),
                                    style: const TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      const Spacer(),
                      if (!_locked)
                        _Keypad(onDigit: _onDigit, onDelete: _onDelete),
                      const SizedBox(height: 24),
                      if (!_locked)
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            AppTranslations.t('forgot_pin'),
                            style: TextStyle(color: Color(0xFF757575)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _Keypad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];
    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 72, height: 72);
            return GestureDetector(
              onTap: () => k == 'del' ? onDelete() : onDigit(k),
              child: Container(
                width: 72,
                height: 72,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                alignment: Alignment.center,
                child: k == 'del'
                    ? Icon(Icons.backspace_outlined,
                        color: Color(0xFF757575), size: 22)
                    : Text(k,
                        style: TextStyle(
                          color: Color(0xFF000000),
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        )),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}