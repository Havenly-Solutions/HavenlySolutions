import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all mandatory permissions for SOS and Safety features.
  static Future<bool> requestMandatoryPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationAlways,
      Permission.sms,
      Permission.phone,
      Permission.contacts,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      // Required for Android 13+
      if (Platform.isAndroid) Permission.nearbyWifiDevices,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// Alias for requestMandatoryPermissions to support existing UI calls
  static Future<void> requestSosPermissions() async {
    await requestMandatoryPermissions();
  }

  static Future<bool> hasPermission(Permission permission) async {
    return await permission.isGranted;
  }
}
