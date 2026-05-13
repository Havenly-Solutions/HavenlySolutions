/*
 * ─────────────────────────────────────────────────────────────
 * FILE: lib/core/services/communities_service.dart
 * PHASE: 7 — Community Data Management
 *
 * PURPOSE:
 *   Fetch, cache, and provide community data for:
 *   - Province selection
 *   - Community selection in registration/profile
 *   - Geographic proximity detection for alerts
 *   - SOS event community attribution
 * ─────────────────────────────────────────────────────────────
 */

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../database/local_db.dart';

class CommunitiesService {
  static final CommunitiesService _instance = CommunitiesService._internal();

  static const List<String> saProvinces = [
    'Eastern Cape',
    'Free State',
    'Gauteng',
    'KwaZulu-Natal',
    'Limpopo',
    'Mpumalanga',
    'Northern Cape',
    'North West',
    'Western Cape',
  ];

  List<Map<String, dynamic>> _allCommunities = [];
  final Map<String, List<Map<String, dynamic>>> _communitiesByProvince = {};
  final Set<String> _provinces = {};

  CommunitiesService._internal();

  factory CommunitiesService() {
    return _instance;
  }

  /// Initialize communities from database
  Future<void> init() async {
    try {
      _allCommunities = await LocalDb.getAllCommunities();
      _buildProvinceMaps();
    } catch (e) {
      debugPrint('CommunitiesService.init() failed: $e');
      rethrow;
    }
  }

  /// Rebuild province-based index after database changes
  void _buildProvinceMaps() {
    _communitiesByProvince.clear();
    _provinces.clear();
    _provinces.addAll(saProvinces);

    for (final community in _allCommunities) {
      final province = community['province'] as String? ?? 'Unknown';
      // _provinces.add(province); // We use the static list now

      if (!_communitiesByProvince.containsKey(province)) {
        _communitiesByProvince[province] = [];
      }
      _communitiesByProvince[province]!.add(community);
    }
  }

  /// Get all provinces with communities
  List<String> get provinces => _provinces.toList()..sort();

  /// Get all communities
  List<Map<String, dynamic>> get all => _allCommunities;

  /// Get communities by province
  List<Map<String, dynamic>> getByProvince(String province) {
    return _communitiesByProvince[province] ?? [];
  }

  /// Get community by ID
  Map<String, dynamic>? getById(String communityId) {
    try {
      return _allCommunities.firstWhere(
        (c) => c['id'] == communityId,
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      return null;
    }
  }

  /// Find communities near a coordinate (within radius_km)
  List<Map<String, dynamic>> findNear(double lat, double lng) {
    final nearby = <Map<String, dynamic>>[];

    for (final community in _allCommunities) {
      final cLat = community['center_lat'] as double? ?? 0;
      final cLng = community['center_lng'] as double? ?? 0;
      final radius = community['radius_km'] as double? ?? 0;

      final distance = _calculateDistance(lat, lng, cLat, cLng);
      if (distance <= radius) {
        nearby.add(community);
      }
    }

    return nearby;
  }

  /// Calculate distance between two coordinates in km (Haversine formula)
  static double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2));

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
