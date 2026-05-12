// File: lib/core/models/community_channel_model.dart
// Havenly Solutions (Pty) Ltd

class CommunityChannel {
  final String id;
  final String title;
  final String subtitle;
  final String lastMessage;
  final int unreadCount;

  const CommunityChannel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.lastMessage = '',
    this.unreadCount = 0,
  });
}
