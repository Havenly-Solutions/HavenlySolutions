// File: lib/core/models/community_message_model.dart
// Havenly Solutions (Pty) Ltd

class CommunityMessageModel {
  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime createdAt;

  const CommunityMessageModel({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  factory CommunityMessageModel.fromMap(Map<String, dynamic> map) {
    return CommunityMessageModel(
      id: map['id'] as String,
      channelId: map['channel_id'] as String,
      senderId: map['sender_id'] as String,
      senderName: map['sender_name'] as String,
      body: map['body'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  factory CommunityMessageModel.fromSocket(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return CommunityMessageModel(
        id: payload['id'] as String? ??
            payload['messageId'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        channelId: payload['channelId'] as String? ?? '',
        senderId: payload['senderId'] as String? ?? 'unknown',
        senderName: payload['senderName'] as String? ?? 'Unknown',
        body: payload['body'] as String? ?? '',
        createdAt: payload['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(payload['createdAt'] as int)
            : DateTime.now(),
      );
    }
    return CommunityMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      channelId: '',
      senderId: 'unknown',
      senderName: 'Unknown',
      body: payload.toString(),
      createdAt: DateTime.now(),
    );
  }
}
