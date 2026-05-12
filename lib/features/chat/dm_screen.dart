import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/local_db.dart';
import '../../core/models/conversation_model.dart';

class DmScreen extends StatefulWidget {
  final String participantId;
  final String participantName;

  const DmScreen({
    super.key,
    required this.participantId,
    required this.participantName,
  });

  @override
  State<DmScreen> createState() => _DmScreenState();
}

class _DmScreenState extends State<DmScreen> {
  List<MessageModel> _messages = [];
  bool _loading = true;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _myId = '';
  String _myName = '';
  String? _conversationId;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _myId = prefs.getString('current_user_id') ?? 'local_user';
    _myName = prefs.getString('user_name') ?? 'Me';
    
    // Find or create conversation
    final conversations = await LocalDb.getConversations();
    final existing = conversations.firstWhere(
      (c) => c['participant_id'] == widget.participantId,
      orElse: () => <String, dynamic>{},
    );

    if (existing.isNotEmpty) {
      _conversationId = existing['id'];
      await _loadMessages();
    } else {
      _conversationId = _uuid.v4();
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    final rows = await LocalDb.getMessages(_conversationId!);
    if (mounted) {
      setState(() {
        _messages = rows.map(MessageModel.fromMap).toList();
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _conversationId == null) return;
    _controller.clear();

    final now = DateTime.now();
    final msg = MessageModel(
      id: _uuid.v4(),
      conversationId: _conversationId!,
      senderId: _myId,
      senderName: _myName,
      body: text,
      createdAt: now,
    );

    await LocalDb.insertMessage(msg.toMap());

    // Update conversation last message
    await LocalDb.upsertConversation({
      'id': _conversationId,
      'participant_id': widget.participantId,
      'participant_name': widget.participantName,
      'last_message': text,
      'last_message_at': now.millisecondsSinceEpoch,
      'unread_count': 0,
    });

    if (mounted) {
      setState(() => _messages.add(msg));
      _scrollToBottom();
    }
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF1F5F9),
              child: Text(
                widget.participantName.isNotEmpty ? widget.participantName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.participantName,
              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _messages.isEmpty
                    ? Center(child: Text('Start the conversation.', style: TextStyle(color: Colors.grey.shade400)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMine = msg.senderId == _myId;
                          return _Bubble(
                            msg: msg,
                            isMine: isMine,
                            timeLabel: _timeLabel(msg.createdAt),
                          );
                        },
                      ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMine;
  final String timeLabel;

  const _Bubble({required this.msg, required this.isMine, required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMine ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 20 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.body,
              style: TextStyle(color: isMine ? Colors.white : Colors.black, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              timeLabel,
              style: TextStyle(color: isMine ? Colors.white70 : Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
