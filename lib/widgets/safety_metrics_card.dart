import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/safety_metrics.dart';

class SafetyMetricsCard extends StatelessWidget {
  final SafetyMetrics? metrics;
  final bool isLoading;

  const SafetyMetricsCard({
    super.key,
    required this.metrics,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && metrics == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const SizedBox(
          height: 110,
          child: Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1A2E))),
        ),
      );
    }

    final data = metrics;
    if (data == null || !data.hasActivity) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Text(
          'No safety activity yet',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A2E),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR SAFETY RECORD',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            icon: Icons.sos_outlined,
            iconColor: const Color(0xFFC0392B),
            label: 'SOS Triggered',
            value: data.totalSosCount == 0
                ? 'Never triggered'
                : '${data.totalSosCount} time${data.totalSosCount > 1 ? "s" : ""}',
            subValue: data.lastSosAt != null
                ? 'Last: ${_formatDate(data.lastSosAt!)}'
                : null,
          ),
          const Divider(height: 20, color: Color(0xFFE0E0E0)),
          _MetricRow(
            icon: Icons.timer_outlined,
            iconColor: const Color(0xFF1A1A2E),
            label: 'Response Time',
            value: data.lastResponseTimeFormatted,
            subValue: data.avgResponseTimeMs != null
                ? 'Average: ${data.avgResponseTimeFormatted}'
                : null,
          ),
          const Divider(height: 20, color: Color(0xFFE0E0E0)),
          _MetricRow(
            icon: Icons.folder_outlined,
            iconColor: const Color(0xFF0B6E4F),
            label: 'Cases Filed',
            value:
                '${data.totalCasesFiled} filed  ·  ${data.casesResolved} resolved',
            subValue: data.lastCaseAt != null
                ? 'Last: ${_formatDate(data.lastCaseAt!)}'
                : null,
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subValue;

  const _MetricRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 2),
                Text(
                  subValue!,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
