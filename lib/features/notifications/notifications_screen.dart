import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: AppTypography.heading2),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(onPressed: () {}, child: const Text('Mark all read')),
        ],
      ),
      body: ListView(
        children: [
          _buildNotificationItem(
            icon: Icons.error,
            color: AppColors.emergency,
            title: 'SOS Alert Nearby',
            body: 'An SOS was triggered in your community. Stay safe and aware.',
            time: '2m ago',
          ),
          _buildNotificationItem(
            icon: Icons.person_search,
            color: AppColors.orange,
            title: 'Missing Person Reported',
            body: 'A new missing person report was filed in Sector 4.',
            time: '1h ago',
          ),
          _buildNotificationItem(
            icon: Icons.info_outline,
            color: AppColors.brandDeep,
            title: 'Community Update',
            body: 'A new post was added to the news feed.',
            time: '3h ago',
          ),
          _buildNotificationItem(
            icon: Icons.chat_bubble_outline,
            color: Colors.blue,
            title: 'New Message',
            body: 'You have an unread message from the community leader.',
            time: '5h ago',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required String time,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text(body, style: AppTypography.bodySmall),
      trailing: Text(time, style: AppTypography.label.copyWith(color: AppColors.textMuted)),
      onTap: () {},
    );
  }
}
