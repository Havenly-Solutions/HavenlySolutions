/*
 * ─────────────────────────────────────────────────────────────
 * FILE: lib/core/models/sos_payload.dart
 * PHASE: 7 — SOS Data Model
 *
 * PURPOSE:
 *   Standardized data structure for SOS triggers across all
 *   layers and waves.
 * ─────────────────────────────────────────────────────────────
 */

class SosPayload {
  final String? eventId;
  final double lat;
  final double lng;
  final double accuracyM;
  final String? cellCid;
  final String? cellLac;
  final String? triggerMethod;
  final bool isDuress;

  const SosPayload({
    this.eventId,
    required this.lat,
    required this.lng,
    required this.accuracyM,
    this.cellCid,
    this.cellLac,
    this.triggerMethod = 'app_button',
    this.isDuress = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'accuracyM': accuracyM,
      if (cellCid != null) 'cellCid': cellCid,
      if (cellLac != null) 'cellLac': cellLac,
      'triggerMethod': triggerMethod,
      'isDuress': isDuress,
    };
  }

  SosPayload copyWith({
    String? eventId,
    double? lat,
    double? lng,
    double? accuracyM,
    String? cellCid,
    String? cellLac,
    String? triggerMethod,
    bool? isDuress,
  }) {
    return SosPayload(
      eventId: eventId ?? this.eventId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      accuracyM: accuracyM ?? this.accuracyM,
      cellCid: cellCid ?? this.cellCid,
      cellLac: cellLac ?? this.cellLac,
      triggerMethod: triggerMethod ?? this.triggerMethod,
      isDuress: isDuress ?? this.isDuress,
    );
  }

  @override
  String toString() {
    return 'SosPayload(eventId: $eventId, lat: $lat, lng: $lng, accuracy: $accuracyM)';
  }
}
