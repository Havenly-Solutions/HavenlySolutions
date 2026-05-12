import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/translations.dart';
import '../../core/providers/language_provider.dart';
import '../../core/database/local_db.dart';
import '../../core/widgets/app_background.dart';
import '../../providers/user_provider.dart';
import '../../Shared/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Colors.black),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: Colors.black),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${const Uuid().v4()}.jpg';
      final saved = await File(picked.path).copy('${dir.path}/$fileName');

      final user = context.read<UserProvider>().currentUser;
      if (user != null) {
        await LocalDb.updateUser(user.id, {'profile_image_path': saved.path});
        // Reload session to update UI
        if (mounted) await context.read<UserProvider>().bootSession();
      }
    } catch (e) {
      debugPrint('Error saving profile photo: $e');
    }

    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final user = context.watch<UserProvider>().currentUser;

    return AppBackground(
      headerTitle: AppTranslations.t('profile_title'),
      headerSubtitle: 'Havenly Solutions',
      showBackButton: true,
      child: user == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _changePhoto,
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade100, width: 3),
                                ),
                                child: CircleAvatar(
                                  radius: 64,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  backgroundImage: user.profileImagePath != null
                                      ? FileImage(File(user.profileImagePath!))
                                      : null,
                                  child: user.profileImagePath == null
                                      ? const Icon(Icons.person, size: 64, color: Colors.black26)
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _uploading 
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Space Grotesk',
                          ),
                        ),
                        Text(
                          user.phoneNumber,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildSectionTitle(AppTranslations.t('details')),
                  _buildInfoTile(Icons.email_outlined, AppTranslations.t('email'), user.email),
                  _buildInfoTile(Icons.calendar_today_outlined, AppTranslations.t('age'), user.age.toString()),
                  _buildInfoTile(Icons.people_outline, AppTranslations.t('race'), user.race),
                  const SizedBox(height: 24),
                  _buildSectionTitle(AppTranslations.t('location')),
                  _buildInfoTile(Icons.map_outlined, AppTranslations.t('province'), user.province),
                  _buildInfoTile(Icons.home_outlined, AppTranslations.t('community'), user.community),
                  const SizedBox(height: 24),
                  _buildSectionTitle(AppTranslations.t('security')),
                  _buildInfoTile(Icons.badge_outlined, AppTranslations.t('id_number'), user.idNumber),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton(
                      onPressed: () => context.read<UserProvider>().logout(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryRed),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        AppTranslations.t('sign_out'),
                        style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  value != null && value.isNotEmpty ? value : 'Not provided',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
