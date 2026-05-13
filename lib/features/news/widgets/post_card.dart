import 'package:flutter/material.dart';
import '../../../core/models/feed_post.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final FeedPost post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.type == PostType.missingPerson)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Text(
                'MISSING PERSON',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.backgroundLight,
                      backgroundImage: post.authorAvatar != null ? NetworkImage(post.authorAvatar!) : null,
                      child: post.authorAvatar == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.authorName, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          Text('@${post.handle ?? "user"} · ${timeago.format(post.createdAt)}', style: AppTypography.label.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(post.body, style: AppTypography.bodyLarge),
                if (post.images.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(post.images.first, fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildAction(Icons.favorite_border, post.likeCount.toString()),
                    const SizedBox(width: 24),
                    _buildAction(Icons.chat_bubble_outline, post.commentCount.toString()),
                    const Spacer(),
                    const Icon(Icons.share_outlined, color: AppColors.textMuted, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 4),
        Text(count, style: AppTypography.label.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}
