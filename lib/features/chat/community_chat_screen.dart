import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/community_message_model.dart';
import '../../core/providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/socket_service.dart';
import '../../Shared/theme/app_theme.dart';

class CommunityChatScreen extends StatefulWidget {
  final String channelId;
  final String title;

  const CommunityChatScreen({
    super.key,
    required this.channelId,
    required this.title,
  });

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final List<CommunityMessageModel> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();
  bool _isJoining = true;
  bool _connectListenerAdded = false;

  @override
  void initState() {
    super.initState();
    _joinChannel();
  }

  @override
  void dispose() {
    _leaveChannel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _joinChannel() async {
    final userProvider = context.read<UserProvider>();
    final socketService = context.read<SocketService>();
    final user = userProvider.currentUser;

    if (user == null) {
      setState(() => _isJoining = false);
      return;
    }

    if (!socketService.isConnected) {
      if (!_connectListenerAdded) {
        socketService.on('connect', (_) {
          if (!mounted) return;
          _joinChannel();
        });
        _connectListenerAdded = true;
      }
      setState(() => _isJoining = true);
      return;
    }

    setState(() => _isJoining = true);
    socketService.emit('community:join', {'channelId': widget.channelId});
    socketService.on('community:message', _handleIncomingMessage);
    socketService.on('community:joined', (_) {
      if (!mounted) return;
      setState(() => _isJoining = false);
    });
  }

  void _leaveChannel() {
    final socketService = context.read<SocketService>();
    socketService.emit('community:leave', {'channelId': widget.channelId});
    socketService.off('community:message');
    socketService.off('community:joined');
    if (_connectListenerAdded) {
      socketService.off('connect');
    }
  }

  void _handleIncomingMessage(dynamic payload) {
    final message = CommunityMessageModel.fromSocket(payload);
    if (message.channelId != widget.channelId) return;

    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    if (user == null) return;

    final message = CommunityMessageModel(
      id: _uuid.v4(),
      channelId: widget.channelId,
      senderId: user.id,
      senderName: user.fullName,
      body: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(message);
    });
    _controller.clear();
    _scrollToBottom();

    final socketService = context.read<SocketService>();
    socketService.emit('community:message', {
      'id': message.id,
      'channelId': message.channelId,
      'senderId': message.senderId,
      'senderName': message.senderName,
      'body': message.body,
      'createdAt': message.createdAt.millisecondsSinceEpoch,
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isJoining
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryRed))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Start the conversation.',
                          style: TextStyle(color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMine = msg.senderId ==
                              context.read<UserProvider>().currentUser?.id;
                          return _CommunityBubble(message: msg, isMine: isMine);
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                        color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
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

class _CommunityBubble extends StatelessWidget {
  final CommunityMessageModel message;
  final bool isMine;

  const _CommunityBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
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
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    message.senderName,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ),
              Text(
                message.body,
                style: TextStyle(
                    color: isMine ? Colors.white : Colors.black87,
                    fontSize: 14,
                    height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                    color: isMine ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
