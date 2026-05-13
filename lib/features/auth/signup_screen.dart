import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/language_provider.dart';
import '../../core/constants/translations.dart';
import '../../core/services/communities_service.dart';
import '../../core/widgets/app_background.dart';
import '../../core/security/secure_storage_service.dart';
import '../../providers/user_provider.dart';
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
  final _addressController = TextEditingController();
  final _idController = TextEditingController();
  final _countryController = TextEditingController();
  final _communityController = TextEditingController();

  String? _selectedTitle;
  String? _selectedGender;
  String? _selectedRace;
  String? _selectedProvince;

  final List<String> _titleOptions = [
    'Mr',
    'Mrs',
    'Miss',
    'Ms',
    'Dr',
    'Prof',
    'Mx',
  ];

  final List<String> _genderOptions = [
    'male',
    'female',
    'non-binary',
    'prefer_not_to_say',
  ];

  final List<String> _raceOptions = [
    'African',
    'White',
    'Coloured',
    'Indian',
    'Asian',
    'Other',
  ];

  // PIN state
  final List<String> _pin = ['', '', '', ''];
  final List<String> _pinConfirm = ['', '', '', ''];
  bool _confirmingPin = false;
  String _pinError = '';

  @override
  void initState() {
    super.initState();
  }

  void _showPinEducation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Creating your Safety PIN',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Your 4-digit PIN is your key to Havenly Solutions. You will use it to log in and to trigger an SOS from any device via USSD. Keep it private.',
          style: TextStyle(color: Colors.black87, fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I UNDERSTAND',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _idController.dispose();
    _countryController.dispose();
    _communityController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final fullName =
        '${_nameController.text.trim()} ${_surnameController.text.trim()}';
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final idNumber = _idController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final community = _communityController.text.trim();
    final pinRaw = _pin.join();

    final userProvider = context.read<UserProvider>();
    final currentLang = context.read<LanguageProvider>().currentLanguage;

    final deviceId = await SecureStorageService.getOrCreateDeviceId();
    final fcmToken = await SecureStorageService.getFcmToken();

    final registrationData = {
      'fullName': fullName,
      'title': _selectedTitle ?? '',
      'gender': _selectedGender ?? '',
      'age': age,
      'idNumber': idNumber,
      'passportNumber': null,
      'phoneNumber': phoneNumber,
      'email': email,
      'province': _selectedProvince ?? '',
      'race': _selectedRace ?? '',
      'community': community,
      'emergencyContacts': <String>[],
      'pinHash': pinRaw,
      'deviceId': deviceId,
      'fcmToken': fcmToken,
      'preferredLanguage': currentLang,
    };

    final success = await userProvider.register(registrationData);

    if (!mounted) return;

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', phoneNumber);
      await prefs.setBool('has_account', true);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
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
          _handleRegister();
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

    return AppBackground(
      headerTitle: AppTranslations.t('signup_title'),
      headerSubtitle: 'Create your Havenly identity securely',
      cardHeightFactor: _step == 0 ? 0.42 : (_step == 2 ? 0.82 : 0.78),
      showBackButton: true,
      isCleanMode: false,
      child: _step == 0
          ? _buildPhoneStep()
          : _step == 1
              ? _buildDetailsStep()
              : _buildPinStep(),
    );
  }

  Widget _buildPhoneStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
              step: 1,
              title: 'Phone Number',
              subtitle: 'Enter the number you will use to access Havenly.'),
          const SizedBox(height: 20),
          _Field(
            controller: _phoneController,
            label: AppTranslations.t('phone'),
            hint: 'e.g. 0811234567',
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
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
              step: 2,
              title: 'Personal Details',
              subtitle: 'Add your title, gender and location information.'),
          const SizedBox(height: 20),
          _Field(controller: _nameController, label: AppTranslations.t('name')),
          const SizedBox(height: 16),
          _Field(
              controller: _surnameController,
              label: AppTranslations.t('surname')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedTitle,
                  items: _titleOptions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  decoration: _fieldDecoration('Title'),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black),
                  onChanged: (value) => setState(() => _selectedTitle = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: const Color(0xFF111111),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF222222)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF222222)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE53935)),
                    ),
                  ),
                  dropdownColor: const Color(0xFF111111),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'non-binary', child: Text('Non-binary')),
                    DropdownMenuItem(
                      value: 'prefer_not_to_say',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
              ),
            ],
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
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedRace,
                  items: _raceOptions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(AppTranslations.t('race_$value')),
                        ),
                      )
                      .toList(),
                  decoration: _fieldDecoration(AppTranslations.t('race')),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black),
                  onChanged: (value) => setState(() => _selectedRace = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedProvince,
                  items: CommunitiesService.saProvinces
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  decoration: _fieldDecoration(AppTranslations.t('province')),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black),
                  onChanged: (value) =>
                      setState(() => _selectedProvince = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _communityController,
            label: AppTranslations.t('community'),
            hint: AppTranslations.t('community_hint'),
          ),
          const SizedBox(height: 16),
          _Field(
              controller: _addressController,
              label: AppTranslations.t('address')),
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
              label: AppTranslations.t('country')),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: AppTranslations.t('next'),
            onTap: () {
              if (_nameController.text.isNotEmpty &&
                  _surnameController.text.isNotEmpty &&
                  _selectedTitle != null &&
                  _selectedGender != null &&
                  _emailController.text.isNotEmpty &&
                  _ageController.text.isNotEmpty &&
                  _selectedRace != null &&
                  _selectedProvince != null &&
                  _communityController.text.isNotEmpty &&
                  _addressController.text.isNotEmpty &&
                  _idController.text.isNotEmpty &&
                  _countryController.text.isNotEmpty) {
                setState(() => _step = 2);
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _showPinEducation());
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPinStep() {
    final currentPin = _confirmingPin ? _pinConfirm : _pin;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepHeader(
              step: 3,
              title: 'Create PIN',
              subtitle: 'Set a secure 4-digit PIN for quick access.'),
          const SizedBox(height: 18),
          if (_pinError.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _pinError,
                style: const TextStyle(color: Color(0xFFC0392B), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = currentPin[i].isNotEmpty;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      filled ? const Color(0xFFE53935) : Colors.grey.shade300,
                  border: Border.all(color: Colors.grey.shade400),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          _Keypad(
            onDigit: (d) => _onPinDigit(d, _confirmingPin),
            onDelete: () => _onPinDelete(_confirmingPin),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;

  const _StepHeader(
      {required this.step, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$step',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Step $step of 3',
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
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
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
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
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(36),
                ),
                alignment: Alignment.center,
                child: k == 'del'
                    ? const Icon(Icons.backspace_outlined,
                        color: Colors.black, size: 24)
                    : Text(
                        k,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
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
