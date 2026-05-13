import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:convert';
import '../../core/database/local_db.dart';
import '../../core/models/post_model.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';

enum FeedScope { nationwide, province, community, nearby, bookmarked }

class NewsProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Phase 15: Scope & Filtering
  FeedScope _scope = FeedScope.nationwide;
  String? _userProvince;
  String? _userCommunityId;
  double? _userLat;
  double? _userLng;

  List<PostModel> get posts => _posts;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  FeedScope get scope => _scope;
  String? get myUserId => _apiService.currentUserId;

  final _uuid = const Uuid();
  final _picker = ImagePicker();
  final _apiService = ApiService();

  void setScope(FeedScope scope, {String? province, String? communityId, double? lat, double? lng}) {
    _scope = scope;
    _userProvince = province;
    _userCommunityId = communityId;
    _userLat = lat;
    _userLng = lng;
    loadPosts(refresh: true);
  }

  Future<void> loadPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore || _loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (_scope == FeedScope.bookmarked) {
        final rows = await LocalDb.getBookmarks();
        _posts = rows.map((r) => PostModel.fromMap(jsonDecode(r['post_json']))).toList();
        _hasMore = false;
      } else if (AppConfig.kUseMockData) {
        final rows = await LocalDb.getPosts();
        _posts = rows.map(PostModel.fromMap).toList();
        _hasMore = false;
      } else {
        final Map<String, dynamic> params = {
          'page': _currentPage,
          'limit': 20,
        };

        // Phase 15: Apply scope-based filters
        switch (_scope) {
          case FeedScope.province:
            params['province'] = _userProvince;
            break;
          case FeedScope.community:
            params['communityId'] = _userCommunityId;
            break;
          case FeedScope.nearby:
            params['distance'] = 5; // 5km radius
            params['lat'] = _userLat;
            params['lng'] = _userLng;
            break;
          default:
            break;
        }

        final data = await _apiService.get('/api/feed', queryParameters: params);
        final List<dynamic> results = data['posts'];
        final List<PostModel> newPosts = results.map((m) => PostModel.fromMap(m)).toList();

        if (refresh) {
          _posts = newPosts;
        } else {
          _posts.addAll(newPosts);
        }

        _hasMore = results.length == 20;
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // --- BOOKMARKS (LOCAL PINNING) ---

  Future<void> toggleBookmark(PostModel post) async {
    final isPinned = await LocalDb.isBookmarked(post.id);
    if (isPinned) {
      await LocalDb.deleteBookmark(post.id);
    } else {
      await LocalDb.insertBookmark(post.id, jsonEncode(post.toMap()));
    }
    notifyListeners(); // Refresh icons in list
  }

  Future<bool> isBookmarked(String id) async {
    return LocalDb.isBookmarked(id);
  }

  // --- CRUD ACTIONS ---

  Future<void> deletePost(String id, String reason) async {
    try {
      if (!AppConfig.kUseMockData) {
        await _apiService.delete('/api/feed/$id', data: {'reason': reason});
      }

      final postIndex = _posts.indexWhere((p) => p.id == id);
      if (postIndex == -1) return;

      _posts.removeAt(postIndex);
      notifyListeners();

      await LocalDb.deletePost(id);
      await LocalDb.deleteBookmark(id);
    } catch (e) {
      _error = e.toString();
      await loadPosts();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createNewsPost({
    required String title,
    required String body,
    required String authorId,
    required String authorName,
    required String authorRegion,
    int? authorAge,
    double? lat,
    double? lng,
  }) async {
    final post = PostModel(
      id: _uuid.v4(),
      type: PostType.news,
      title: title,
      body: body,
      authorId: authorId,
      authorName: authorName,
      authorAge: authorAge,
      authorRegion: authorRegion,
      createdAt: DateTime.now(),
    );

    if (!AppConfig.kUseMockData) {
      final map = post.toMap();
      if (lat != null && lng != null) {
        map['lat'] = lat;
        map['lng'] = lng;
      }
      await _apiService.post('/api/feed', data: map);
    }

    await LocalDb.insertPost(post.toMap());
    _posts.insert(0, post);
    notifyListeners();
  }

  Future<String?> pickMissingPersonImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${_uuid.v4()}.jpg';
    final saved = await File(picked.path).copy('${dir.path}/$fileName');
    return saved.path;
  }

  Future<void> createMissingPersonPost({
    required String title,
    required String body,
    required String contactName,
    required String contactPhone,
    required String authorId,
    required String authorName,
    required String authorRegion,
    int? authorAge,
    String? imageLocalPath,
    double? lat,
    double? lng,
  }) async {
    final post = PostModel(
      id: _uuid.v4(),
      type: PostType.missingPerson,
      title: title,
      body: body,
      imageLocalPath: imageLocalPath,
      contactName: contactName,
      contactPhone: contactPhone,
      authorId: authorId,
      authorName: authorName,
      authorAge: authorAge,
      authorRegion: authorRegion,
      createdAt: DateTime.now(),
    );

    if (!AppConfig.kUseMockData) {
      final map = post.toMap();
      if (lat != null && lng != null) {
        map['lat'] = lat;
        map['lng'] = lng;
      }
      await _apiService.post('/api/feed', data: map);
    }

    await LocalDb.insertPost(post.toMap());
    _posts.insert(0, post);
    notifyListeners();
  }

  Future<List<ReplyModel>> getReplies(String postId) async {
    if (!AppConfig.kUseMockData) {
      final data = await _apiService.get('/api/feed/$postId/replies');
      final List<dynamic> results = data;
      return results.map((m) => ReplyModel.fromMap(m)).toList();
    }
    final rows = await LocalDb.getReplies(postId);
    return rows.map(ReplyModel.fromMap).toList();
  }

  Future<void> addReply({
    required String postId,
    required String authorId,
    required String authorName,
    required String body,
    String? authorRegion,
  }) async {
    final reply = ReplyModel(
      id: _uuid.v4(),
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorRegion: authorRegion,
      body: body,
      createdAt: DateTime.now(),
    );

    if (!AppConfig.kUseMockData) {
      await _apiService.post('/api/feed/$postId/replies', data: reply.toMap());
    }

    await LocalDb.insertReply(reply.toMap());
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final old = _posts[idx];
      _posts[idx] = old.copyWith(replyCount: old.replyCount + 1);
      notifyListeners();
    }
  }
}
