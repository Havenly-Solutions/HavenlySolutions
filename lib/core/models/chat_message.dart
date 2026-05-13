enum MessageType { text, image, voice, location }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String body;
  final MessageType type;
  final DateTime createdAt;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isMe = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: json['senderAvatar'] as String?,
      body: json['body'] as String,
      type: MessageType.values.byName(json['type'] as String? ?? 'text'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isMe: json['senderId'] == currentUserId,
    );
  }
}

class ChatThread {
  final String id;
  final String name;
  final String? avatar;
  final ChatMessage lastMessage;
  final int unreadCount;
  final bool isCommunity;

  ChatThread({
    required this.id,
    required this.name,
    this.avatar,
    required this.lastMessage,
    this.unreadCount = 0,
    this.isCommunity = false,
  });
}
