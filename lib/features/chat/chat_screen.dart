import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/translations.dart';
import '../../core/models/community_channel_model.dart';
import '../../core/providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/socket_service.dart';
import '../../Shared/theme/app_theme.dart';
import 'chat_provider.dart';
import 'community_chat_screen.dart';
import 'dm_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<CommunityChannel> _communityChannels;
  bool _connectListenerRegistered = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _communityChannels = [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().syncContacts();
      _subscribeToCommunityChannel();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<UserProvider>().currentUser;
    if (user?.id != _currentUserId) {
      _currentUserId = user?.id;
      _buildCommunityChannels();
      _subscribeToCommunityChannel();
    }
  }

  void _buildCommunityChannels() {
    final user = context.read<UserProvider>().currentUser;
    final normalizedCommunity = user?.community.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

    _communityChannels = [
      if (normalizedCommunity != null && normalizedCommunity.isNotEmpty)
        CommunityChannel(
          id: normalizedCommunity,
          title: '${user?.community ?? 'Community'} Watch',
          subtitle: 'Chat with neighbours and volunteer responders',
          lastMessage: 'Local community updates and support messages.',
          unreadCount: 0,
        ),
      const CommunityChannel(
        id: 'sentinel',
        title: 'Sentinel Broadcast',
        subtitle: 'Safety updates for your area',
        lastMessage: 'Briefings and emergency alerts delivered to your community.',
        unreadCount: 2,
      ),
      const CommunityChannel(
        id: 'support',
        title: 'Local Support Group',
        subtitle: 'Volunteer network chat',
        lastMessage: 'Share tips, coordinate watches, and support neighbors.',
        unreadCount: 0,
      ),
    ];
  }

  void _subscribeToCommunityChannel() {
    final userProvider = context.read<UserProvider>();
    final socketService = context.read<SocketService>();
    final user = userProvider.currentUser;

    if (user == null) return;

    if (socketService.isConnected) {
      _joinCommunityChannel(user.community);
    } else if (!_connectListenerRegistered) {
      socketService.on('connect', _handleSocketConnect);
      _connectListenerRegistered = true;
    }

    socketService.on('community:message', (payload) {
      if (!mounted) return;
      final message = payload is Map<String, dynamic>
          ? payload['body']?.toString() ?? ''
          : payload.toString();
      if (message.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppTranslations.t('chat_community')}: $message')),
      );
    });
  }

  void _handleSocketConnect(dynamic _) {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;
    _joinCommunityChannel(user.community);
  }

  void _joinCommunityChannel(String community) {
    final socketService = context.read<SocketService>();
    if (!socketService.isConnected || community.trim().isEmpty) {
      return;
    }

    final channelId = community.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    socketService.emit('community:join', {'channelId': channelId});
  }

  @override
  void dispose() {
    final socketService = context.read<SocketService>();
    socketService.off('community:message');
    if (_connectListenerRegistered) {
      socketService.off('connect');
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey.shade400,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Space Grotesk'),
          tabs: [
            Tab(text: AppTranslations.t('chat_community')),
            Tab(text: AppTranslations.t('chat_contacts')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCommunityTab(),
          _buildContactsTab(chatProvider),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      itemCount: _communityChannels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final channel = _communityChannels[index];
        final isBroadcast = channel.id == 'sentinel';
        return _ChatCard(
          title: channel.title,
          subtitle: channel.subtitle,
          icon: channel.id == 'support' ? Icons.people_outline : Icons.notifications_active_outlined,
          color: isBroadcast ? AppTheme.primaryRed : Colors.black,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommunityChatScreen(
                  channelId: channel.id,
                  title: channel.title,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContactsTab(ChatProvider provider) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      children: [
        if (provider.matchedUsers.isNotEmpty) ...[
          _buildSectionHeader('ON HAVENLY SOLUTIONS'),
          ...provider.matchedUsers.map((m) => _ChatCard(
                title: m['contact'].displayName,
                subtitle: m['user']['community_name'] ?? 'In your area',
                icon: Icons.person_outline,
                color: Colors.black,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DmScreen(
                      participantId: m['user']['id'],
                      participantName: m['contact'].displayName,
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 24),
        ],
        if (provider.unmatchedContacts.isNotEmpty) ...[
          _buildSectionHeader('INVITE TO HAVENLY SOLUTIONS'),
          ...provider.unmatchedContacts.take(20).map((c) => _InviteTile(
                name: c.displayName,
                onInvite: () => _inviteContact(c.phones.first.number),
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _inviteContact(String phone) async {
    final msg = "${AppTranslations.t('invite_msg')} https://havenly-solutions.app/download";
    final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ChatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ChatCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Color.fromARGB(
                  25,
                  (color.toARGB32() >> 16) & 0xFF,
                  (color.toARGB32() >> 8) & 0xFF,
                  color.toARGB32() & 0xFF,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Space Grotesk')),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InviteTile extends StatelessWidget {
  final String name;
  final VoidCallback onInvite;

  const _InviteTile({required this.name, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF1F5F9),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          TextButton(
            onPressed: onInvite,
            child: const Text('Invite', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
