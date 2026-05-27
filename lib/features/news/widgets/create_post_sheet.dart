import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/feed_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class CreatePostSheet extends ConsumerStatefulWidget {
  const CreatePostSheet({super.key});

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isPosting = true);
    final user = ref.read(userProvider);

    await ref.read(feedProvider.notifier).createPost({
      'type': 'standard',
      'content': _controller.text.trim(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Create Post', style: AppTypography.heading1),
              TextButton(
                onPressed: _isPosting ? null : _submit,
                child: _isPosting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Post',
                        style: TextStyle(
                            color: AppColors.emergency,
                            fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "What's happening in your community?",
              border: InputBorder.none,
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.image_outlined,
                      color: AppColors.brandDeep),
                  onPressed: () {}),
              IconButton(
                  icon: const Icon(Icons.location_on_outlined,
                      color: AppColors.brandDeep),
                  onPressed: () {}),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
