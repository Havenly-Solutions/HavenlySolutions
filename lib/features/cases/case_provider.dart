import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../config/app_config.dart';
import '../../core/database/local_db.dart';
import '../../core/models/case_model.dart';
import '../../core/security/secure_storage_service.dart';
import '../../services/api_service.dart';

class CaseProvider extends ChangeNotifier {
  final List<CaseModel> _cases = [];
  bool _loading = false;

  List<CaseModel> get cases => List.unmodifiable(_cases);
  bool get loading => _loading;

  static const List<String> categories = [
    'Theft',
    'Assault',
    'Suspicious Activity',
    'Harassment',
    'Other',
  ];

  Future<void> loadCases() async {
    _loading = true;
    notifyListeners();

    try {
      if (!AppConfig.kUseMockData) {
        await _syncRemoteCases();
      }

      final rows = await LocalDb.getCases();
      _cases
        ..clear()
        ..addAll(rows.map(CaseModel.fromMap));
    } catch (e) {
      debugPrint('[CaseProvider] Failed to load cases: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _syncRemoteCases() async {
    final userId = await SecureStorageService.getUserId();
    if (userId == null || userId.isEmpty) return;

    try {
      final response = await ApiService().get('/api/cases', queryParameters: {'user_id': userId});
      final List<dynamic>? remoteCases = response['cases'] as List<dynamic>?;
      if (remoteCases == null) return;

      for (final rawCase in remoteCases) {
        final caseMap = Map<String, dynamic>.from(rawCase as Map);
        final caseModel = CaseModel.fromMap(caseMap);
        await LocalDb.insertCase(caseModel.toMap());
      }
    } catch (e) {
      debugPrint('[CaseProvider] Remote case sync failed: $e');
    }
  }

  Future<bool> submitCase({
    required String userId,
    required String community,
    required String category,
    required String description,
    required String evidence,
  }) async {
    _loading = true;
    notifyListeners();

    final now = DateTime.now();
    final caseId = const Uuid().v4();
    final caseModel = CaseModel(
      id: caseId,
      userId: userId,
      community: community,
      category: category,
      description: description,
      evidence: evidence,
      status: 'pending',
      createdAt: now,
      updatedAt: now,
      synced: false,
    );

    try {
      await LocalDb.insertCase(caseModel.toMap());
      _cases.insert(0, caseModel);
      notifyListeners();

      if (!AppConfig.kUseMockData) {
        try {
          await ApiService().post('/api/cases', data: caseModel.toMap());
          await LocalDb.updateCase(caseModel.id, {'synced': 1});
          _cases[0] = caseModel.copyWith(synced: true);
          notifyListeners();
        } catch (e) {
          debugPrint('[CaseProvider] Case sync deferred: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('[CaseProvider] Failed to submit case: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
