import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_post.dart';
import '../services/api_service.dart';

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
  final ApiService _apiService;

  FeedNotifier(this._apiService) : super(FeedState()) {
    fetchPosts();
  }

  Future<void> fetchPosts({bool refresh = false}) async {
    if (state.isLoading || (!state.hasMore && !refresh)) return;

    if (refresh) {
      state =
          state.copyWith(posts: [], page: 1, hasMore: true, isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final response = await _apiService.getPosts(
        page: state.page,
        limit: 20,
      );

      final List<dynamic> postsJson = response['posts'];
      final newPosts =
          postsJson.map((json) => FeedPost.fromJson(json)).toList();

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

  Future<void> createPost(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.createPost(data);
      final newPost = FeedPost.fromJson(response);
      state = state.copyWith(posts: [newPost, ...state.posts]);
    } catch (e) {
      // Handle error
    }
  }
}
