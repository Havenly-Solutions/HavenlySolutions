/*
 * ─────────────────────────────────────────────────────────────
 * FILE: mobile/lib/features/support/ui/leader_support_chat_screen.dart
 * PHASE: 8 — Leader Support Chat
 *
 * PURPOSE:
 *   Shows support messages between the current community leader and
 *   Havenly Solutions support staff. Messages are loaded from the
 *   backend support_messages table and can be sent from the mobile UI.
 *
 *   This screen is intentionally simple: it supports message feed
 *   display, text entry, and send action.
 *
 * HOW TO EXTEND:
 *   Phase 19 adds image attachments and reply threading.
 *   Phase 20 adds unread badge counts and real-time socket updates.
 * ─────────────────────────────────────────────────────────────
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Shared/theme/app_theme.dart';

class LeaderSupportChatScreen extends StatefulWidget {
  const LeaderSupportChatScreen({super.key});

  @override
  State<LeaderSupportChatScreen> createState() =>
      _LeaderSupportChatScreenState();
}

class _LeaderSupportChatScreenState extends State<LeaderSupportChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    // TODO: implement backend fetch from /api/support/messages or /support/messages
    await Future<void>.delayed(const Duration(milliseconds: 300));
    setState(() {
      _messages.clear();
      _messages.addAll([]);
      _loading = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      // TODO: implement backend post to /api/support/messages
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _controller.clear();
      setState(() {
        _messages.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch,
          'body': text,
          'isLeader': true,
          'sentAt': DateTime.now().toIso8601String(),
        });
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Havenly Support Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No support messages yet.'))
                    : ListView.separated(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isLeader = message['isLeader'] == true;
                          return Align(
                            alignment: isLeader
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isLeader
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['body'] as String,
                                    style: TextStyle(
                                      color: isLeader
                                          ? Colors.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    message['sentAt'] as String,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Write a message to Havenly support',
                        hintStyle: GoogleFonts.dmSans(
                            color: AppColors.textSecondary, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _sending ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(14),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
