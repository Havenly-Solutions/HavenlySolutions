import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'widgets/identity_verification_view.dart';
import 'widgets/personal_details_view.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 1;

  void _nextStep() {
    setState(() {
      _currentStep = 2;
    });
  }

  void _previousStep() {
    setState(() {
      _currentStep = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep == 2 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: _previousStep,
            )
          : Image.asset('assets/images/logo.png', width: 22, height: 22),
        title: Text('Havenly', style: AppTypography.heading2.copyWith(fontSize: 18, color: AppColors.darkNav)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[100],
              child: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentStep == 1 
          ? PersonalDetailsView(onContinue: _nextStep)
          : IdentityVerificationView(onComplete: () => context.go('/account-creation')),
      ),
    );
  }
}
