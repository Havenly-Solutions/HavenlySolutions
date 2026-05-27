import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/providers/feed_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class MissingPersonPostScreen extends ConsumerStatefulWidget {
  const MissingPersonPostScreen({super.key});

  @override
  ConsumerState<MissingPersonPostScreen> createState() => _MissingPersonPostScreenState();
}

class _MissingPersonPostScreenState extends ConsumerState<MissingPersonPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _lastSeenController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _detailsController = TextEditingController();
  
  String _gender = 'Male';
  XFile? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _image = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo of the missing person.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // In a real app, upload image to S3 first
      const mockImageUrl = 'https://via.placeholder.com/300';

      await ref.read(feedProvider.notifier).createPost({
        'type': 'MISSING_PERSON',
        'content': _detailsController.text,
        'mediaUrl': mockImageUrl,
        'missingStatus': 'MISSING',
        'missingPersonData': {
          'name': _nameController.text,
          'age': int.parse(_ageController.text),
          'gender': _gender,
          'lastSeen': _lastSeenController.text,
          'contactName': _contactNameController.text,
          'contactPhone': _contactPhoneController.text,
        },
      });

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing person report published successfully.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Missing Person'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'PHOTO OF MISSING PERSON',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(_image!.path), fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Upload Photo', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField('FULL NAME', _nameController, 'Enter name'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField('AGE', _ageController, 'Years', keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GENDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: ['Male', 'Female', 'Other'].map((String val) {
                          return DropdownMenuItem<String>(value: val, child: Text(val));
                        }).toList(),
                        onChanged: (val) => setState(() => _gender = val!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('LAST SEEN LOCATION', _lastSeenController, 'Area or Street'),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const Text('CONTACT FOR TIPS', style: AppTypography.heading2),
            const SizedBox(height: 16),
            _buildTextField('CONTACT NAME', _contactNameController, 'Name'),
            const SizedBox(height: 16),
            _buildTextField('CONTACT PHONE', _contactPhoneController, '+27...', keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
            _buildTextField('ADDITIONAL DETAILS', _detailsController, 'Clothing, identifying marks...', maxLines: 3),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Publish Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (val) => val!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
