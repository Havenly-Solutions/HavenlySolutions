import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/user_provider.dart';
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

  void _onNumberTap(String value) {
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
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _loginWithPin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(userProvider.notifier).pinLogin(_pin);
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
    // Logic for silent SOS
    // Screen shows nothing, dispatches in background
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Security threshold reached. Silent SOS activated.')),
    );
    // In a real app, this would be much more discreet
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final firstName = user?.fullName.split(' ').first ?? 'User';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.asset('assets/images/logo.png', width: 80),
            const SizedBox(height: 32),
            Text(
              'Welcome Back, \$firstName',
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
                    color: isFilled ? AppColors.brandDeep : Colors.grey[300],
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
            _buildKeypad(),
          ],
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
