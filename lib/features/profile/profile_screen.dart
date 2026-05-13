import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../app/routes.dart';
import '../../Shared/theme/app_theme.dart';
import '../../core/providers/language_provider.dart';
import '../../core/database/local_db.dart';
import '../../providers/user_provider.dart';
import '../../services/device_reset_service.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (!userProvider.isAuthenticated) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _changePhoto() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Profile Photo',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_outlined, color: AppColors.textPrimary),
              title: Text('Take Photo', style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: AppColors.textPrimary),
              title: Text('Choose from Gallery', style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textPrimary)),
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

      if (user != null) {
        await LocalDb.updateUser(user.id, {'profile_image_path': saved.path});
        if (context.mounted) await userProvider.bootSession();
      }
    } catch (e) {
      debugPrint('Error saving profile photo: $e');
    }

    if (context.mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final user = context.watch<UserProvider>().currentUser;

    if (user == null) {
        return Scaffold(
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // MOUNTAIN HEADER BANNER
            Stack(
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/mountain top view.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color.fromRGBO(26, 26, 46, 0.8),
                      ],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _changePhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.surface,
                              child: CircleAvatar(
                                radius: 34,
                                backgroundImage: user.profileImagePath != null
                                    ? FileImage(File(user.profileImagePath!))
                                    : null,
                                backgroundColor: AppColors.primary,
                                child: user.profileImagePath == null
                                    ? const Icon(Icons.person, color: Colors.white)
                                    : null,
                              ),
                            ),
                            if (_uploading)
                              const Positioned.fill(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              user.phoneNumber,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: const Color.fromRGBO(255, 255, 255, 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // CONTENT
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // DUTY/ACTIVE STATUS CARD
                  _ProfileCard(
                    label: "ACCOUNT STATUS",
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Active Member",
                                style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: AppColors.green,
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text("Active",
                                    style: GoogleFonts.dmSans(
                                        color: AppColors.green,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        const _DetailRow(
                            label: "Last active", value: "Just now", isGrey: true),
                        const SizedBox(height: 8),
                        _DetailRow(
                            label: "Member since",
                            value: DateFormat('MMMM yyyy').format(user.createdAt),
                            isGrey: true),
                      ],
                    ),
                  ),

                  // SECURITY LOG CARD
                  const _ProfileCard(
                    label: "SECURITY",
                    child: Column(
                      children: [
                        _SecurityRow(
                          icon: Icons.shield_outlined,
                          iconColor: AppColors.green,
                          title: "Biometric Login",
                          subtitle: "Enabled",
                        ),
                        _SecurityRow(
                          icon: Icons.phone_android_outlined,
                          iconColor: AppColors.textPrimary,
                          title: "Device Authorized",
                          subtitle: "LGN NX1",
                        ),
                        _SecurityRow(
                          icon: Icons.lock_outline,
                          iconColor: AppColors.textPrimary,
                          title: "2-Step Verification",
                          subtitle: "PIN protection active",
                        ),
                        _SecurityRow(
                          icon: Icons.key_outlined,
                          iconColor: AppColors.textPrimary,
                          title: "Change PIN",
                          subtitle: "Update your 4-digit security PIN",
                          showChevron: true,
                        ),
                      ],
                    ),
                  ),

                  // PERSONAL DETAILS SECTION
                  _ProfileCard(
                    label: "PERSONAL DETAILS",
                    child: Column(
                      children: [
                        _InfoField(
                            icon: Icons.mail_outline,
                            label: "Email",
                            value: user.email ?? "Not provided"),
                        _InfoField(
                            icon: Icons.calendar_today_outlined,
                            label: "Age",
                            value: "${user.age} years"),
                        _InfoField(
                            icon: Icons.map_outlined,
                            label: "Province",
                            value: user.province),
                        _InfoField(
                            icon: Icons.location_city_outlined,
                            label: "Community",
                            value: user.community),
                        _InfoField(
                            icon: Icons.people_outline,
                            label: "Race",
                            value: user.race),
                        _InfoField(
                          icon: Icons.contacts_outlined,
                          label: "Emergency Contacts",
                          value: "${user.emergencyContacts.length} Contacts",
                          showChevron: true,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyContacts),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text("Edit Profile", style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ACCOUNT SECTION
                  _ProfileCard(
                    label: "ACCOUNT MANAGEMENT",
                    child: Column(
                      children: [
                        _SecurityRow(
                          icon: Icons.pause_circle_outline,
                          iconColor: const Color(0xFFD4A017),
                          title: "Deactivate Account",
                          subtitle: "Temporarily disable your account",
                          showChevron: true,
                          onTap: () => _handleDeactivate(context),
                        ),
                        _SecurityRow(
                          icon: Icons.delete_forever_outlined,
                          iconColor: AppColors.danger,
                          title: "Delete Account",
                          subtitle: "Permanently delete your account",
                          showChevron: true,
                          onTap: () => _handleDeleteAccount(context),
                        ),
                        _SecurityRow(
                          icon: Icons.phonelink_erase_outlined,
                          iconColor: AppColors.textPrimary,
                          title: "Clear Device Data",
                          subtitle: "Wipe local app data",
                          showChevron: true,
                          onTap: () => _handleClearDeviceData(context),
                        ),
                      ],
                    ),
                  ),

                  // SIGN OUT
                  const SizedBox(height: 16),
                  ListTile(
                    onTap: () async {
                      await context.read<UserProvider>().logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.auth,
                          (_) => false,
                        );
                      }
                    },
                    leading: const Icon(Icons.logout, color: AppColors.danger),
                    title: Text("Sign Out",
                        style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeactivate(BuildContext context) async {
    final navigator = Navigator.of(context);
    final userProvider = context.read<UserProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Deactivate Account?"),
        content: const Text("Your account will be paused. Your data stays safe."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Deactivate")),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService().post('/api/auth/deactivate', data: {});
      } catch (_) {
        debugPrint('[Profile] Deactivate request failed, continuing with local reset.');
      }
      await userProvider.logout();
      await DeviceResetService.wipeAllLocalData();
      if (!mounted) return;
      navigator.pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final navigator = Navigator.of(context);
    final userProvider = context.read<UserProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text(
            "This will remove your account from this device and clear all local data. This action cannot be undone locally."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService().post('/api/auth/delete-account', data: {});
    } catch (e) {
      debugPrint('[Profile] Delete account request failed: $e');
    }

    await userProvider.logout();
    await DeviceResetService.wipeAllLocalData();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
  }

  Future<void> _handleClearDeviceData(BuildContext context) async {
    final navigator = Navigator.of(context);
    final userProvider = context.read<UserProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Device Data?"),
        content: const Text("This removes all locally stored data from this device."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Clear Data")),
        ],
      ),
    );
    if (confirmed == true) {
      await userProvider.logout();
      await DeviceResetService.wipeAllLocalData();
      if (!mounted) return;
      navigator.pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _ProfileCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 24),
          child: Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGrey;
  const _DetailRow({required this.label, required this.value, this.isGrey = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 12,
                color: isGrey ? AppColors.textSecondary : AppColors.textPrimary)),
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: isGrey ? FontWeight.normal : FontWeight.bold,
                color: isGrey ? AppColors.textSecondary : AppColors.textPrimary)),
      ],
    );
  }
}

class _SecurityRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SecurityRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (showChevron) const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showChevron;
  final VoidCallback? onTap;

  const _InfoField({
    required this.icon,
    required this.label,
    required this.value,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Text(value,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            if (showChevron) const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
