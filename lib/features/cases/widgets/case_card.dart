import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/case_model.dart';

class CaseCard extends StatelessWidget {
  final CaseModel caseModel;
  final VoidCallback onTap;

  const CaseCard({
    required this.caseModel,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE3EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  caseModel.refNumber.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A9BB0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _StatusBadge(status: caseModel.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              caseModel.incidentType,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF8A9BB0)),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(caseModel.incidentDate),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProgressSection(status: caseModel.status),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  caseModel.synced ? Icons.cloud_done : Icons.cloud_off,
                  size: 14,
                  color: caseModel.synced ? const Color(0xFF1A7A4A) : const Color(0xFFD97706),
                ),
                const SizedBox(width: 6),
                Text(
                  caseModel.synced ? 'Synced' : 'Pending upload',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: caseModel.synced ? const Color(0xFF1A7A4A) : const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label = status.replaceAll('_', ' ').toUpperCase();

    switch (status.toLowerCase()) {
      case 'received':
        bgColor = const Color(0xFFE8F0FE);
        textColor = const Color(0xFF1A56DB);
        break;
      case 'under_review':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        break;
      case 'urgent':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFCC0000);
        break;
      case 'pending':
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        break;
      case 'closed':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final String status;

  const _ProgressSection({required this.status});

  @override
  Widget build(BuildContext context) {
    double progress = 0.2;
    String label = 'Case Received';

    if (status == 'under_review') {
      progress = 0.5;
      label = 'SAPS Review in Progress';
    } else if (status == 'urgent') {
      progress = 0.8;
      label = 'Urgent SAPS Action';
    } else if (status == 'closed') {
      progress = 1.0;
      label = 'Case Finalised';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: const Color(0xFFF0F3F8),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF002366)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
      ],
    );
  }
}
