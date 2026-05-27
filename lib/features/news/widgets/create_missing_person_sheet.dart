import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../core/providers/feed_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class CreateMissingPersonSheet extends ConsumerStatefulWidget {
  const CreateMissingPersonSheet({super.key});

  @override
  ConsumerState<CreateMissingPersonSheet> createState() =>
      _CreateMissingPersonSheetState();
}

class _CreateMissingPersonSheetState
    extends ConsumerState<CreateMissingPersonSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _ageController = TextEditingController();
  final _lastSeenController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _bodyController = TextEditingController();

  File? _image;
  bool _isValidating = false;
  bool _isPosting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _lastSeenController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isValidating = true;
      });

      final faceDetector = FaceDetector(options: FaceDetectorOptions());
      final inputImage = InputImage.fromFile(_image!);
      final faces = await faceDetector.processImage(inputImage);

      setState(() => _isValidating = false);

      if (faces.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Please upload a clear photo of the missing person\'s face.')),
          );
        }
        setState(() => _image = null);
      }
      faceDetector.close();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _image == null) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a photo')),
        );
      }
      return;
    }

    setState(() => _isPosting = true);
    final user = ref.read(userProvider);

    await ref.read(feedProvider.notifier).createPost({
      'type': 'MISSING_PERSON',
      'content': _bodyController.text.trim(),
      'mediaUrl': _image!.path, // In real app, upload first
      'missingStatus': 'MISSING',
      'missingPersonData': {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'age': int.tryParse(_ageController.text),
        'lastSeen': _lastSeenController.text.trim(),
        'contactName': _contactNameController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
      },
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Report Missing Person', style: AppTypography.heading1),
                  TextButton(
                    onPressed: _isPosting ? null : _submit,
                    child: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Post',
                            style: TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isValidating
                        ? const Center(child: CircularProgressIndicator())
                        : _image == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.grey),
                                  Text('Upload Photo',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey))
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_image!, fit: BoxFit.cover)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(_nameController, 'Name'),
              const SizedBox(height: 12),
              _buildTextField(_surnameController, 'Surname'),
              const SizedBox(height: 12),
              _buildTextField(_ageController, 'Age',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(
                  _lastSeenController, 'Last Seen (Date & Location)'),
              const SizedBox(height: 12),
              _buildTextField(_contactNameController, 'Contact Name'),
              const SizedBox(height: 12),
              _buildTextField(_contactPhoneController, 'Contact Phone',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(_bodyController, 'Description', maxLines: 3),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }
}
