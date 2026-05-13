import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_post.dart';
import '../services/api_service.dart';
import 'user_provider.dart';

class FeedState {
  final List<FeedPost> posts;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;

  FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  FeedState copyWith({
    List<FeedPost>? posts,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FeedNotifier(apiService);
});

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier(ApiService apiService) : super(FeedState()) {
    fetchPosts();
  }

  Future<void> fetchPosts({bool refresh = false}) async {
    if (state.isLoading || (!state.hasMore && !refresh)) return;

    if (refresh) {
      state = state.copyWith(posts: [], page: 1, hasMore: true, isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final List<FeedPost> newPosts = []; // Assuming empty if no backend yet

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoading: false,
        page: state.page + 1,
        hasMore: newPosts.length == 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createPost(FeedPost post) async {
    state = state.copyWith(posts: [post, ...state.posts]);
  }
}
