import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Image.asset('assets/images/logo.png', width: 22, height: 22),
        ),
        title: Text('Havenly', style: AppTypography.heading2.copyWith(fontSize: 18, color: AppColors.darkNav)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileCard(user),
            _buildSection(
              icon: Icons.person_outline,
              title: 'Account Details',
              items: [
                _buildActionRow('Personal Information', onTap: () => context.push('/profile/edit')),
                _buildActionRow('Billing & Subscriptions'),
                _buildActionRow('Connected Devices'),
              ],
            ),
            _buildSection(
              icon: Icons.lock_outline,
              title: 'Security Settings',
              items: [
                _buildActionRow('Password & Authentication'),
                _buildActionRow('Two-Factor Setup', badge: true),
                _buildActionRow('Active Sessions'),
              ],
            ),
            _buildSection(
              icon: Icons.notifications_none_outlined,
              title: 'Notification Preferences',
              items: [
                _buildToggleRow('Push Alerts', true),
                _buildToggleRow('Email Digests', false),
                _buildToggleRow('SMS Updates', true),
              ],
            ),
            _buildSection(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Settings',
              items: [
                _buildActionRow('Data Sharing'),
                _buildActionRow('Location Services'),
                _buildActionRow('Delete Account', isDestructive: true, onTap: () => _confirmDelete(context)),
              ],
            ),
            const SizedBox(height: 32),
            _buildSignOutButton(context, ref),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(User? user) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/logo.png'),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFF2D4F4F), shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? 'Eleanor Vance', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3D3D))),
          Text(user?.email ?? 'eleanor.vance@example.com', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusBadge(null, 'Protected', const Color(0xFF2D4F4F), logo: true),
              const SizedBox(width: 8),
              _buildStatusBadge(null, 'Premium Plan', Colors.grey[200]!, textColor: Colors.black87),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(IconData? icon, String text, Color color, {Color textColor = Colors.white, bool logo = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          if (logo) ...[
            Image.asset('assets/images/logo.png', width: 12, height: 12),
            const SizedBox(width: 4)
          ] else if (icon != null) ...[
            Icon(icon, color: textColor, size: 12),
            const SizedBox(width: 4)
          ],
          Text(text, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required List<Widget> items}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF1A3D3D)),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A3D3D))),
              ],
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildActionRow(String title, {bool badge = false, bool isDestructive = false, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      title: Text(title, style: TextStyle(fontSize: 14, color: isDestructive ? Colors.red[800] : Colors.black87)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Switch(value: value, onChanged: (v) {}, activeColor: const Color(0xFF1A3D3D)),
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          ref.read(userProvider.notifier).logout();
          context.go('/auth');
        },
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Sign Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black87,
          minimumSize: const Size(140, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action is permanent and will remove all your safety data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
