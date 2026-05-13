// File: lib/core/models/case_model.dart
// Havenly Solutions (Pty) Ltd

enum SyncStatus { pending, syncing, synced, failed }

class CaseModel {
  final String id;
  final String userId;
  final String community;
  final String category;
  final String description;
  final String evidence;
  final String status;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseModel({
    required this.id,
    required this.userId,
    required this.community,
    required this.category,
    required this.description,
    required this.evidence,
    required this.status,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSynced => syncStatus == SyncStatus.synced;

  factory CaseModel.fromMap(Map<String, dynamic> map) {
    final rawStatus = map['sync_status'] as String? ?? 'pending';
    return CaseModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      community: map['community'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      evidence: map['evidence'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      syncStatus: _parseSyncStatus(rawStatus),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
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
      'sync_status': syncStatus.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
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
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      community: community ?? this.community,
      category: category ?? this.category,
      description: description ?? this.description,
      evidence: evidence ?? this.evidence,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

SyncStatus _parseSyncStatus(String raw) {
  switch (raw) {
    case 'syncing':
      return SyncStatus.syncing;
    case 'synced':
      return SyncStatus.synced;
    case 'failed':
      return SyncStatus.failed;
    case 'pending':
    default:
      return SyncStatus.pending;
  }
}
