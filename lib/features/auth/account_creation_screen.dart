import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AccountCreationScreen extends ConsumerStatefulWidget {
  const AccountCreationScreen({super.key});

  @override
  ConsumerState<AccountCreationScreen> createState() =>
      _AccountCreationScreenState();
}

class _AccountCreationScreenState extends ConsumerState<AccountCreationScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createAccount() async {
    setState(() => _isLoading = true);
    try {
      // Simulate account creation
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/pin-creation');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Details')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'ID Number')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createAccount,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
