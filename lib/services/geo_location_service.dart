import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'offline_queue_service.dart';

/// FILE: lib/services/geo_location_service.dart
/// PURPOSE: GPS capture, reverse geocoding, auto-detect area
/// PHASE: 13 — PostGIS Integration
///
/// On app open:
///   1. Get current GPS coordinates
///   2. Reverse geocode to suburb, city, province
///   3. Resolve nearest community via backend (PostGIS)
///   4. Cache result in SharedPreferences
///
/// During SOS:
///   Continuous updates every 10 seconds
///   Updates user.last_lat, user.last_lng on backend

class GeoLocationService extends ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  String? _currentSuburb;
  String? _currentCity;
  String? _currentProvince;
  
  // Phase 13: Community Info
  String? _nearestCommunityId;
  String? _nearestCommunityName;
  bool _isInsideCommunity = false;
  
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStream;
  Timer? _resolveThrottle;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  String? get currentSuburb => _currentSuburb;
  String? get currentCity => _currentCity;
  String? get nearestCommunityName => _nearestCommunityName;
  String? get nearestCommunityId => _nearestCommunityId;
  bool get isInsideCommunity => _isInsideCommunity;
  bool get isTracking => _isTracking;

  // Called on app open — auto-detect location
  Future<void> initialise() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _currentPosition = position;
      await _reverseGeocode(position);
      await _resolveCommunity(position);
      notifyListeners();

      // Update user location on backend
      _updateLocationOnBackend(position);
    } catch (e) {
      debugPrint('[Geo] Initialise error: $e');
      // Load last known from SharedPreferences
      await _loadCachedLocation();
    }
  }

  Future<void> _reverseGeocode(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _currentSuburb = place.subLocality ?? place.locality ?? 'Unknown area';
        _currentCity = place.locality ?? '';
        _currentProvince = place.administrativeArea ?? '';
        _currentAddress =
            '${place.street ?? ''}, $_currentSuburb, $_currentCity';

        // Cache for offline use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_address', _currentAddress ?? '');
        await prefs.setString('cached_suburb', _currentSuburb ?? '');
        await prefs.setString('cached_city', _currentCity ?? '');
        await prefs.setString('cached_province', _currentProvince ?? '');
        await prefs.setDouble('cached_lat', position.latitude);
        await prefs.setDouble('cached_lng', position.longitude);
      }
    } catch (e) {
      debugPrint('[Geo] Reverse geocode error: $e');
    }
  }

  // Phase 13: Resolve community using backend PostGIS
  Future<void> _resolveCommunity(Position position) async {
    try {
      final response = await ApiService().post('/api/geo/resolve', data: {
        'lat': position.latitude,
        'lng': position.longitude,
      });

      if (response.data['success']) {
        final community = response.data['data']['nearestCommunity'];
        if (community != null) {
          _nearestCommunityId = community['id'];
          _nearestCommunityName = community['name'];
          _isInsideCommunity = response.data['data']['isInside'] ?? false;
        }
      }
    } catch (e) {
      debugPrint('[Geo] Resolve community error: $e');
    }
  }

  // Update user's last known location on backend
  void _updateLocationOnBackend(Position position) {
    ApiService().patch('/api/users/location', data: {
      'lat': position.latitude,
      'lng': position.longitude,
    }).catchError((_) {});
  }

  // Start continuous tracking (called when SOS activates)
  Future<void> startSosTracking(String sosId) async {
    _isTracking = true;
    notifyListeners();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      _currentPosition = position;
      notifyListeners();

      // Throttled community resolve during tracking (every 30s)
      if (_resolveThrottle == null || !_resolveThrottle!.isActive) {
        _resolveCommunity(position);
        _resolveThrottle = Timer(const Duration(seconds: 30), () {});
      }

      // PATCH location heartbeat to backend
      ApiService().patch('/api/sos/$sosId/location', data: {
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
      }).catchError((_) {
        // If offline: queue the heartbeat
        OfflineQueueService().enqueue('/api/sos/$sosId/location', 'PATCH',
            {'lat': position.latitude, 'lng': position.longitude});
      });
    });
  }

  // Stop tracking (called when SOS is cancelled)
  Future<void> stopSosTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    _resolveThrottle?.cancel();
    notifyListeners();
  }

  Future<void> _loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _currentAddress = prefs.getString('cached_address');
    _currentSuburb = prefs.getString('cached_suburb');
    _currentCity = prefs.getString('cached_city');
    _currentProvince = prefs.getString('cached_province');
    final lat = prefs.getDouble('cached_lat');
    final lng = prefs.getDouble('cached_lng');
    if (lat != null && lng != null) {
      _currentPosition = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _resolveThrottle?.cancel();
    super.dispose();
  }
}
