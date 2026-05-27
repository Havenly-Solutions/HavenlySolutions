import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/translations.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class OTPVerificationView extends StatefulWidget {
  final String phoneNumber;
  final void Function(String verificationToken) onVerified;
  
  const OTPVerificationView({
    super.key,
    required this.phoneNumber,
    required this.onVerified,
  });

  @override
  State<OTPVerificationView> createState() => _OTPVerificationViewState();
}

class _OTPVerificationViewState extends State<OTPVerificationView> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  int _timerSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _sendOtp();
  }

  void _startTimer() {
    _timerSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  Future<void> _sendOtp() async {
    try {
      // API call to send OTP (assuming we have /api/mobile/auth/otp/send)
      // For now, use ApiService placeholder or real call if implemented
      // (I'll assume it's implemented in ApiService based on backend work)
      // await ApiService().sendOtp(widget.phoneNumber);
    } catch (e) {
      debugPrint('[OTP] Send failed: $e');
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Mock call or real call
      // In a real implementation:
      // final response = await ApiService().verifyOtp(widget.phoneNumber, _otpController.text);
      // widget.onVerified(response.verificationToken);

      // MOCK for demonstration:
      await Future.delayed(const Duration(seconds: 1));
      if (_otpController.text == '123456') {
        widget.onVerified('mock_verification_token_${DateTime.now().millisecondsSinceEpoch}');
      } else {
        setState(() => _error = 'Invalid OTP. Try 123456 for testing.');
      }
    } catch (e) {
      setState(() => _error = 'Verification failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.sms_outlined, size: 64, color: Color(0xFF1A3D3D)),
          const SizedBox(height: 24),
          Text(
            AppTranslations.t('verify_phone'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'We sent a 6-digit code to ${widget.phoneNumber}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              if (val.length == 6) _verifyOtp();
            },
          ),
          
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          
          const SizedBox(height: 32),
          
          TextButton(
            onPressed: _timerSeconds == 0 ? () {
              _startTimer();
              _sendOtp();
            } : null,
            child: Text(
              _timerSeconds == 0 ? 'Resend Code' : 'Resend in ${_timerSeconds}s',
              style: TextStyle(color: _timerSeconds == 0 ? AppColors.primary : Colors.grey),
            ),
          ),
          
          const SizedBox(height: 48),
          
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003333),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Verify & Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
