import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/database/local_db.dart';
import 'api_service.dart';

class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  Future<void> enqueue(String endpoint, String method, dynamic payload) async {
    final db = await LocalDb.db;
    await db.insert('offline_queue', {
      'id': const Uuid().v4(),
      'endpoint': endpoint,
      'method': method,
      'payload': payload != null ? jsonEncode(payload) : null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'retry_count': 0,
      'status': 'PENDING',
    });
  }

  Future<void> processQueue() async {
    final db = await LocalDb.db;
    final List<Map<String, dynamic>> pending = await db.query(
      'offline_queue',
      where: 'status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'created_at ASC',
    );

    if (pending.isEmpty) return;

    final apiService = ApiService();

    for (var item in pending) {
      try {
        final String method = item['method'];
        final String endpoint = item['endpoint'];
        final dynamic payload = item['payload'] != null ? jsonDecode(item['payload']) : null;

        switch (method) {
          case 'POST':
            await apiService.post(endpoint, data: payload);
            break;
          case 'PUT':
            await apiService.put(endpoint, data: payload);
            break;
          case 'PATCH':
            await apiService.patch(endpoint, data: payload);
            break;
          case 'DELETE':
            await apiService.delete(endpoint, data: payload);
            break;
        }

        await db.update(
          'offline_queue',
          {'status': 'SENT'},
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      } catch (e) {
        final int retryCount = item['retry_count'] + 1;
        await db.update(
          'offline_queue',
          {
            'retry_count': retryCount,
            'status': retryCount >= 3 ? 'FAILED' : 'PENDING',
          },
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      }
    }
  }
}
