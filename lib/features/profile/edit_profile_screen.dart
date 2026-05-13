import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../core/database/local_db.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _provinceController;
  late TextEditingController _communityController;
  late TextEditingController _suburbController;

  String? _gender;
  String? _race;
  String? _title;

  final List<String> _genders = [
    'male',
    'female',
    'non-binary',
    'prefer_not_to_say'
  ];
  final List<String> _races = [
    'african',
    'white',
    'coloured',
    'indian',
    'asian',
    'other'
  ];
  final List<String> _titles = ['Mr', 'Mrs', 'Ms', 'Miss', 'Dr', 'Prof', 'Adv'];

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().currentUser;
    _nameController = TextEditingController(text: user?.fullName);
    _ageController = TextEditingController(text: user?.age.toString());
    _emailController = TextEditingController(text: user?.email);
    _provinceController = TextEditingController(text: user?.province);
    _communityController = TextEditingController(text: user?.community);
    _suburbController = TextEditingController();

    _gender = user?.gender;
    _race = user?.race;
    _title = user?.title;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _provinceController.dispose();
    _communityController.dispose();
    _suburbController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final data = {
        'fullName': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'email': _emailController.text.trim(),
        'province': _provinceController.text.trim(),
        'community': _communityController.text.trim(),
        'suburb': _suburbController.text.trim(),
        'gender': _gender,
        'race': _race,
        'title': _title,
      };

      final response = await ApiService().patch('/api/users/me', data: data);

      if (response.data['success']) {
        final userProvider = context.read<UserProvider>();
        if (userProvider.currentUser != null) {
          await LocalDb.updateUser(userProvider.currentUser!.id, {
            'full_name': _nameController.text.trim(),
            'age': int.parse(_ageController.text.trim()),
            'email': _emailController.text.trim(),
            'province': _provinceController.text.trim(),
            'community_name': _communityController.text.trim(),
            'gender': _gender,
            'race': _race,
            'title': _title,
          });
          await userProvider.bootSession();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(
                fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A2E),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1A2E)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("PERSONAL INFO"),
                    _buildDropdown("Title", _title, _titles,
                        (v) => setState(() => _title = v)),
                    _buildTextField(
                        _nameController, "Full Name", Icons.person_outline),
                    _buildTextField(_ageController, "Age",
                        Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number),
                    _buildTextField(_emailController, "Email Address",
                        Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 24),
                    _buildSectionTitle("DEMOGRAPHICS"),
                    DropdownButtonFormField<String>(
                      value: _gender,
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
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    _buildDropdown("Race", _race, _races,
                        (v) => setState(() => _race = v)),
                    const SizedBox(height: 24),
                    _buildSectionTitle("LOCATION"),
                    _buildTextField(
                        _provinceController, "Province", Icons.map_outlined),
                    _buildTextField(_communityController, "Community",
                        Icons.location_city_outlined),
                    _buildTextField(_suburbController, "Suburb",
                        Icons.location_on_outlined),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A2E),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Save Changes",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontFamily: 'DM Sans',
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontFamily: 'DM Sans'),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Field required';
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        style: const TextStyle(fontFamily: 'DM Sans', color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }
}
