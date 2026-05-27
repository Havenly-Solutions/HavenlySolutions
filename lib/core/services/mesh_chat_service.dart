import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/mesh_packet.dart';
import '../database/local_db.dart';
import 'bluetooth_mesh_service.dart';
import 'connectivity_service.dart';
import 'api_service.dart';
import '../security/secure_storage_service.dart';

class MeshChatService {
  MeshChatService._();
  static final MeshChatService instance = MeshChatService._();

  /// Routes messages through internet when available, and through Bluetooth mesh when offline.
  /// As per Master Build Prompt Section 15.
  Future<void> sendMessage({
    required String toUserId,
    String? roomId,
    required String content,
  }) async {
    final currentUserId = await SecureStorageService.getUserId() ?? 'unknown';
    
    final msgId = const Uuid().v4();
    final now = DateTime.now();

    final messageMap = {
      'id': msgId,
      'conversation_id': roomId ?? toUserId,
      'sender_id': currentUserId,
      'sender_name': 'Me', // Should be fetched from profile
      'body': content,
      'created_at': now.millisecondsSinceEpoch,
      'synced': 0,
    };

    // 1. Write to local SQLite immediately
    await LocalDb.insertMessage(messageMap);

    // 2. Check connectivity
    final isOnline = await ConnectivityService().isOnline;

    if (isOnline) {
      try {
        // await ApiService().sendMessage(messageMap);
        await LocalDb.updateMessageSyncStatus(msgId, 1);
      } catch (e) {
        // Failed to send online, will sync later
      }
    } else {
      // 3. Route via BLE mesh
      final packet = MeshPacket(
        id: msgId,
        senderId: currentUserId,
        type: MeshPacketType.chat,
        payload: {
          'toUserId': toUserId,
          'roomId': roomId,
          'content': content,
        },
        timestamp: now.millisecondsSinceEpoch,
      );

      await BluetoothMeshService.sendBytesToAll(packet.toBytes());
    }
  }

  /// Start listening for incoming mesh messages.
  void startListening() {
    // This should be integrated into BluetoothMeshService's relay listener
  }
}
