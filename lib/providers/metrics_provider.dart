import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../core/database/local_db.dart';
import '../core/security/secure_storage_service.dart';
import '../models/safety_metrics.dart';
import '../services/api_service.dart';

class MetricsProvider extends ChangeNotifier {
  SafetyMetrics? metrics;
  bool isLoading = false;

  final ApiService _apiService = ApiService();

  Future<void> loadMetrics() async {
    final userId = await SecureStorageService.getUserId();
    if (userId == null || userId.isEmpty) {
      metrics = null;
      notifyListeners();
      return;
    }

    final cached = await LocalDb.getSafetyMetrics(userId);
    if (cached != null) {
      metrics = SafetyMetrics.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
      );
      notifyListeners();
    }

    isLoading = true;
    notifyListeners();

    try {
      if (AppConfig.kUseMockData) {
        metrics = const SafetyMetrics(
          totalSosCount: 0,
          lastSosAt: null,
          lastResponseTimeMs: null,
          avgResponseTimeMs: null,
          totalCasesFiled: 0,
          casesResolved: 0,
          lastCaseAt: null,
          lastSosStatus: null,
          lastSosAddress: null,
          lastCaseNumber: null,
          lastCaseType: null,
          lastCaseStatus: null,
        );
      } else {
        final response = await _apiService.get('/api/users/metrics');
        metrics = SafetyMetrics.fromJson(response as Map<String, dynamic>);
      }

      await LocalDb.saveSafetyMetrics(userId, jsonEncode(metrics!.toJson()));
    } catch (e) {
      debugPrint('[MetricsProvider] Failed to load metrics: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
