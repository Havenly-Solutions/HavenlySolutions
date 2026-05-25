import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bcrypt/bcrypt.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/security/secure_storage_service.dart';

class PINCreationScreen extends StatefulWidget {
  const PINCreationScreen({super.key});

  @override
  State<PINCreationScreen> createState() => _PINCreationScreenState();
}

class _PINCreationScreenState extends State<PINCreationScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;

  void _onNumberTap(String value) {
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.length < 4) _confirmPin += value;
      } else {
        if (_pin.length < 4) _pin += value;
      }
    });

    if (!_isConfirming && _pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() => _isConfirming = true);
      });
    } else if (_isConfirming && _confirmPin.length == 4) {
      if (_pin == _confirmPin) {
        _savePin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs do not match. Try again.')),
        );
        setState(() {
          _pin = '';
          _confirmPin = '';
          _isConfirming = false;
        });
      }
    }
  }

  void _onBackspace() {
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
        }
      } else {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _savePin() async {
    final hash = BCrypt.hashpw(_pin, BCrypt.gensalt(logRounds: 10));
    await SecureStorageService.savePinHash(hash);
    await SecureStorageService.setPinSet(true);
    if (mounted) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isConfirming
                        ? 'Confirm Your PIN'
                        : 'Set Your Emergency PIN',
                    style: AppTypography.heading1,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This 4-digit PIN activates your SOS from any phone. Keep it secret. Keep it safe.',
                    style: TextStyle(color: AppColors.orange, fontSize: 16),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final currentPin = _isConfirming ? _confirmPin : _pin;
                final isFilled = index < currentPin.length;
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
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '3 wrong attempts = silent SOS fires automatically',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
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
