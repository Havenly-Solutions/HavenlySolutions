// File: lib/core/models/case_model.dart
// Havenly Solutions (Pty) Ltd

class CaseModel {
  final String id;
  final String userId;
  final String community;
  final String category;
  final String description;
  final String evidence;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  const CaseModel({
    required this.id,
    required this.userId,
    required this.community,
    required this.category,
    required this.description,
    required this.evidence,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.synced,
  });

  factory CaseModel.fromMap(Map<String, dynamic> map) {
    return CaseModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      community: map['community'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      evidence: map['evidence'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'community': community,
      'category': category,
      'description': description,
      'evidence': evidence,
      'status': status,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'synced': synced ? 1 : 0,
    };
  }

  CaseModel copyWith({
    String? id,
    String? userId,
    String? community,
    String? category,
    String? description,
    String? evidence,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return CaseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      community: community ?? this.community,
      category: category ?? this.category,
      description: description ?? this.description,
      evidence: evidence ?? this.evidence,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}
