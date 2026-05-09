// Phone number entry — OTP verification — PIN creation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/language_provider.dart';
import '../../core/constants/translations.dart';
import '../../app/routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _step = 0; // 0=phone, 1=details, 2=pin

  // Controllers
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _provinceController = TextEditingController();
  final _addressController = TextEditingController();
  final _idController = TextEditingController();
  final _countryController = TextEditingController();

  // PIN state
  final List<String> _pin = ['', '', '', ''];
  final List<String> _pinConfirm = ['', '', '', ''];
  bool _confirmingPin = false;
  String _pinError = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _provinceController.dispose();
    _addressController.dispose();
    _idController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_account', true);
    await prefs.setBool('seen_onboarding', false);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
  }

  void _onPinDigit(String digit, bool isConfirm) {
    final list = isConfirm ? _pinConfirm : _pin;
    final idx = list.indexOf('');
    if (idx == -1) return;
    setState(() {
      list[idx] = digit;
      _pinError = '';
    });
    if (list.every((d) => d.isNotEmpty)) {
      if (!isConfirm) {
        setState(() => _confirmingPin = true);
      } else {
        if (_pin.join() == _pinConfirm.join()) {
          _finish();
        } else {
          setState(() {
            _pinConfirm.fillRange(0, 4, '');
            _pin.fillRange(0, 4, '');
            _confirmingPin = false;
            _pinError = AppTranslations.t('pin_mismatch');
          });
        }
      }
    }
  }

  void _onPinDelete(bool isConfirm) {
    final list = isConfirm ? _pinConfirm : _pin;
    final lastFilled = list.lastIndexWhere((d) => d.isNotEmpty);
    if (lastFilled == -1) return;
    setState(() => list[lastFilled] = '');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

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
                child: Column(
                  children: [
                    // App bar in card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_step > 0) {
                                setState(() => _step--);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF000000)),
                          ),
                          Expanded(
                            child: Text(
                              AppTranslations.t('signup_title'),
                              style: const TextStyle(
                                color: Color(0xFF000000),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48), // Balance the back button
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: _step == 0
                          ? _buildPhoneStep()
                          : _step == 1
                              ? _buildDetailsStep()
                              : _buildPinStep(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            AppTranslations.t('phone'),
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),
          _Field(
            controller: _phoneController,
            label: AppTranslations.t('phone'),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const Spacer(),
          _PrimaryButton(
            label: AppTranslations.t('next'),
            onTap: () {
              if (_phoneController.text.length >= 9) {
                setState(() => _step = 1);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _Field(
            controller: _nameController,
            label: AppTranslations.t('name'),
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _surnameController,
            label: AppTranslations.t('surname'),
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _emailController,
            label: AppTranslations.t('email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _ageController,
            label: AppTranslations.t('age'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _provinceController,
            label: AppTranslations.t('province'),
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _addressController,
            label: AppTranslations.t('address'),
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _idController,
            label: AppTranslations.t('id_number'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _countryController,
            label: AppTranslations.t('country'),
          ),
          const SizedBox(height: 32),
          _PrimaryButton(
            label: AppTranslations.t('next'),
            onTap: () {
              if (_nameController.text.isNotEmpty &&
                  _surnameController.text.isNotEmpty &&
                  _emailController.text.isNotEmpty &&
                  _ageController.text.isNotEmpty &&
                  _provinceController.text.isNotEmpty &&
                  _addressController.text.isNotEmpty &&
                  _idController.text.isNotEmpty &&
                  _countryController.text.isNotEmpty) {
                setState(() => _step = 2);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPinStep() {
    final currentPin = _confirmingPin ? _pinConfirm : _pin;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            _confirmingPin
                ? AppTranslations.t('confirm_pin')
                : AppTranslations.t('create_pin'),
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (_pinError.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _pinError,
              style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 40),
          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = currentPin[i].isNotEmpty;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? const Color(0xFF00BCD4)
                      : Color(0xFFE0E0E0),
                ),
              );
            }),
          ),
          const SizedBox(height: 48),
          // Keypad
          _Keypad(
            onDigit: (d) => _onPinDigit(d, _confirmingPin),
            onDelete: () => _onPinDelete(_confirmingPin),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Color(0xFF000000)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF757575)),
        filled: true,
        fillColor: Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00BCD4)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                    : Text(
                        k,
                        style: TextStyle(
                          color: Color(0xFF000000),
                          fontSize: 24,
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