import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/translations.dart';
import '../../core/theme/app_typography.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 22, height: 22),
            const SizedBox(width: 8),
            Text(AppTranslations.t('safety_communications'),
                style: AppTypography.heading2.copyWith(fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black),
              onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppTranslations.t('communications_hub'),
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1)),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.t('communications_description'),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

            _buildSectionHeader(AppTranslations.t('direct_messages'),
                badge: AppTranslations.t('new_messages_label')),
            _buildDirectMessageItem(context, 'Det. Jane Doe',
                'Reporting clear on the North side...', '10:42 AM',
                isActive: true),
            _buildDirectMessageItem(context, 'Dispatcher Brown',
                'Understood. Log entry #9921 has...', 'Yesterday'),

            const SizedBox(height: 32),
            _buildSectionHeader(AppTranslations.t('community_rooms')),
            _buildCommunityRoomItem(
              context,
              AppTranslations.t('downtown_safety_watch'),
              AppTranslations.t('active_members', args: ['248']),
              AppTranslations.t('officer_smith_update'),
              '5m ago',
              Icons.hub_outlined,
            ),
            _buildCommunityRoomItem(
              context,
              AppTranslations.t('emergency_responders'),
              AppTranslations.t('active_members', args: ['12']),
              AppTranslations.t('sgt_miller_update'),
              '12m ago',
              Icons.groups_outlined,
              isAlert: true,
            ),

            const SizedBox(height: 120), // Space for floating nav
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // Above floating nav
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.black,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      bottomNavigationBar: _buildInternalNav(),
    );
  }

  Widget _buildSectionHeader(String title, {String? badge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.black87)),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(12)),
              child: Text(badge,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildDirectMessageItem(
      BuildContext context, String name, String msg, String time,
      {bool isActive = false}) {
    return ListTile(
      onTap: () => context
          .push('/chat/1?title=\$name&subtitle=Active Case: #2024-DM-0912'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Stack(
        children: [
          const CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage('assets/images/logo.png')),
          if (isActive)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
      subtitle: Text(msg,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[700], fontSize: 13)),
    );
  }

  Widget _buildCommunityRoomItem(BuildContext context, String title,
      String members, String lastMsg, String time, IconData icon,
      {bool isAlert = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => context
                .push('/chat/community?title=\$title&subtitle=\$members'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color:
                            isAlert ? Colors.blue[50] : const Color(0xFF1A1C1E),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon,
                        color: isAlert ? Colors.blue : Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(AppTranslations.t('moderated'),
                                  style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey)),
                            ),
                          ],
                        ),
                        Text(members,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11)),
                        const SizedBox(height: 12),
                        Text(lastMsg,
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppTranslations.t('last_activity', args: [time]),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                TextButton(
                    onPressed: () =>
                        context.push('/chat/community?title=\$title'),
                    child: Text(AppTranslations.t('join_room'),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalNav() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInternalNavItem(Icons.chat_bubble, 'Chats', true),
          _buildInternalNavItem(Icons.hub_outlined, 'Rooms', false),
          _buildInternalNavItem(Icons.notifications_none, 'Alerts', false),
          _buildInternalNavItem(
              Icons.contact_page_outlined, 'Directory', false),
        ],
      ),
    );
  }

  Widget _buildInternalNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: isSelected ? const Color(0xFF1A1C1E) : Colors.grey[400],
            size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: isSelected ? const Color(0xFF1A1C1E) : Colors.grey[400],
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
