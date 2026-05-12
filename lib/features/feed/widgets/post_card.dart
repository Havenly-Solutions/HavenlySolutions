import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/post_model.dart';
import '../feed_provider.dart';
import 'user_profile_sheet.dart';
import '../../../Shared/theme/app_theme.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _currentUserId = prefs.getString('current_user_id'));
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('d MMM').format(dt);
  }

  void _showUserProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => UserProfileSheet(
        userId: widget.post.authorId,
        userName: widget.post.authorName,
        userAge: widget.post.authorAge,
        userRegion: widget.post.authorRegion,
      ),
    );
  }

  void _openReplies(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RepliesSheet(post: widget.post),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final isMissing = widget.post.type == PostType.missingPerson;
    String? reason;

    if (isMissing) {
      reason = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DeleteReasonSheet(post: widget.post),
      );
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Remove Post?', style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to remove this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirmed == true) reason = "News post removal";
    }

    if (reason != null) {
      if (!mounted) return;
      try {
        await context.read<FeedProvider>().deletePost(widget.post.id, reason);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove post. Please try again.'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMissing = widget.post.type == PostType.missingPerson;
    final isAuthor = _currentUserId == widget.post.authorId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMissing ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isMissing ? 'MISSING PERSON' : 'NEWS',
                    style: TextStyle(
                      color: isMissing ? AppTheme.primaryRed : Colors.grey.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(widget.post.createdAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                if (isAuthor) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _handleDelete(context),
                    icon: const Icon(Icons.delete_outline, color: AppTheme.primaryRed, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),

          if (isMissing && widget.post.imageLocalPath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              child: Image.file(
                File(widget.post.imageLocalPath!),
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: Colors.grey.shade100,
                  child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade300, size: 40),
                ),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.title != null)
                  Text(
                    widget.post.title!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Space Grotesk'),
                  ),
                if (widget.post.body != null && widget.post.body!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.post.body!,
                    style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 14, height: 1.5, fontFamily: 'DM Sans'),
                  ),
                ],

                if (isMissing && widget.post.contactPhone != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_outlined, color: AppTheme.primaryRed, size: 18),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.post.contactName != null)
                              Text(
                                widget.post.contactName!,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            Text(
                              widget.post.contactPhone!,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showUserProfile(context),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFF1F5F9),
                        child: Text(
                          widget.post.authorName.isNotEmpty ? widget.post.authorName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.post.authorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'DM Sans')),
                          if (widget.post.authorRegion != null)
                            Text(widget.post.authorRegion!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontFamily: 'DM Sans')),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openReplies(context),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, color: Colors.grey.shade400, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.post.replyCount}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteReasonSheet extends StatefulWidget {
  final PostModel post;
  const _DeleteReasonSheet({required this.post});

  @override
  State<_DeleteReasonSheet> createState() => _DeleteReasonSheetState();
}

class _DeleteReasonSheetState extends State<_DeleteReasonSheet> {
  String? _selectedReason;
  final _otherController = TextEditingController();
  final List<String> _reasons = [
    "Person has been found",
    "Posted in error",
    "Case resolved",
    "Duplicate post",
    "Other"
  ];

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_selectedReason == null) return false;
    if (_selectedReason == "Other") {
      return _otherController.text.trim().length >= 10;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Reason for Removal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: _reasons.map((r) => ChoiceChip(
              label: Text(r),
              selected: _selectedReason == r,
              onSelected: (val) => setState(() => _selectedReason = val ? r : null),
              selectedColor: const Color(0xFFFEE2E2),
              labelStyle: TextStyle(
                color: _selectedReason == r ? AppTheme.primaryRed : Colors.black87,
                fontWeight: _selectedReason == r ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'DM Sans',
              ),
              backgroundColor: Colors.grey.shade100,
            )).toList(),
          ),
          if (_selectedReason == "Other") ...[
            const SizedBox(height: 16),
            TextField(
              controller: _otherController,
              onChanged: (_) => setState(() {}),
              maxLines: 3,
              style: const TextStyle(fontFamily: 'DM Sans'),
              decoration: InputDecoration(
                hintText: "Please describe the reason...",
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 8),
            Text('Minimum 10 characters required.', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _canSubmit ? () {
                final result = _selectedReason == "Other" ? _otherController.text.trim() : _selectedReason;
                Navigator.pop(context, result);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Remove Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Space Grotesk')),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepliesSheet extends StatefulWidget {
  final PostModel post;
  const _RepliesSheet({required this.post});

  @override
  State<_RepliesSheet> createState() => _RepliesSheetState();
}

class _RepliesSheetState extends State<_RepliesSheet> {
  List<ReplyModel> _replies = [];
  bool _loading = true;
  final _replyController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final provider = context.read<FeedProvider>();
    final replies = await provider.getReplies(widget.post.id);
    if (mounted) {
      setState(() {
        _replies = replies;
        _loading = false;
      });
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);

    final prefs = await SharedPreferences.getInstance();
    final authorId = prefs.getString('current_user_id') ?? 'local_user';
    final authorName = prefs.getString('user_name') ?? 'Anonymous';
    final authorRegion = prefs.getString('user_region');

    await context.read<FeedProvider>().addReply(
          postId: widget.post.id,
          authorId: authorId,
          authorName: authorName,
          body: text,
          authorRegion: authorRegion,
        );

    _replyController.clear();
    await _load();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.post.title ?? 'Replies',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Flexible(
            child: _loading
                ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Colors.black)))
                : _replies.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No replies yet', style: TextStyle(color: Colors.grey, fontFamily: 'DM Sans')),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(24),
                        itemCount: _replies.length,
                        itemBuilder: (_, i) => _ReplyTile(reply: _replies[i]),
                      ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sending ? null : _sendReply,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                    child: _sending
                        ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  final ReplyModel reply;
  const _ReplyTile({required this.reply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFF1F5F9),
            child: Text(reply.authorName.isNotEmpty ? reply.authorName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reply.authorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'DM Sans')),
                const SizedBox(height: 4),
                Text(reply.body, style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 13, height: 1.4, fontFamily: 'DM Sans')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
