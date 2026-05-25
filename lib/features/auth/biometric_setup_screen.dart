import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/biometric_service.dart';
import '../../core/theme/app_colors.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  bool _loading = false;
  String? _status;
  bool _done = false;

  Future<void> _enroll() async {
    setState(() {
      _loading = true;
      _status = null;
    });

    final result = await BiometricService.instance.authenticate(
      reason: 'Register your biometric to enable quick login',
      allowDeviceCredential: false,
    );

    if (!mounted) return;

    if (result == BiometricResult.success) {
      await BiometricService.instance.enrollBiometric();
      setState(() {
        _done = true;
        _status = 'Biometric registered successfully.';
        _loading = false;
      });
    } else if (result == BiometricResult.notAvailable ||
        result == BiometricResult.notEnrolled) {
      setState(() {
        _status =
            'No biometric found on this device. You can enable it later in Settings.';
        _loading = false;
      });
    } else {
      setState(() {
        _status =
            'Biometric setup cancelled. You can enable it later in Profile → Security.';
        _loading = false;
      });
    }
  }

  void _skip() {
    context.go('/home');
  }

  void _continue() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _done ? Icons.check_circle_rounded : Icons.face_rounded,
                  size: 48,
                  color: _done ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _done ? 'You\'re all set!' : 'Enable Face / Fingerprint Login',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _done
                    ? 'You can now log in instantly with your biometric — just like your banking app.'
                    : 'Log in with one look or touch — faster and more secure than a password.',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              if (_status != null) ...[
                const SizedBox(height: 16),
                Text(
                  _status!,
                  style: TextStyle(
                    fontSize: 13,
                    color: _done ? AppColors.success : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 40),
              if (!_done) ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _enroll,
                    icon: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.fingerprint_rounded),
                    label: const Text('Set up biometric login'),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _skip,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _continue,
                    child: const Text('Continue to Havenly Solutions'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
