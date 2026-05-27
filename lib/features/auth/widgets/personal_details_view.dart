import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/translations.dart';
import '../models/signup_data.dart';

class PersonalDetailsView extends StatefulWidget {
  final void Function(SignupData data) onContinue;
  const PersonalDetailsView({super.key, required this.onContinue});

  @override
  State<PersonalDetailsView> createState() => _PersonalDetailsViewState();
}

class _PersonalDetailsViewState extends State<PersonalDetailsView> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedTitle;
  String? _selectedGender;
  String? _selectedRace;
  DateTime? _selectedDate;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _communityController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  final List<String> _titles = [
    AppTranslations.t('title_mr'),
    AppTranslations.t('title_mrs'),
    AppTranslations.t('title_ms'),
    AppTranslations.t('title_dr'),
    AppTranslations.t('title_prof'),
    AppTranslations.t('title_rev'),
  ];
  final List<String> _genders = [
    AppTranslations.t('gender_male'),
    AppTranslations.t('gender_female'),
    AppTranslations.t('gender_other'),
    AppTranslations.t('gender_prefer_not_to_say'),
  ];

  List<String> get _races => [
        AppTranslations.t('race_African'),
        AppTranslations.t('race_White'),
        AppTranslations.t('race_Coloured'),
        AppTranslations.t('race_Indian'),
        AppTranslations.t('race_Asian'),
        AppTranslations.t('race_Other'),
      ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF003333),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  void _continue() {
    if (_formKey.currentState?.validate() ?? false) {
      final signupData = SignupData(
        title: _selectedTitle!,
        firstName: _firstNameController.text.trim(),
        surname: _surnameController.text.trim(),
        gender: _selectedGender!,
        race: _selectedRace!,
        dateOfBirth: _selectedDate!,
        idNumber: _idController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        province: _provinceController.text.trim().isEmpty
            ? 'Gauteng'
            : _provinceController.text.trim(),
        community: _communityController.text.trim(),
      );
      widget.onContinue(signupData);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _provinceController.dispose();
    _communityController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppTranslations.t('step 1 of 2'),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A3D3D),
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text(AppTranslations.t('personal_details'),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3D3D))),
            const SizedBox(height: 8),
            Text(
              AppTranslations.t('personal_details_sub'),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdown(
                    AppTranslations.t('title'),
                    AppTranslations.t('select_title'),
                    _titles,
                    _selectedTitle,
                    (val) => setState(() => _selectedTitle = val),
                    validator: (value) => value == null
                        ? AppTranslations.t('error_required')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    AppTranslations.t('first name'),
                    AppTranslations.t('enter name'),
                    controller: _firstNameController,
                    validator: (value) => value?.trim().isEmpty ?? true
                        ? AppTranslations.t('error_required')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    AppTranslations.t('surname'),
                    AppTranslations.t('enter surname'),
                    controller: _surnameController,
                    validator: (value) => value?.trim().isEmpty ?? true
                        ? AppTranslations.t('error_required')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    AppTranslations.t('gender'),
                    AppTranslations.t('select_gender'),
                    _genders,
                    _selectedGender,
                    (val) => setState(() => _selectedGender = val),
                    validator: (value) => value == null
                        ? AppTranslations.t('error_required')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    AppTranslations.t('date_of_birth'),
                    AppTranslations.t('date_format_hint'),
                    controller: _dobController,
                    suffixIcon: Icons.calendar_today_outlined,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) => _selectedDate == null
                        ? AppTranslations.t('error_select_date')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    AppTranslations.t('id_number_passport'),
                    AppTranslations.t('enter_id_number'),
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.trim().isEmpty ?? true
                        ? AppTranslations.t('error_required')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    AppTranslations.t('race_ethnicity'),
                    AppTranslations.t('select_identity'),
                    _races,
                    _selectedRace,
                    (val) => setState(() => _selectedRace = val),
                    validator: (value) => value == null
                        ? AppTranslations.t('error_required')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    AppTranslations.t('phone'),
                    AppTranslations.t('enter_phone_number'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixText: '+27 ',
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return AppTranslations.t('error_required');
                      }
                      final digitsOnly =
                          value!.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digitsOnly.length < 9 || digitsOnly.length > 10) {
                        return AppTranslations.t('error_invalid_phone');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    AppTranslations.t('email'),
                    AppTranslations.t('email_hint'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return AppTranslations.t('error_required');
                      }
                      if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(value!.trim())) {
                        return AppTranslations.t('error_invalid_email');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    AppTranslations.t('address'),
                    AppTranslations.t('enter_residential_address'),
                    controller: _addressController,
                    validator: (value) => value?.trim().isEmpty ?? true
                        ? AppTranslations.t('error_required')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    AppTranslations.t('postal code'),
                    AppTranslations.t('enter_postal_code'),
                    controller: _postalCodeController,
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.trim().isEmpty ?? true
                        ? AppTranslations.t('error_required')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'Province',
                    'Select Province',
                    [
                      'Eastern Cape',
                      'Free State',
                      'Gauteng',
                      'KwaZulu-Natal',
                      'Limpopo',
                      'Mpumalanga',
                      'Northern Cape',
                      'North West',
                      'Western Cape'
                    ],
                    _provinceController.text.isEmpty
                        ? null
                        : _provinceController.text,
                    (val) => setState(() => _provinceController.text = val!),
                    validator: (value) => value == null
                        ? AppTranslations.t('error_required')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    AppTranslations.t('Community'),
                    AppTranslations.t('search community'),
                    controller: _communityController,
                    icon: Icons.location_on_outlined,
                    validator: (value) => value?.trim().isEmpty ?? true
                        ? AppTranslations.t('error_required')
                        : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003333),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppTranslations.t('continue to identity scan'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    IconData? icon,
    IconData? suffixIcon,
    TextEditingController? controller,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            decoration: InputDecoration(
              icon: icon != null
                  ? Icon(icon, size: 18, color: Colors.grey)
                  : null,
              suffixIcon: suffixIcon != null
                  ? GestureDetector(
                      onTap: onTap,
                      child: Icon(suffixIcon, size: 18, color: Colors.black87))
                  : null,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixText: prefixText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String hint, List<String> items,
      String? value, ValueChanged<String?> onChanged,
      {String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: value,
              hint: Text(hint,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              isExpanded: true,
              dropdownColor: Colors.white,
              decoration: const InputDecoration(border: InputBorder.none),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item,
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 13)),
                );
              }).toList(),
              onChanged: onChanged,
              validator: validator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
        ),
      ],
    );
  }
}
