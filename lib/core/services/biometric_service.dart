import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import '../security/secure_storage_service.dart';

enum BiometricResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  lockedOut,
  cancelled,
}

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isHardwareSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasEnrolledBiometrics() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<BiometricResult> authenticate({
    String reason = 'Verify your identity to access Havenly Solutions',
    bool allowDeviceCredential = false,
  }) async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        return BiometricResult.notAvailable;
      }

      final enrolled = await hasEnrolledBiometrics();
      if (!enrolled && !allowDeviceCredential) {
        return BiometricResult.notEnrolled;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: !allowDeviceCredential,
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );

      return authenticated ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notEnrolled:
          return BiometricResult.notEnrolled;
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return BiometricResult.lockedOut;
        case auth_error.notAvailable:
          return BiometricResult.notAvailable;
        default:
          return BiometricResult.cancelled;
      }
    } catch (_) {
      return BiometricResult.failed;
    }
  }

  Future<void> enrollBiometric() async {
    await SecureStorageService.setBiometricRegistered(true);
  }

  Future<bool> isBiometricLoginEnabled() async {
    final hardwareOk = await isHardwareSupported();
    final osEnrolled = await hasEnrolledBiometrics();
    final userOptedIn = await SecureStorageService.isBiometricRegistered();
    return hardwareOk && osEnrolled && userOptedIn;
  }
}
