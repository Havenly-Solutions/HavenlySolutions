import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/translations.dart';
import '../../core/providers/language_provider.dart';
import '../../core/widgets/app_background.dart';
import '../../core/security/secure_storage_service.dart';
import '../../providers/user_provider.dart';
import '../../services/sos_service.dart';
import '../../app/routes.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final List<String> _pin = ['', '', '', ''];
  int _attempts = 0;
  bool _locked = false;
  bool _sosTriggered = false;
  int _sosCountdown = 60; // 1 minute countdown
  int _lockCountdown = 120;
  Timer? _countdownTimer;

  void _onDigit(String d) {
    if (_locked) return;
    final idx = _pin.indexOf('');
    if (idx == -1) return;
    setState(() => _pin[idx] = d);
    if (_pin.every((c) => c.isNotEmpty)) {
      Future.delayed(const Duration(milliseconds: 150), _checkPin);
    }
  }

  void _onDelete() {
    final last = _pin.lastIndexWhere((c) => c.isNotEmpty);
    if (last == -1) return;
    setState(() => _pin[last] = '');
  }

  Future<void> _checkPin() async {
    // If the widget was removed (e.g. during hot restart or quick navigation),
    // do not proceed with authentication check.
    if (!mounted) return;

    final userProvider = context.read<UserProvider>();
    final entered = _pin.join();

    final prefs = await SharedPreferences.getInstance();
    final identifier = prefs.getString('user_phone') ?? '';
    final deviceId = await SecureStorageService.getOrCreateDeviceId();

    debugPrint('[Auth] Attempting login for $identifier');

    // We'll send the raw PIN for now as the provider/backend comparison
    // requires a stable value. BCrypt.hashpw creates a random salt
    // and a new hash every time, making it impossible to match
    // unless compared using checkpw on the server side.
    final success = await userProvider.login(identifier, entered, deviceId);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    }

    _attempts++;
    setState(() => _pin.fillRange(0, 4, ''));

    if (_attempts >= 3) {
      _triggerSOS();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _attempts == 2
                ? AppTranslations.t('pin_wrong_2')
                : AppTranslations.t('pin_wrong'),
          ),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
  }

  void _triggerSOS() {
    setState(() {
      _locked = true;
      _sosTriggered = true;
      _sosCountdown = 60;
    });
    _startSOSCountdown();
    _startLockCountdown();
  }

  void _startSOSCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_sosCountdown > 0 && _sosTriggered) {
        setState(() => _sosCountdown--);
      } else {
        timer.cancel();
        if (_sosTriggered) {
          _dispatchSOS();
        }
      }
    });
  }

  Future<void> _dispatchSOS() async {
    if (!mounted) return;
    setState(() => _sosTriggered = false);
    await SOSService().triggerSOS(triggerType: SOSTriggerType.failedLogin);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/sos_active');
    }
  }

  void _startLockCountdown() async {
    while (_lockCountdown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _lockCountdown--);
    }
    if (mounted) {
      setState(() {
        _locked = false;
        _attempts = 0;
        _lockCountdown = 120;
      });
    }
  }

  void _cancelSOS() {
    setState(() => _sosTriggered = false);
    _countdownTimer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTranslations.t('sos_cancelled')),
        backgroundColor: Colors.black,
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    final user = context.watch<UserProvider>().currentUser;
    final greeting =
        user?.welcomeDisplayName ?? AppTranslations.t('welcome_back');

    return AppBackground(
      headerTitle: greeting,
      headerSubtitle: 'Enter your secure Havenly PIN',
      cardHeightFactor: 0.72,
      showBackButton: true,
      isCleanMode: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppTranslations.t('enter_pin'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = _pin[i].isNotEmpty;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _locked
                        ? Colors.grey.shade300
                        : filled
                            ? Colors.black
                            : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            if (_locked) ...[
              const SizedBox(height: 24),
              Text(
                AppTranslations.t('pin_lockout_title'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${AppTranslations.t('retry_in')} $_lockCountdown ${AppTranslations.t('seconds')}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              if (_sosTriggered) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppTranslations.t('pin_sos_warning'),
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$_sosCountdown ${AppTranslations.t('seconds')}',
                        style: const TextStyle(
                            color: Color(0xFFC0392B),
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _cancelSOS,
                        child: Text(AppTranslations.t('cancel_sos'),
                            style: const TextStyle(
                                color: Color(0xFFC0392B),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 32),
            if (!_locked) ...[
              _Keypad(onDigit: _onDigit, onDelete: _onDelete),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.forgotPin),
                child: Text(AppTranslations.t('forgot_pin'),
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  const _Keypad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];
    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 72, height: 72);
            return GestureDetector(
              onTap: () => k == 'del' ? onDelete() : onDigit(k),
              child: Container(
                width: 72,
                height: 72,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(36)),
                alignment: Alignment.center,
                child: k == 'del'
                    ? const Icon(Icons.backspace_outlined,
                        color: Colors.black, size: 22)
                    : Text(k,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
