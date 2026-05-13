import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sos_orchestrator.dart';

enum SOSStatus { idle, countdown, active, cancelled }

class SOSState {
  final SOSStatus status;
  final int countdownSeconds;
  final bool isSilent;

  SOSState({
    this.status = SOSStatus.idle,
    this.countdownSeconds = 35,
    this.isSilent = false,
  });

  SOSState copyWith({
    SOSStatus? status,
    int? countdownSeconds,
    bool? isSilent,
  }) {
    return SOSState(
      status: status ?? this.status,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      isSilent: isSilent ?? this.isSilent,
    );
  }
}

final sosProvider = StateNotifierProvider<SOSNotifier, SOSState>((ref) {
  return SOSNotifier();
});

class SOSNotifier extends StateNotifier<SOSState> {
  SOSNotifier() : super(SOSState());

  void startCountdown({bool silent = false}) {
    state = state.copyWith(status: SOSStatus.countdown, isSilent: silent, countdownSeconds: 35);
  }

  void updateCountdown(int seconds) {
    state = state.copyWith(countdownSeconds: seconds);
  }

  Future<void> triggerSOS() async {
    state = state.copyWith(status: SOSStatus.active);
    await SosOrchestrator.trigger();
  }

  Future<void> cancelSOS() async {
    await SosOrchestrator.cancel();
    state = state.copyWith(status: SOSStatus.cancelled);
    Future.delayed(const Duration(seconds: 2), () {
      state = state.copyWith(status: SOSStatus.idle);
    });
  }

  void reset() {
    state = SOSState();
  }
}
