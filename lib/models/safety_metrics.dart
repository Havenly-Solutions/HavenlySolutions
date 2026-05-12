class SafetyMetrics {
  final int totalSosCount;
  final DateTime? lastSosAt;
  final int? lastResponseTimeMs;
  final int? avgResponseTimeMs;
  final int totalCasesFiled;
  final int casesResolved;
  final DateTime? lastCaseAt;
  final String? lastSosStatus;
  final String? lastSosAddress;
  final String? lastCaseNumber;
  final String? lastCaseType;
  final String? lastCaseStatus;

  const SafetyMetrics({
    required this.totalSosCount,
    required this.lastSosAt,
    required this.lastResponseTimeMs,
    required this.avgResponseTimeMs,
    required this.totalCasesFiled,
    required this.casesResolved,
    required this.lastCaseAt,
    required this.lastSosStatus,
    required this.lastSosAddress,
    required this.lastCaseNumber,
    required this.lastCaseType,
    required this.lastCaseStatus,
  });

  String get lastResponseTimeFormatted {
    if (lastResponseTimeMs == null) return 'No data yet';
    final s = lastResponseTimeMs! ~/ 1000;
    final m = s ~/ 60;
    final rem = s % 60;
    return m > 0 ? '${m}m ${rem}s' : '${s}s';
  }

  String get avgResponseTimeFormatted {
    if (avgResponseTimeMs == null) return 'No data yet';
    final s = avgResponseTimeMs! ~/ 1000;
    final m = s ~/ 60;
    return m > 0 ? '${m}m ${s % 60}s' : '${s}s';
  }

  bool get hasActivity =>
      totalSosCount > 0 ||
      totalCasesFiled > 0 ||
      lastSosAt != null ||
      lastCaseAt != null;

  factory SafetyMetrics.fromJson(Map<String, dynamic> json) {
    final lastSos = json['lastSos'] as Map<String, dynamic>?;
    final lastCase = json['lastCase'] as Map<String, dynamic>?;

    return SafetyMetrics(
      totalSosCount: json['totalSosCount'] as int? ?? 0,
      lastSosAt: json['lastSosAt'] != null
          ? DateTime.tryParse(json['lastSosAt'] as String)
          : null,
      lastResponseTimeMs: json['lastResponseTimeMs'] as int?,
      avgResponseTimeMs: json['avgResponseTimeMs'] as int?,
      totalCasesFiled: json['totalCasesFiled'] as int? ?? 0,
      casesResolved: json['casesResolved'] as int? ?? 0,
      lastCaseAt: json['lastCaseAt'] != null
          ? DateTime.tryParse(json['lastCaseAt'] as String)
          : null,
      lastSosStatus: lastSos?['status'] as String?,
      lastSosAddress: lastSos?['address'] as String?,
      lastCaseNumber: lastCase?['caseNumber'] as String?,
      lastCaseType: lastCase?['type'] as String?,
      lastCaseStatus: lastCase?['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSosCount': totalSosCount,
      'lastSosAt': lastSosAt?.toIso8601String(),
      'lastResponseTimeMs': lastResponseTimeMs,
      'avgResponseTimeMs': avgResponseTimeMs,
      'totalCasesFiled': totalCasesFiled,
      'casesResolved': casesResolved,
      'lastCaseAt': lastCaseAt?.toIso8601String(),
      'lastSos': lastSosStatus == null && lastSosAddress == null
          ? null
          : {
              'status': lastSosStatus,
              'address': lastSosAddress,
            },
      'lastCase': lastCaseNumber == null && lastCaseType == null && lastCaseStatus == null
          ? null
          : {
              'caseNumber': lastCaseNumber,
              'type': lastCaseType,
              'status': lastCaseStatus,
            },
    };
  }

  SafetyMetrics copyWith({
    int? totalSosCount,
    DateTime? lastSosAt,
    int? lastResponseTimeMs,
    int? avgResponseTimeMs,
    int? totalCasesFiled,
    int? casesResolved,
    DateTime? lastCaseAt,
    String? lastSosStatus,
    String? lastSosAddress,
    String? lastCaseNumber,
    String? lastCaseType,
    String? lastCaseStatus,
  }) {
    return SafetyMetrics(
      totalSosCount: totalSosCount ?? this.totalSosCount,
      lastSosAt: lastSosAt ?? this.lastSosAt,
      lastResponseTimeMs: lastResponseTimeMs ?? this.lastResponseTimeMs,
      avgResponseTimeMs: avgResponseTimeMs ?? this.avgResponseTimeMs,
      totalCasesFiled: totalCasesFiled ?? this.totalCasesFiled,
      casesResolved: casesResolved ?? this.casesResolved,
      lastCaseAt: lastCaseAt ?? this.lastCaseAt,
      lastSosStatus: lastSosStatus ?? this.lastSosStatus,
      lastSosAddress: lastSosAddress ?? this.lastSosAddress,
      lastCaseNumber: lastCaseNumber ?? this.lastCaseNumber,
      lastCaseType: lastCaseType ?? this.lastCaseType,
      lastCaseStatus: lastCaseStatus ?? this.lastCaseStatus,
    );
  }
}
