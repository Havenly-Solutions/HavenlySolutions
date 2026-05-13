import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/sos_orchestrator.dart';
import '../../services/sos_service.dart';
import '../../services/geo_location_service.dart';
import '../../Shared/theme/app_theme.dart';

class SosActiveScreen extends StatefulWidget {
  const SosActiveScreen({super.key});

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<SosActiveScreen>
    with TickerProviderStateMixin {
  // ── ANIMATION ───────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  // ── CANCEL HOLD ─────────────────────────────────────────────
  late AnimationController _cancelHoldController;
  double _cancelProgress = 0;
  bool _cancelHolding = false;

  // ── STATE ────────────────────────────────────────────────────
  bool _cancelling = false;
  DateTime? _triggeredAt;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _cancelHoldController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() => _cancelProgress = _cancelHoldController.value);
        if (_cancelHoldController.value >= 1.0) {
          _handleCancel();
        }
      });

    _triggeredAt = DateTime.now();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cancelHoldController.dispose();
    super.dispose();
  }

  // ── CANCEL ───────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _ConfirmDialog(
        title: 'Accidental Exit?',
        body:
            'Accidentally pressing back will not cancel the SOS. Your safety is active. To stop, use the hold-to-cancel button below.',
        confirmLabel: 'Stay Active',
      ),
    );
    return ok == true;
  }

  Future<void> _handleCancel() async {
    _cancelHoldController.stop();
    setState(() => _cancelling = true);

    final geoService = context.read<GeoLocationService>();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ConfirmDialog(
        title: 'Confirm Cancel',
        body:
            'Are you absolutely sure you want to stop this SOS alert? Emergency services will be stood down.',
        confirmLabel: 'Yes, End SOS',
        confirmRed: true,
      ),
    );

    if (ok == true) {
      final eventId = SosOrchestrator.activeEventId;
      if (eventId != null) {
        await SOSService().cancelSOS(eventId, geoService: geoService);
      }
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() {
        _cancelling = false;
        _cancelProgress = 0;
        _cancelHolding = false;
      });
      _cancelHoldController.reset();
    }
  }

  void _onCancelHoldStart() {
    if (_cancelling) return;
    setState(() {
      _cancelHolding = true;
      _cancelProgress = 0;
    });
    _cancelHoldController.forward(from: 0);
  }

  void _onCancelHoldEnd() {
    if (_cancelProgress < 1.0) {
      _cancelHoldController.stop();
      _cancelHoldController.reset();
      setState(() {
        _cancelHolding = false;
        _cancelProgress = 0;
      });
    }
  }

  // ── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final geoService = context.watch<GeoLocationService>();
    final pos = geoService.currentPosition;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.danger,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Pulsing Animation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Text(
                          'SOS',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                const Text(
                  'SOS ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Emergency services have been notified',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 1),

                // Meta Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 0, 0, 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _MetaRow(
                        label: 'TRIGGERED AT',
                        value: _triggeredAt
                                ?.toLocal()
                                .toString()
                                .substring(11, 19) ??
                            '--:--:--',
                      ),
                      const Divider(color: Colors.white24),
                      _MetaRow(
                        label: 'LOCATION',
                        value: geoService.currentAddress ?? 'Acquiring...',
                      ),
                      if (pos != null)
                         Padding(
                           padding: const EdgeInsets.only(top: 4),
                           child: Text(
                             '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                             style: const TextStyle(color: Colors.white70, fontSize: 10),
                           ),
                         ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // HOLD TO CANCEL
                GestureDetector(
                  onLongPressStart: (_) => _onCancelHoldStart(),
                  onLongPressEnd: (_) => _onCancelHoldEnd(),
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Stack(
                      children: [
                        if (_cancelHolding)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: LinearProgressIndicator(
                                value: _cancelProgress,
                                backgroundColor: Colors.white,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.danger.withValues(alpha: 0.2)),
                              ),
                            ),
                          ),
                        Center(
                          child: Text(
                            _cancelling ? 'ENDING SOS...' : 'HOLD 3S TO CANCEL',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.danger,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final bool confirmRed;

  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.confirmRed = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: GoogleFonts.dmSans(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      content: Text(body, style: GoogleFonts.dmSans(color: AppColors.textPrimary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Go Back', style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                confirmRed ? AppColors.danger : AppColors.textPrimary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
