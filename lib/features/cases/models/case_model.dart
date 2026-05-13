class CaseModel {
  final String id;
  final String refNumber;
  final String incidentType;
  final DateTime incidentDate;
  final String locationAddress;
  final double? locationLat;
  final double? locationLng;
  final String description;
  final String status;
  final bool synced;
  final DateTime createdAt;
  final List<String> evidenceUrls;

  CaseModel({
    required this.id,
    required this.refNumber,
    required this.incidentType,
    required this.incidentDate,
    required this.locationAddress,
    this.locationLat,
    this.locationLng,
    required this.description,
    required this.status,
    required this.synced,
    required this.createdAt,
    required this.evidenceUrls,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ref_number': refNumber,
      'incident_type': incidentType,
      'incident_date': incidentDate.toIso8601String(),
      'location_address': locationAddress,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'description': description,
      'status': status,
      'synced': synced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'evidence_urls': evidenceUrls.join(','),
    };
  }

  factory CaseModel.fromMap(Map<String, dynamic> map) {
    return CaseModel(
      id: map['id'],
      refNumber: map['ref_number'],
      incidentType: map['incident_type'],
      incidentDate: DateTime.parse(map['incident_date']),
      locationAddress: map['location_address'],
      locationLat: map['location_lat'],
      locationLng: map['location_lng'],
      description: map['description'],
      status: map['status'],
      synced: map['synced'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      evidenceUrls: map['evidence_urls'] != null && map['evidence_urls'].toString().isNotEmpty
          ? map['evidence_urls'].toString().split(',')
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'refNumber': refNumber,
      'incidentType': incidentType,
      'incidentDate': incidentDate.toIso8601String(),
      'locationAddress': locationAddress,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'description': description,
      'status': status,
      'synced': synced,
      'createdAt': createdAt.toIso8601String(),
      'evidenceUrls': evidenceUrls,
    };
  }

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'],
      refNumber: json['refNumber'],
      incidentType: json['incidentType'],
      incidentDate: DateTime.parse(json['incidentDate']),
      locationAddress: json['locationAddress'],
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLng: (json['locationLng'] as num?)?.toDouble(),
      description: json['description'],
      status: json['status'],
      synced: json['synced'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      evidenceUrls: List<String>.from(json['evidenceUrls'] ?? []),
    );
  }

  CaseModel copyWith({
    String? id,
    String? refNumber,
    String? incidentType,
    DateTime? incidentDate,
    String? locationAddress,
    double? locationLat,
    double? locationLng,
    String? description,
    String? status,
    bool? synced,
    DateTime? createdAt,
    List<String>? evidenceUrls,
  }) {
    return CaseModel(
      id: id ?? this.id,
      refNumber: refNumber ?? this.refNumber,
      incidentType: incidentType ?? this.incidentType,
      incidentDate: incidentDate ?? this.incidentDate,
      locationAddress: locationAddress ?? this.locationAddress,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      description: description ?? this.description,
      status: status ?? this.status,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
    );
  }
}
