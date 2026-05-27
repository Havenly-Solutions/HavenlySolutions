import 'package:flutter/material.dart';
import '../../../core/models/feed_post.dart';
import '../../../core/theme/app_colors.dart';

class MissingPersonCard extends StatelessWidget {
  final FeedPost post;
  const MissingPersonCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final status = post.mpStatus ?? MissingStatus.MISSING;
    final borderColor = status == MissingStatus.MISSING 
        ? AppColors.primary 
        : (status == MissingStatus.FOUND ? AppColors.success : Colors.grey);

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (post.images.isNotEmpty)
              Image.network(post.images.first, fit: BoxFit.cover)
            else
              Container(color: Colors.grey[300], child: const Icon(Icons.person, size: 40)),
            
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Text(
                  post.mpName ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            if (status != MissingStatus.MISSING)
              Container(
                color: Colors.black45,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.name,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
