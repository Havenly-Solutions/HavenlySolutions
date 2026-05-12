// File: lib/features/feed/widgets/user_profile_sheet.dart
// Havenly Solutions (Pty) Ltd
// Tapping a user's avatar shows their profile + contact button

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/local_db.dart';
import '../../../core/models/conversation_model.dart';
import '../../chat/dm_screen.dart';

class UserProfileSheet extends StatelessWidget {
  final String userId;
  final String userName;
  final int? userAge;
  final String? userRegion;

  const UserProfileSheet({
    super.key,
    required this.userId,
    required this.userName,
    this.userAge,
    this.userRegion,
  });

  Future<void> _openDm(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final myId = prefs.getString('user_id') ?? 'local_user';

    // Derive a stable conversation ID from both user IDs
    final ids = [myId, userId]..sort();
    final conversationId = ids.join('_');

    final conversation = ConversationModel(
      id: conversationId,
      participantId: userId,
      participantName: userName,
      participantAge: userAge,
      participantRegion: userRegion,
    );

    await LocalDb.upsertConversation(conversation.toMap());

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DmScreen(
            participantId: userId,
            participantName: userName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade100, width: 2),
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (userAge != null || userRegion != null) ...[
            Text(
              [
                if (userAge != null) 'Age $userAge',
                if (userRegion != null) userRegion!,
              ].join('  ·  '),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
            const SizedBox(height: 32),
          ] else
            const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _openDm(context),
              icon: const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.white),
              label: const Text(
                'Send Message',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
