import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/sos_provider.dart';
import '../../core/theme/app_colors.dart';

class EmergencyModeScreen extends ConsumerStatefulWidget {
  const EmergencyModeScreen({super.key});

  @override
  ConsumerState<EmergencyModeScreen> createState() =>
      _EmergencyModeScreenState();
}

class _EmergencyModeScreenState extends ConsumerState<EmergencyModeScreen> {
  late Timer _heartbeatTimer;
  String _coords = 'Capturing...';
  double _cancelProgress = 0.0;
  Timer? _cancelTimer;

  final Map<String, bool> _layerStatus = {
    'GPS Location Captured': false,
    'SMS Sent to Emergency Contacts': false,
    'Bluetooth Broadcast Active': false,
    'Backend Notified': false,
    'Community Alerted': false,
  };

  @override
  void initState() {
    super.initState();
    _startSimulatedSOS();
    _startHeartbeat();
  }

  @override
  void dispose() {
    _heartbeatTimer.cancel();
    _cancelTimer?.cancel();
    super.dispose();
  }

  void _startSimulatedSOS() {
    // Simulate each layer completing
    int delay = 500;
    for (var layer in _layerStatus.keys) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) {
          setState(() {
            _layerStatus[layer] = true;
            if (layer == 'GPS Location Captured') {
              _coords = '-26.2041, 28.0473'; // Sample Joburg coords
            }
          });
        }
      });
      delay += 800;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          // Simulate heartbeat update
          _coords = '-26.20${40 + timer.tick}, 28.04${72 + timer.tick}';
        });
      }
    });
  }

  void _onCancelDown() {
    _cancelTimer?.cancel();
    _cancelTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _cancelProgress += 0.01; // 5 seconds = 100 * 50ms
        if (_cancelProgress >= 1.0) {
          timer.cancel();
          _confirmCancel();
        }
      });
    });
  }

  void _onCancelUp() {
    if (_cancelProgress < 1.0) {
      setState(() {
        _cancelProgress = 0.0;
      });
      _cancelTimer?.cancel();
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel SOS?'),
        content:
            const Text('Are you sure you want to cancel the emergency alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO, KEEP ACTIVE',
                style: TextStyle(color: AppColors.emergency)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(sosProvider.notifier).cancelSOS();
              context.go('/home');
            },
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              color: AppColors.emergency,
              child: const Text(
                'EMERGENCY ACTIVE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Status',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    ..._layerStatus.entries.map(
                        (entry) => _buildStatusRow(entry.key, entry.value)),
                    const Spacer(),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'LIVE GPS HEARTBEAT',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _coords,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Location updating...',
                            style: TextStyle(
                                color: AppColors.communityGreen, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    GestureDetector(
                      onLongPressStart: (_) => _onCancelDown(),
                      onLongPressEnd: (_) => _onCancelUp(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: LinearProgressIndicator(
                              value: _cancelProgress,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white30),
                            ),
                          ),
                          const Text(
                            'HOLD 5S TO CANCEL SOS',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          isComplete
              ? const Icon(Icons.check_circle, color: AppColors.communityGreen)
              : const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white54),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isComplete ? Colors.white : Colors.white54,
                fontSize: 16,
              ),
            ),
          ),
          if (isComplete && label == 'GPS Location Captured')
            Text('[$_coords]',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
