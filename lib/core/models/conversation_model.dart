// File: lib/core/models/conversation_model.dart
// Havenly Solutions (Pty) Ltd

class ConversationModel {
  final String id;
  final String participantId;
  final String participantName;
  final int? participantAge;
  final String? participantRegion;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAge,
    this.participantRegion,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> m) {
    return ConversationModel(
      id: m['id'] as String,
      participantId: m['participant_id'] as String,
      participantName: m['participant_name'] as String,
      participantAge: m['participant_age'] as int?,
      participantRegion: m['participant_region'] as String?,
      lastMessage: m['last_message'] as String?,
      lastMessageAt: m['last_message_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['last_message_at'] as int)
          : null,
      unreadCount: m['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participant_id': participantId,
      'participant_name': participantName,
      'participant_age': participantAge,
      'participant_region': participantRegion,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.millisecondsSinceEpoch,
      'unread_count': unreadCount,
    };
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime createdAt;
  final bool synced;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
    this.synced = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> m) {
    return MessageModel(
      id: m['id'] as String,
      conversationId: m['conversation_id'] as String,
      senderId: m['sender_id'] as String,
      senderName: m['sender_name'] as String,
      body: m['body'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      synced: (m['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'body': body,
      'created_at': createdAt.millisecondsSinceEpoch,
      'synced': synced ? 1 : 0,
    };
  }
}
