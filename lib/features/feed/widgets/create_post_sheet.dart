// File: lib/features/feed/widgets/create_post_sheet.dart
// Havenly Solutions (Pty) Ltd
// Bottom sheet for creating news posts and missing person reports

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../feed_provider.dart';

enum _PostType { news, missingPerson }

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  _PostType _postType = _PostType.news;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  String? _imagePath;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final provider = context.read<FeedProvider>();
    final path = await provider.pickMissingPersonImage();
    if (path != null && mounted) {
      setState(() => _imagePath = path);
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    if (_postType == _PostType.missingPerson &&
        _contactPhoneController.text.trim().isEmpty) return;

    setState(() => _submitting = true);

    final prefs = await SharedPreferences.getInstance();
    final authorId = prefs.getString('user_id') ?? 'local_user';
    final authorName = prefs.getString('user_name') ?? 'Anonymous';
    final authorRegion = prefs.getString('user_region') ?? 'Unknown';
    final authorAge = prefs.getInt('user_age');
    final provider = context.read<FeedProvider>();

    if (_postType == _PostType.news) {
      await provider.createNewsPost(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        authorId: authorId,
        authorName: authorName,
        authorRegion: authorRegion,
        authorAge: authorAge,
      );
    } else {
      await provider.createMissingPersonPost(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        contactName: _contactNameController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        authorId: authorId,
        authorName: authorName,
        authorRegion: authorRegion,
        authorAge: authorAge,
        imageLocalPath: _imagePath,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Create Post',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Type selector
            Row(
              children: [
                _TypeChip(
                  label: 'News',
                  selected: _postType == _PostType.news,
                  onTap: () => setState(() => _postType = _PostType.news),
                ),
                const SizedBox(width: 10),
                _TypeChip(
                  label: 'Missing Person',
                  selected: _postType == _PostType.missingPerson,
                  onTap: () =>
                      setState(() => _postType = _PostType.missingPerson),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Image picker (missing person only)
            if (_postType == _PostType.missingPerson) ...[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF222222)),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.grey.shade600,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _SheetField(
              controller: _titleController,
              label: _postType == _PostType.missingPerson
                  ? 'Full Name of Missing Person'
                  : 'Title',
            ),
            const SizedBox(height: 12),
            _SheetField(
              controller: _bodyController,
              label: _postType == _PostType.missingPerson
                  ? 'Age, physical description, last seen location'
                  : 'Details',
              maxLines: 4,
            ),

            if (_postType == _PostType.missingPerson) ...[
              const SizedBox(height: 12),
              _SheetField(
                controller: _contactNameController,
                label: 'Contact Name (who to call)',
              ),
              const SizedBox(height: 12),
              _SheetField(
                controller: _contactPhoneController,
                label: 'Contact Phone Number',
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  disabledBackgroundColor: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE53935).withOpacity(0.15)
              : const Color(0xFF111111),
          border: Border.all(
            color:
                selected ? const Color(0xFFE53935) : const Color(0xFF222222),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFE53935) : Colors.grey.shade500,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _SheetField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF111111),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF222222)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF222222)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
