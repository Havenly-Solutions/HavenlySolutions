import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/translations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'models/signup_data.dart';
import 'widgets/identity_verification_view.dart';
import 'widgets/personal_details_view.dart';
import 'widgets/otp_verification_view.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 1;
  SignupData? _signupData;

  void _nextStep(SignupData data) {
    setState(() {
      _signupData = data;
      _currentStep = 2;
    });
  }

  void _onOtpVerified(String token) {
    setState(() {
      _signupData = _signupData?.copyWith(verificationToken: token);
      _currentStep = 3;
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 1) _currentStep--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => _currentStep > 1 ? _previousStep() : context.pop(),
        ),
        title: Text(
          _currentStep == 1
              ? AppTranslations.t('signup title')
              : _currentStep == 2 
                  ? 'Verify Phone'
                  : AppTranslations.t('identity verification'),
          style: AppTypography.heading2
              .copyWith(fontSize: 18, color: AppColors.darkNav),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[100],
              child: const Icon(Icons.person_outline,
                  color: Colors.black54, size: 20),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStepContent(),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentStep == 1) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.t('Need Emergency Access'),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/guest-auth'),
                    icon: const Icon(Icons.emergency, size: 16),
                    label: Text(
                      AppTranslations.t('Continue as Guest'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return PersonalDetailsView(
            key: const ValueKey(1), onContinue: _nextStep);
      case 2:
        return OTPVerificationView(
          key: const ValueKey(2),
          phoneNumber: _signupData?.phoneNumber ?? '',
          onVerified: _onOtpVerified,
        );
      case 3:
        return IdentityVerificationView(
          key: const ValueKey(3),
          onComplete: (hash, url) {
            if (_signupData != null) {
              final finalData =
                  _signupData!.copyWith(faceImageHash: hash, faceImageUrl: url);
              context.go('/account-creation', extra: finalData);
            }
          },
          verificationToken: _signupData?.verificationToken ?? '',
        );
      default:
        return const Center(child: Text('Invalid step'));
    }
  }
}
