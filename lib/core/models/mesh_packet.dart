import 'dart:convert';
import 'dart:typed_data';

enum MeshPacketType { chat, sos_relay, discovery }

class MeshPacket {
  final String id;
  final String senderId;
  final MeshPacketType type;
  final Map<String, dynamic> payload;
  final int timestamp;

  MeshPacket({
    required this.id,
    required this.senderId,
    required this.type,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'type': type.name,
      'payload': payload,
      'timestamp': timestamp,
    };
  }

  factory MeshPacket.fromMap(Map<String, dynamic> map) {
    return MeshPacket(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      type: MeshPacketType.values.byName(map['type'] as String),
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      timestamp: map['timestamp'] as int,
    );
  }

  Uint8List toBytes() {
    return Uint8List.fromList(utf8.encode(jsonEncode(toMap())));
  }

  factory MeshPacket.fromBytes(Uint8List bytes) {
    return MeshPacket.fromMap(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
  }
}
