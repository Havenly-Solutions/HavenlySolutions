enum PostType { standard, missingPerson }

class FeedPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? handle;
  final String body;
  final PostType type;
  final List<String> images;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool isLiked;

  // Missing Person specific fields
  final String? mpName;
  final String? mpSurname;
  final int? mpAge;
  final String? mpLastSeen;
  final String? mpContactName;
  final String? mpContactPhone;

  FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.handle,
    required this.body,
    required this.type,
    this.images = const [],
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.mpName,
    this.mpSurname,
    this.mpAge,
    this.mpLastSeen,
    this.mpContactName,
    this.mpContactPhone,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      handle: json['handle'] as String?,
      body: json['body'] as String,
      type: PostType.values.byName(json['type'] as String? ?? 'standard'),
      images: (json['images'] as List?)?.map((e) => e as String).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      mpName: json['mpName'] as String?,
      mpSurname: json['mpSurname'] as String?,
      mpAge: json['mpAge'] as int?,
      mpLastSeen: json['mpLastSeen'] as String?,
      mpContactName: json['mpContactName'] as String?,
      mpContactPhone: json['mpContactPhone'] as String?,
    );
  }
}
