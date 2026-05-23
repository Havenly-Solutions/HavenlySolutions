import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/translations.dart';

class PersonalDetailsView extends StatefulWidget {
  final VoidCallback onContinue;
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
  final TextEditingController _phoneController =
      TextEditingController(text: '+27 ');
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _communityController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  final List<String> _titles = ['Mr', 'Mrs', 'Ms', 'Dr', 'Prof', 'Rev'];
  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('STEP 1 OF 2',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A3D3D),
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            const Text('Personal Details',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3D3D))),
            const SizedBox(height: 8),
            Text(
              'Please provide your accurate information to ensure a secure setup within Havenly.',
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
                      'Title',
                      'Select Title',
                      _titles,
                      _selectedTitle,
                      (val) => setState(() => _selectedTitle = val)),
                  const SizedBox(height: 16),
                  _buildTextField('First Name', 'Enter your first name',
                      controller: _firstNameController),
                  const SizedBox(height: 16),
                  _buildTextField('Surname', 'Enter your surname',
                      controller: _surnameController),
                  const SizedBox(height: 16),
                  _buildDropdown(
                      'Gender',
                      'Select Gender',
                      _genders,
                      _selectedGender,
                      (val) => setState(() => _selectedGender = val)),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Date of Birth',
                    'mm/dd/yyyy',
                    controller: _dobController,
                    suffixIcon: Icons.calendar_today_outlined,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('ID Number / Passport', 'Enter ID number',
                      controller: _idController),
                  const SizedBox(height: 16),
                  _buildDropdown(
                      'Race / Ethnicity',
                      'Select Identity',
                      _races,
                      _selectedRace,
                      (val) => setState(() => _selectedRace = val)),
                  const SizedBox(height: 16),
                  _buildTextField('Phone Number', '+27 (00) 000-0000',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField('Email Address', 'name@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField(
                      'Residential Address', '123 Havenly Lane, Suite 100',
                      controller: _addressController),
                  const SizedBox(height: 16),
                  _buildTextField('Community / Neighborhood',
                      'Search for your community...',
                      controller: _communityController,
                      icon: Icons.location_on_outlined),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003333),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue to Identity Scan',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward,
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
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
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
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String hint, List<String> items,
      String? value, ValueChanged<String?> onChanged) {
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
            ),
          ),
        ),
      ],
    );
  }
}
