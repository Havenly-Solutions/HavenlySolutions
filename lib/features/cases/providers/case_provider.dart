import 'package:flutter/foundation.dart';
import '../../../core/database/local_db.dart';
import '../../../services/api_service.dart';
import '../models/case_model.dart';

class CaseProvider extends ChangeNotifier {
  final List<CaseModel> _cases = [];
  bool _isLoading = false;

  List<CaseModel> get cases => List.unmodifiable(_cases);
  bool get isLoading => _isLoading;

  Future<void> loadCases() async {
    _isLoading = true;
    notifyListeners();

    try {
      final rows = await LocalDb.getCases();
      _cases.clear();
      _cases.addAll(rows.map((row) => CaseModel.fromMap(row)));
    } catch (e) {
      debugPrint('[CaseProvider] Failed to load cases: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  bool isSynced(String caseId) {
    try {
      final c = _cases.firstWhere((e) => e.id == caseId);
      return c.synced;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncPendingCases() async {
    try {
      final db = await LocalDb.db;
      final unsynced = await db.query(
        'cases',
        where: 'synced = ?',
        whereArgs: [0],
      );

      if (unsynced.isEmpty) return;

      for (var row in unsynced) {
        final caseModel = CaseModel.fromMap(row);
        try {
          final response =
              await ApiService().post('/api/cases', data: caseModel.toJson());

          // Assuming 201 or success code
          if (response != null &&
              (response['success'] == true || response['id'] != null)) {
            await LocalDb.updateCase(caseModel.id, {'synced': 1});

            final index = _cases.indexWhere((c) => c.id == caseModel.id);
            if (index != -1) {
              _cases[index] = _cases[index].copyWith(synced: true);
            }
          }
        } catch (e) {
          debugPrint('[CaseProvider] Failed to sync case ${caseModel.id}: $e');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[CaseProvider] syncPendingCases error: $e');
    }
  }

  Future<bool> submitCase(CaseModel caseData) async {
    try {
      await LocalDb.insertCase(caseData.toMap());
      _cases.insert(0, caseData);
      notifyListeners();

      // Attempt immediate sync
      try {
        final response =
            await ApiService().post('/api/cases', data: caseData.toJson());
        if (response != null &&
            (response['success'] == true || response['id'] != null)) {
          await LocalDb.updateCase(caseData.id, {'synced': 1});
          final index = _cases.indexWhere((c) => c.id == caseData.id);
          if (index != -1) {
            _cases[index] = _cases[index].copyWith(synced: true);
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('[CaseProvider] Immediate sync failed: $e');
      }

      return true;
    } catch (e) {
      debugPrint('[CaseProvider] Failed to submit case: $e');
      return false;
    }
  }
}
