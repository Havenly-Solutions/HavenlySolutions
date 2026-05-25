import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../database/local_db.dart';
import '../security/secure_storage_service.dart';

class OfflineSyncService {
  OfflineSyncService._();
  static final OfflineSyncService instance = OfflineSyncService._();

  final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorageService.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('[OfflineSync] request error: ${error.message}');
        return handler.next(error);
      },
    ));

  Future<bool> get isOnline async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity == ConnectivityResult.mobile ||
        connectivity == ConnectivityResult.wifi;
  }

  Future<void> enqueueRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? payload,
    int maxRetries = 3,
  }) async {
    await LocalDb.enqueueOfflineRequest(
      id: const Uuid().v4(),
      endpoint: endpoint,
      method: method,
      payload: payload,
      maxRetries: maxRetries,
    );
    debugPrint('[OfflineSync] Enqueued request $endpoint $method');
  }

  Future<void> syncPendingRequests() async {
    if (!await isOnline) {
      debugPrint('[OfflineSync] offline, skipping sync');
      return;
    }

    final pendingItems = await LocalDb.getPendingOfflineRequests();
    if (pendingItems.isEmpty) {
      debugPrint('[OfflineSync] no pending requests');
      return;
    }

    for (final item in pendingItems) {
      final id = item['id'] as String;
      final endpoint = item['endpoint'] as String;
      final method = item['method'] as String;
      final payload = item['payload'] != null
          ? jsonDecode(item['payload'] as String) as Map<String, dynamic>
          : null;
      final retryCount = (item['retry_count'] as int?) ?? 0;
      final maxRetries = (item['max_retries'] as int?) ?? 3;

      try {
        await _dio.request(
          endpoint,
          data: payload,
          options: Options(method: method),
        );
        await LocalDb.deleteOfflineRequest(id);
        debugPrint('[OfflineSync] synced request $endpoint');
      } on DioException catch (_) {
        final nextRetryCount = retryCount + 1;
        if (nextRetryCount >= maxRetries) {
          await LocalDb.updateOfflineRequestStatus(
            id,
            status: 'FAILED',
            retryCount: nextRetryCount,
          );
          debugPrint('[OfflineSync] request failed permanently $endpoint');
        } else {
          await LocalDb.updateOfflineRequestStatus(
            id,
            retryCount: nextRetryCount,
          );
          debugPrint(
              '[OfflineSync] will retry $endpoint ($nextRetryCount/$maxRetries)');
        }
      } catch (_) {
        debugPrint('[OfflineSync] unexpected error syncing $endpoint');
      }
    }
  }
}
