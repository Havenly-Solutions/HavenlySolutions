import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';

/// FILE: lib/services/socket_service.dart
/// PHASE: 17 — Real-Time SOS Broadcasting
///
/// Handles real-time events from the backend, including
/// immediate SOS alerts and localized broadcasts.

class SocketService extends ChangeNotifier {
  SocketService._internal();

  static final SocketService instance = SocketService._internal();

  factory SocketService() => instance;

  io.Socket? _socket;
  bool _isConnected = false;

  // Callback for global alert overlay
  static void Function(Map<String, dynamic> data)? onSosBroadcast;

  bool get isConnected => _isConnected;

  Future<bool> connect(String accessToken) async {
    if (AppConfig.kUseMockData) {
      debugPrint('[SocketService] Mock mode enabled; skipping socket connect.');
      return false;
    }

    if (_socket?.connected == true) {
      return true;
    }

    _initializeSocket(accessToken);
    _socket?.connect();
    return true;
  }

  Future<void> disconnect() async {
    if (_socket == null) return;

    _socket?.disconnect();
    _socket?.off('connect');
    _socket?.off('disconnect');
    _socket?.off('connect_error');
    _socket?.off('error');
    _socket?.off('sos:broadcast');
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }

  void emit(String event, dynamic data) {
    if (_socket?.connected != true) {
      debugPrint(
          '[SocketService] Cannot emit "$event" because socket is not connected.');
      return;
    }
    _socket?.emit(event, data);
  }

  void on(String event, void Function(dynamic data) listener) {
    _socket?.on(event, listener);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void _initializeSocket(String accessToken) {
    _socket?.disconnect();
    _socket?.off('connect');
    _socket?.off('disconnect');
    _socket?.off('connect_error');
    _socket?.off('error');

    _socket = io.io(
      AppConfig.wsUrl,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': accessToken},
      },
    );

    _socket?.on('connect', (_) {
      _isConnected = true;
      debugPrint('[SocketService] Connected to ${AppConfig.wsUrl}.');
      notifyListeners();
    });

    _socket?.on('disconnect', (_) {
      _isConnected = false;
      debugPrint('[SocketService] Disconnected from socket.');
      notifyListeners();
    });

    _socket?.on('sos:broadcast', (data) {
      debugPrint('[Socket] Received SOS broadcast: $data');
      if (onSosBroadcast != null) {
        onSosBroadcast!(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('connect_error', (error) {
      debugPrint('[SocketService] Connect error: $error');
    });

    _socket?.on('error', (error) {
      debugPrint('[SocketService] Socket error: $error');
    });
  }
}
