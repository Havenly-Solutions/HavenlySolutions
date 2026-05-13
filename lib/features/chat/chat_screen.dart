// FILE: mobile/lib/features/chat/chat_screen.dart
// Phase 9/10 — WhatsApp-style chat hub
// Tabs: Community Chat | Contacts
// Overflow fix: TabBarView wrapped in Expanded

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Shared/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Havenly Chat',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.search,
                        color: AppColors.textPrimary, size: 22),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert,
                        color: AppColors.textPrimary, size: 22),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // TabBar — no overflow because TabBarView is Expanded below
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Community Chat'),
                Tab(text: 'Contacts'),
              ],
            ),

            // THIS IS THE FIX FOR THE OVERFLOW:
            // TabBarView must be in Expanded so it fills remaining space
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _CommunityChatTab(),
                  _ContactsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── COMMUNITY CHAT TAB ────────────────────────────────────────

class _CommunityChatTab extends StatelessWidget {
  const _CommunityChatTab();

  @override
  Widget build(BuildContext context) {
    // Static community rooms — in production these come from the
    // user's community_id and nearby communities via backend.
    final rooms = [
      _RoomData(
        name: 'Benmore Watch',
        subtitle: 'Chat with neighbours and volunteer responders',
        icon: Icons.notifications_active_outlined,
        iconColor: AppColors.danger,
      ),
      _RoomData(
        name: 'Sentinel Broadcast',
        subtitle: 'Safety updates for your area',
        icon: Icons.notifications_outlined,
        iconColor: AppColors.danger.withValues(alpha: 0.6),
      ),
      _RoomData(
        name: 'Local Support Group',
        subtitle: 'Volunteer network chat',
        icon: Icons.people_outline,
        iconColor: AppColors.textSecondary,
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      itemCount: rooms.length,
      separatorBuilder: (_, __) => Divider(
        color: AppColors.divider,
        height: 1,
        indent: 80,
      ),
      itemBuilder: (context, i) {
        final room = rooms[i];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          tileColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(room.icon,
                color: room.iconColor, size: 24),
          ),
          title: Text(
            room.name,
            style: GoogleFonts.dmSans(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            room.subtitle,
            style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.chevron_right,
              color: AppColors.textSecondary, size: 20),
          onTap: () {
            // Navigate to community chat room
            // This connects to the existing Socket.IO room logic
          },
        );
      },
    );
  }
}

class _RoomData {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _RoomData({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
}

// ── CONTACTS TAB (WhatsApp style) ─────────────────────────────

class _ContactsTab extends StatefulWidget {
  const _ContactsTab();

  @override
  State<_ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<_ContactsTab> {
  final List<_ContactData> _contacts = [
    // Simulated — Phase 21 replaces with real device contact import
    // Havenly users show name only. Non-users show Invite button.
    _ContactData(
        name: 'Thabo Mokoena',
        phone: '+27 71 234 5678',
        isHavenlyUser: true,
        initials: 'TM'),
    _ContactData(
        name: 'Nomsa Dlamini',
        phone: '+27 82 345 6789',
        isHavenlyUser: true,
        initials: 'ND'),
    _ContactData(
        name: 'Sipho Khumalo',
        phone: '+27 60 456 7890',
        isHavenlyUser: false,
        initials: 'SK'),
    _ContactData(
        name: 'Ayanda Nkosi',
        phone: '+27 73 567 8901',
        isHavenlyUser: false,
        initials: 'AN'),
    _ContactData(
        name: 'Lerato Molefe',
        phone: '+27 84 678 9012',
        isHavenlyUser: true,
        initials: 'LM'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 0, bottom: 20),
      children: [
        // New contact / invite header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(Icons.people_outline,
                  color: AppColors.danger, size: 18),
              const SizedBox(width: 8),
              Text(
                'Contacts on Havenly',
                style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),

        ..._contacts.map((contact) {
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      contact.initials,
                      style: GoogleFonts.dmSans(
                        color: AppColors.danger,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  contact.name,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  contact.phone,
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: contact.isHavenlyUser
                    ? null
                    : GestureDetector(
                        onTap: () {
                          // Share Havenly invite link
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Invite',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                onTap: contact.isHavenlyUser
                    ? () {
                        // Open DM screen with this contact
                      }
                    : null,
              ),
              Divider(
                  color: AppColors.divider,
                  height: 1,
                  indent: 72),
            ],
          );
        }),
      ],
    );
  }
}

class _ContactData {
  final String name;
  final String phone;
  final bool isHavenlyUser;
  final String initials;

  const _ContactData({
    required this.name,
    required this.phone,
    required this.isHavenlyUser,
    required this.initials,
  });
}
