import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../core/database/local_db.dart';
import '../../core/models/post_model.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';

class FeedProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<PostModel> get posts => _posts;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  final _uuid = const Uuid();
  final _picker = ImagePicker();
  final _apiService = ApiService();

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
      if (AppConfig.kUseMockData) {
        // Fallback to SQLite cached posts if mock mode is on
        final rows = await LocalDb.getPosts();
        _posts = rows.map(PostModel.fromMap).toList();
        _hasMore = false;
      } else {
        final data = await _apiService.get('/api/feed', queryParameters: {
          'page': _currentPage,
          'limit': 20,
        });

        final List<dynamic> results = data['posts'];
        final List<PostModel> newPosts = results.map((m) => PostModel.fromMap(m)).toList();

        if (refresh) {
          _posts = newPosts;
        } else {
          _posts.addAll(newPosts);
        }

        _hasMore = results.length == 20;
        _currentPage++;

        // Cache first page
        if (refresh) {
          // Clear old cache and insert new
          // (Implementation simplified for now)
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deletePost(String id, String reason) async {
    try {
      if (!AppConfig.kUseMockData) {
        await _apiService.delete('/api/feed/$id', data: {'reason': reason});
      }
      
      final postIndex = _posts.indexWhere((p) => p.id == id);
      if (postIndex == -1) return;
      
      _posts.removeAt(postIndex);
      notifyListeners();

      // For offline survival, also delete from local SQLite
      await LocalDb.deletePost(id);
    } catch (e) {
      _error = e.toString();
      // Reload from DB to restore post if backend failed (Rollback logic)
      await loadPosts();
      notifyListeners();
      rethrow;
    }
  }

  // Legacy local-only methods preserved for fallback
  Future<void> createNewsPost({
    required String title,
    required String body,
    required String authorId,
    required String authorName,
    required String authorRegion,
    int? authorAge,
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
      await _apiService.post('/api/feed', data: post.toMap());
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
      // Logic for uploading image would go here
      await _apiService.post('/api/feed', data: post.toMap());
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
