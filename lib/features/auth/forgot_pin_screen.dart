import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/routes.dart';
import '../../core/constants/translations.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final List<String> _pin = ['', '', '', ''];
  final List<String> _pinConfirm = ['', '', '', ''];
  bool _verified = false;
  bool _confirmingPin = false;
  String _message = '';

  void _verify(String method) {
    setState(() {
      _verified = true;
      _message =
          'Recovery confirmed by $method. Now create a new 4-digit PIN.';
    });
  }

  void _onDigit(String digit) {
    final list = _confirmingPin ? _pinConfirm : _pin;
    final idx = list.indexOf('');
    if (idx == -1) return;
    setState(() {
      list[idx] = digit;
      _message = '';
    });
    if (list.every((d) => d.isNotEmpty)) {
      if (!_confirmingPin) {
        setState(() {
          _confirmingPin = true;
          _message = 'Enter the same PIN again to confirm it.';
        });
      } else {
        _saveIfMatched();
      }
    }
  }

  void _onDelete() {
    final list = _confirmingPin ? _pinConfirm : _pin;
    final last = list.lastIndexWhere((d) => d.isNotEmpty);
    if (last == -1) return;
    setState(() => list[last] = '');
  }

  Future<void> _saveIfMatched() async {
    if (_pin.join() != _pinConfirm.join()) {
      setState(() {
        _pin.fillRange(0, 4, '');
        _pinConfirm.fillRange(0, 4, '');
        _confirmingPin = false;
        _message = AppTranslations.t('pin_mismatch');
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pin', _pin.join());
    await prefs.setBool('has_account', true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTranslations.t('pin_changed')),
        backgroundColor: const Color(0xFF323232),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.pin,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _confirmingPin ? _pinConfirm : _pin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          AppTranslations.t('forgot_pin_title'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
          child: Column(
            children: [
              Image.asset('assets/images/logo.png', width: 72, height: 72),
              const SizedBox(height: 18),
              Text(
                _verified
                    ? AppTranslations.t('set_new_pin')
                    : AppTranslations.t('forgot_pin_sub'),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _verified
                    ? 'Choose a PIN you will remember. You will still enter it after biometric login so the number stays familiar.'
                    : 'Confirm your account recovery method before changing the PIN on this device.',
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!_verified) ...[
                _RecoveryButton(
                  label: AppTranslations.t('reset_via_sms'),
                  icon: Icons.sms_outlined,
                  onTap: () => _verify('SMS'),
                ),
                const SizedBox(height: 12),
                _RecoveryButton(
                  label: AppTranslations.t('reset_via_email'),
                  icon: Icons.email_outlined,
                  onTap: () => _verify('email'),
                ),
              ] else ...[
                Text(
                  _confirmingPin
                      ? AppTranslations.t('confirm_pin')
                      : AppTranslations.t('set_new_pin'),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = currentPin[i].isNotEmpty;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? const Color(0xFF00BCD4)
                            : const Color(0xFFE0E0E0),
                      ),
                    );
                  }),
                ),
                if (_message.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message,
                    style: TextStyle(
                      color: _message == AppTranslations.t('pin_mismatch')
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF757575),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                _ResetKeypad(onDigit: _onDigit, onDelete: _onDelete),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoveryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _RecoveryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00BCD4), size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFF757575)),
          ],
        ),
      ),
    );
  }
}

class _ResetKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _ResetKeypad({required this.onDigit, required this.onDelete});

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
            if (k.isEmpty) return const SizedBox(width: 68, height: 68);
            return GestureDetector(
              onTap: () => k == 'del' ? onDelete() : onDigit(k),
              child: Container(
                width: 68,
                height: 68,
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                alignment: Alignment.center,
                child: k == 'del'
                    ? const Icon(
                        Icons.backspace_outlined,
                        color: Color(0xFF757575),
                        size: 20,
                      )
                    : Text(
                        k,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
