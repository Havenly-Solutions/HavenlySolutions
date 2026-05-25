import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/user_provider.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tryBiometricLogin();
  }

  Future<void> _tryBiometricLogin() async {
    final enabled = await BiometricService.instance.isBiometricLoginEnabled();
    if (!enabled) return;
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 400));

    final result = await BiometricService.instance.authenticate(
      reason: 'Log in to Havenly Solutions',
      allowDeviceCredential: true,
    );

    if (!mounted) return;
    if (result == BiometricResult.success) {
      final token = await SecureStorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        try {
          await ref.read(userProvider.notifier).loginWithToken(token);
          if (!mounted) return;
          context.go('/home');
        } catch (_) {
          // Ignore token login failure and let user sign in manually.
        }
      }
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(userProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      final pinSet = await SecureStorageService.isPinSet();
      if (mounted) {
        context.go(pinSet ? '/pin-login' : '/pin-creation');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
