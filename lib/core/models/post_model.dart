// File: lib/core/models/post_model.dart
// Havenly Solutions (Pty) Ltd

enum PostType { safety, police, community, news, missingPerson }

class PostModel {
  final String id;
  final PostType type;
  final String? title;
  final String? body;
  final String? imageLocalPath;
  final String? contactName;
  final String? contactPhone;
  final String authorId;
  final String authorName;
  final int? authorAge;
  final String? authorRegion;
  final int replyCount;
  final DateTime createdAt;
  final bool synced;

  const PostModel({
    required this.id,
    required this.type,
    this.title,
    this.body,
    this.imageLocalPath,
    this.contactName,
    this.contactPhone,
    required this.authorId,
    required this.authorName,
    this.authorAge,
    this.authorRegion,
    this.replyCount = 0,
    required this.createdAt,
    this.synced = false,
  });

  PostModel copyWith({
    String? id,
    PostType? type,
    String? title,
    String? body,
    String? imageLocalPath,
    String? contactName,
    String? contactPhone,
    String? authorId,
    String? authorName,
    int? authorAge,
    String? authorRegion,
    int? replyCount,
    DateTime? createdAt,
    bool? synced,
  }) {
    return PostModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAge: authorAge ?? this.authorAge,
      authorRegion: authorRegion ?? this.authorRegion,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  factory PostModel.fromMap(Map<String, dynamic> m) {
    return PostModel(
      id: m['id'] as String,
      type: m['type'] == 'missing_person'
          ? PostType.missingPerson
          : PostType.news,
      title: m['title'] as String?,
      body: m['body'] as String?,
      imageLocalPath: m['image_local_path'] as String?,
      contactName: m['contact_name'] as String?,
      contactPhone: m['contact_phone'] as String?,
      authorId: m['author_id'] as String,
      authorName: m['author_name'] as String,
      authorAge: m['author_age'] as int?,
      authorRegion: m['author_region'] as String?,
      replyCount: m['reply_count'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      synced: (m['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type == PostType.missingPerson ? 'missing_person' : 'news',
      'title': title,
      'body': body,
      'image_local_path': imageLocalPath,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'author_id': authorId,
      'author_name': authorName,
      'author_age': authorAge,
      'author_region': authorRegion,
      'reply_count': replyCount,
      'created_at': createdAt.millisecondsSinceEpoch,
      'synced': synced ? 1 : 0,
    };
  }
}

class ReplyModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorRegion;
  final String body;
  final DateTime createdAt;

  const ReplyModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorRegion,
    required this.body,
    required this.createdAt,
  });

  factory ReplyModel.fromMap(Map<String, dynamic> m) {
    return ReplyModel(
      id: m['id'] as String,
      postId: m['post_id'] as String,
      authorId: m['author_id'] as String,
      authorName: m['author_name'] as String,
      authorRegion: m['author_region'] as String?,
      body: m['body'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'author_id': authorId,
      'author_name': authorName,
      'author_region': authorRegion,
      'body': body,
      'created_at': createdAt.millisecondsSinceEpoch,
      'synced': 0,
    };
  }
}
