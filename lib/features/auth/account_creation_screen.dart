import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/translations.dart';
import '../../core/providers/user_provider.dart';
import '../auth/models/signup_data.dart';

class AccountCreationScreen extends ConsumerStatefulWidget {
  final SignupData? signupData;
  const AccountCreationScreen({super.key, this.signupData});

  @override
  ConsumerState<AccountCreationScreen> createState() =>
      _AccountCreationScreenState();
}

class _AccountCreationScreenState extends ConsumerState<AccountCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emergencyContactNameController =
      TextEditingController();
  final TextEditingController _emergencyContactPhoneController =
      TextEditingController(text: '+27 ');
  final TextEditingController _sosPinController = TextEditingController();
  final TextEditingController _sosPinConfirmController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.signupData?.fullName ?? '');
    _idController =
        TextEditingController(text: widget.signupData?.idNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _sosPinController.dispose();
    _sosPinConfirmController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (widget.signupData == null) {
      setState(() =>
          _errorMessage = AppTranslations.t('error_personal_details_missing'));
      return;
    }

    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = AppTranslations.t('error_fill_required'));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(
          () => _errorMessage = AppTranslations.t('error_password_mismatch'));
      return;
    }

    if (_sosPinController.text != _sosPinConfirmController.text) {
      setState(
          () => _errorMessage = AppTranslations.t('error_sos_pin_mismatch'));
      return;
    }

    if (_sosPinController.text.length != 4 ||
        !_sosPinController.text.contains(RegExp(r'^[0-9]+$'))) {
      setState(() => _errorMessage = AppTranslations.t('error_sos_pin_digits'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(userProvider.notifier).signup(
            fullName: widget.signupData!.fullName,
            email: widget.signupData!.email,
            phone: widget.signupData!.formattedPhone,
            password: _passwordController.text,
            idNumber: widget.signupData!.idNumber,
            dateOfBirth: widget.signupData!.dateOfBirth,
            address: widget.signupData!.address,
            postalCode: widget.signupData!.postalCode,
            emergencyContactName: _emergencyContactNameController.text.trim(),
            emergencyContactPhone: _emergencyContactPhoneController.text.trim(),
            sosPin: _sosPinController.text.trim(),
            age: 25, // TODO: calculate from DOB or pass from signupData
            gender: widget.signupData!.gender,
            province: widget.signupData!.province,
            community: widget.signupData!.community,
            faceImageHash: widget.signupData!.faceImageHash,
            faceImageUrl: widget.signupData!.faceImageUrl,
            verificationToken: widget.signupData!.verificationToken,
          );

      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
      setState(() => _errorMessage =
          '${AppTranslations.t('error_signup_failed')}: ${error.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.t('signup_title'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              TextFormField(
                controller: _nameController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: AppTranslations.t('full name'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: AppTranslations.t('id number'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppTranslations.t('password'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return AppTranslations.t('error_required');
                  }
                  if (value!.length < 8) {
                    return AppTranslations.t('error_password_length');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppTranslations.t('confirm password'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? AppTranslations.t('error_required')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyContactNameController,
                decoration: InputDecoration(
                  labelText: AppTranslations.t('emergency contact name'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? AppTranslations.t('error_required')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyContactPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: AppTranslations.t('emergency_contact_phone'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? AppTranslations.t('error_required')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sosPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: AppTranslations.t('four_digit_sos_pin'),
                  counterText: '',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return AppTranslations.t('error_required');
                  }
                  if (value!.length != 4) {
                    return AppTranslations.t('error_4_digits_required');
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return AppTranslations.t('error_numbers_only');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sosPinConfirmController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: AppTranslations.t('confirm_sos_pin'),
                  counterText: '',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? AppTranslations.t('error_required')
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createAccount,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(AppTranslations.t('complete_signup')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
