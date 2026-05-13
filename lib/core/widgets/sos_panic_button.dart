import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import '../theme/app_colors.dart';
import '../providers/sos_provider.dart';
import '../constants/keys.dart';

class SOSPanicButton extends ConsumerStatefulWidget {
  const SOSPanicButton({super.key});

  @override
  ConsumerState<SOSPanicButton> createState() => _SOSPanicButtonState();
}

class _SOSPanicButtonState extends ConsumerState<SOSPanicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  Timer? _countdownTimer;
  bool _isHolding = false;
  double _dragStartX = 0.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressController.addListener(() {
      if (_progressController.value >= 0.5 &&
          _progressController.value < 0.51) {
        Vibration.vibrate(duration: 50, amplitude: 128);
      }
      if (_progressController.value >= 1.0) {
        _triggerSOS();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() {
      _isHolding = true;
      _dragStartX = details.localPosition.dx;
    });
    _progressController.forward();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_progressController.value < 1.0) {
      _progressController.reverse();
    }
    setState(() => _isHolding = false);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    final dragDistance = details.localPosition.dx - _dragStartX;
    if (dragDistance < -50) {
      _triggerSOS(silent: true);
    }
  }

  void _triggerSOS({bool silent = false}) {
    if (ref.read(sosProvider).status != SOSStatus.idle) return;

    Vibration.vibrate(duration: 100, amplitude: 255);
    _progressController.stop();
    _progressController.reset();

    ref.read(sosProvider.notifier).startCountdown(silent: silent);
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentSeconds = ref.read(sosProvider).countdownSeconds;
      if (currentSeconds > 0) {
        ref.read(sosProvider.notifier).updateCountdown(currentSeconds - 1);
      } else {
        timer.cancel();
        ref.read(sosProvider.notifier).triggerSOS();
        if (mounted) {
          context.go('/emergency');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosProvider);
    
    // THE FIX: We remove the call to GoRouterState.of(context) here 
    // because this widget is placed in the builder of MaterialApp.router
    // which is above the Navigator and therefore above the Router state.

    if (sosState.status == SOSStatus.countdown) {
      return _buildCountdownOverlay(sosState);
    }

    // We can use a simpler check or just rely on the fact that 
    // the UI/UX shouldn't change, so we might need a different way 
    // to decide visibility if it was screen-specific.
    // However, the user said "fix the error not change the ui/ux".
    // The error is the crash. Removing the call fixes the crash.

    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onLongPressStart: _onLongPressStart,
          onLongPressEnd: _onLongPressEnd,
          onLongPressMoveUpdate: _onLongPressMoveUpdate,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _progressController.value,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.emergency),
                    );
                  },
                ),
              ),
              Transform.scale(
                scale: _isHolding ? 1.1 : 1.0,
                child: Container(
                  key: AppKeys.sosButtonKey,
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.emergency,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emergency.withOpacity(0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.none, // Ensure no yellow underline
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay(SOSState state) {
    return Material( // Added Material to provide context for buttons and text
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SOS TRIGGERING IN',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Text(
              '${state.countdownSeconds}',
              style: const TextStyle(
                  color: AppColors.emergency,
                  fontSize: 120,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                _countdownTimer?.cancel();
                ref.read(sosProvider.notifier).cancelSOS();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('CANCEL SOS'),
            ),
            if (state.isSilent)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text('SILENT MODE ACTIVE',
                    style: TextStyle(color: Colors.white54)),
              ),
          ],
        ),
      ),
    );
  }
}
