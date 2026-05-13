import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../news_provider.dart';
import '../widgets/post_card.dart';
import '../../../providers/user_provider.dart';
import '../../../services/geo_location_service.dart';
import '../../../core/models/post_model.dart';

class NationwideFeedScreen extends StatefulWidget {
  const NationwideFeedScreen({super.key});

  @override
  State<NationwideFeedScreen> createState() => _NationwideFeedScreenState();
}

class _FilterBar extends StatelessWidget {
  final PostType? current;
  final ValueChanged<PostType?> onChanged;

  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'ALL',
            selected: current == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'SAFETY',
            selected: current == PostType.safety,
            onTap: () => onChanged(PostType.safety),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'POLICE',
            selected: current == PostType.police,
            onTap: () => onChanged(PostType.police),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'COMMUNITY',
            selected: current == PostType.community,
            onTap: () => onChanged(PostType.community),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE53935) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFE53935) : const Color(0xFF2A2A2A),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NationwideFeedScreenState extends State<NationwideFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  PostType? _filter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().loadPosts(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NewsProvider>().loadPosts();
    }
  }

  Future<void> _refresh() async {
    await context.read<NewsProvider>().loadPosts(refresh: true);
  }

  void _openCreatePost() {
    // TODO: Implement create post
  }

  void _openMissingPersons() {
    // TODO: Implement missing persons view
  }

  void _updateScope(FeedScope scope) {
    final user = context.read<UserProvider>().currentUser;
    final geo = context.read<GeoLocationService>();
    
    context.read<NewsProvider>().setScope(
      scope,
      province: user?.province,
      communityId: user?.community, // Assuming community name is used as ID or similar
      lat: geo.currentPosition?.latitude,
      lng: geo.currentPosition?.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Havenly Solutions News',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Live safety updates across South Africa',
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _openCreatePost,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFFE53935),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // LIVE banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Real-time safety alerts and community updates across South Africa.',
                      style: TextStyle(
                          color: Colors.white, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: Colors.white, size: 16),
                ],
              ),
            ),

            // Filter chips
            _FilterBar(current: _filter, onChanged: (f) => setState(() => _filter = f)),

            // Feed content
            Expanded(
              child: Consumer<NewsProvider>(
                builder: (context, provider, _) {
                  if (provider.loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935), strokeWidth: 2),
                    );
                  }

                  final missingPosts = provider.posts
                      .where((p) => p.type == PostType.missingPerson)
                      .toList();

                  final newsPosts = _filter == null ||
                          _filter == PostType.news
                      ? provider.posts
                          .where((p) => p.type == PostType.news)
                          .toList()
                      : <PostModel>[];

                  return RefreshIndicator(
                    onRefresh: provider.loadPosts,
                    color: const Color(0xFFE53935),
                    backgroundColor: const Color(0xFF111111),
                    child: ListView(
                      padding: const EdgeInsets.only(
                          top: 8, bottom: 110),
                      children: [
                        // Missing persons album — always at top
                        if (missingPosts.isNotEmpty &&
                            (_filter == null ||
                                _filter ==
                                    PostType.missingPerson))
                          MissingPersonsAlbum(
                            posts: missingPosts,
                            onViewAll: _openMissingPersons,
                          ),

                        // News posts
                        ...newsPosts.map(
                          (p) => PostCard(
                            post: p,
                            myUserId: provider.myUserId,
                          ),
                        ),

                        if (provider.posts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                Icon(Icons.feed_outlined,
                                    color: Colors.grey.shade800,
                                    size: 48),
                                const SizedBox(height: 14),
                                Text(
                                  'No posts yet across South Africa.',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}
