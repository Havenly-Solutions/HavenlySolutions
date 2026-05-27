import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/sos_orchestrator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class PINLoginScreen extends ConsumerStatefulWidget {
  const PINLoginScreen({super.key});

  @override
  ConsumerState<PINLoginScreen> createState() => _PINLoginScreenState();
}

class _PINLoginScreenState extends ConsumerState<PINLoginScreen> {
  String _pin = '';
  int _attempts = 0;
  bool _isLoading = false;
  bool _isLocked = false;

  void _onNumberTap(String value) {
    if (_isLocked) return;
    if (_pin.length < 4) {
      setState(() {
        _pin += value;
      });
    }

    if (_pin.length == 4) {
      _loginWithPin();
    }
  }

  void _onBackspace() {
    if (_isLocked) return;
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _loginWithPin() async {
    setState(() => _isLoading = true);
    final enteredPin = _pin;
    
    try {
      // Check for Duress PIN (mocked for now, should be in secure storage)
      // Section 16: Duress PIN configured by user
      const duressPin = '9999'; // Example
      if (enteredPin == duressPin) {
        unawaited(SosOrchestrator.trigger(threatSource: 'duress_pin'));
        // App behaves normally
        context.go('/home');
        return;
      }

      await ref.read(userProvider.notifier).pinLogin(enteredPin);
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _attempts++;
        _pin = '';
      });

      if (_attempts >= 3) {
        _triggerSilentSOS();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Invalid PIN. ${3 - _attempts} attempts remaining.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _triggerSilentSOS() {
    setState(() {
      _isLocked = true;
    });

    // Section 16: Silent SOS fires without alerting the user
    // trigger_method = 'pin_fail'
    unawaited(SosOrchestrator.trigger(threatSource: 'pin_fail'));

    // Show account locked UI — looks like a normal error
    // (In a real app, this would probably prevent further login for X minutes)
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final firstName = user?.fullName.split(' ').first ?? 'User';

    if (_isLocked) {
      return _buildLockedState();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.asset('assets/images/logo.png', width: 80, errorBuilder: (_,__,___) => const Icon(Icons.shield, size: 80, color: AppColors.primary)),
            const SizedBox(height: 32),
            Text(
              'Welcome Back, $firstName',
              style: AppTypography.heading1,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your PIN to continue',
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : Colors.grey[300],
                  ),
                );
              }),
            ),
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () {
                  // Logout and go to auth
                  ref.read(userProvider.notifier).logout();
                  context.go('/auth');
                },
                child: const Text('Not you? Login with another account'),
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const SizedBox(
                height: 140,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 80, color: AppColors.danger),
              const SizedBox(height: 32),
              const Text(
                'Account Locked',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Too many failed attempts. For your security, this account has been temporarily locked. Please try again in 30 minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text('Return to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3']),
          _buildKeypadRow(['4', '5', '6']),
          _buildKeypadRow(['7', '8', '9']),
          _buildKeypadRow(['', '0', 'backspace']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((val) {
        if (val == '') return const SizedBox(width: 60);
        if (val == 'backspace') {
          return IconButton(
            onPressed: _onBackspace,
            icon: const Icon(Icons.backspace_outlined, size: 28),
          );
        }
        return TextButton(
          onPressed: () => _onNumberTap(val),
          child: Text(
            val,
            style: const TextStyle(
                fontSize: 32, color: Colors.black, fontWeight: FontWeight.w400),
          ),
        );
      }).toList(),
    );
  }
}
