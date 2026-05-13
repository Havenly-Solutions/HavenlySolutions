import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/post_model.dart';

class NewsCard extends StatelessWidget {
  final PostModel post;
  final bool isFeatured;

  const NewsCard({
    required this.post,
    this.isFeatured = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isFeatured) {
      return _buildFeatured(context);
    }
    return _buildStandard(context);
  }

  Widget _buildFeatured(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.grey.shade200,
                child: post.imageLocalPath != null
                    ? (post.imageLocalPath!.startsWith('http')
                        ? Image.network(post.imageLocalPath!, fit: BoxFit.cover)
                        : (post.imageLocalPath!.isEmpty
                            ? const SizedBox()
                            : Image.asset(post.imageLocalPath!,
                                fit: BoxFit.cover)))
                    : const Center(
                        child: Icon(Icons.newspaper,
                            size: 64, color: Colors.grey)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategory(post.type.name.toUpperCase()),
                const SizedBox(height: 12),
                Text(
                  post.title ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    fontFamily: 'serif',
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  post.body ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMeta(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategory(post.type.name.toUpperCase()),
                const SizedBox(height: 8),
                Text(
                  post.title ?? 'Untitled',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildMeta(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 100,
              height: 100,
              color: Colors.grey.shade100,
              child: post.imageLocalPath != null
                  ? (post.imageLocalPath!.startsWith('http')
                      ? Image.network(post.imageLocalPath!, fit: BoxFit.cover)
                      : (post.imageLocalPath!.isEmpty
                          ? const SizedBox()
                          : Image.asset(post.imageLocalPath!,
                              fit: BoxFit.cover)))
                  : const Center(
                      child: Icon(Icons.image_outlined, color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFC0392B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFC0392B),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildMeta() {
    return Row(
      children: [
        Text(
          (post.authorRegion ?? 'Nationwide').toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(width: 8),
        Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.grey.shade400)),
        const SizedBox(width: 8),
        Text(
          DateFormat('HH:mm \u2022 dd MMM').format(post.createdAt),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
