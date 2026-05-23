import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;
  final bool isCommunity;

  const ChatDetailScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.isCommunity = false,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text':
          'Good afternoon, this is Sgt. Miller. I\'m following up on the report you filed regarding the incident at the downtown parking garage. Do you have a moment to answer a few clarifying questions?',
      'time': '14:02',
    },
    {
      'isMe': true,
      'text':
          'Yes, I\'m available now. I also found a photo of the vehicle that might help. Should I send it here?',
      'time': '14:05',
    },
    {
      'isMe': false,
      'text':
          'That would be very helpful. Please upload it using the attachment icon below. Ensure the license plate is visible if possible.',
      'time': '14:06',
    }
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'isMe': true,
        'text': _messageController.text.trim(),
        'time': '14:07',
      });
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/images/logo.png')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  if (widget.subtitle != null)
                    Text(widget.subtitle!,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.phone_outlined, color: Colors.black87),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('TODAY, SEPT 24',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(
                    msg['text'], msg['isMe'], msg['time']);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMe ? Colors.black : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isMe ? 12 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 12),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(time,
                  style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(Icons.done_all, size: 12, color: Colors.grey),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration:
                BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!)),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Write an official message...',
                  hintStyle: TextStyle(fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                  color: Colors.black, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
