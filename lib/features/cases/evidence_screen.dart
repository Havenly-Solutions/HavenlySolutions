import 'package:flutter/material.dart';
import './models/case_model.dart';
import '../../core/widgets/saps_badge.dart';

class EvidenceScreen extends StatelessWidget {
  final CaseModel caseModel;

  const EvidenceScreen({required this.caseModel, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002366),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Evidence Log',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Center(child: SapsBadge()))],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'EVIDENCE ITEMS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF8A9BB0), letterSpacing: 1.2),
              ),
            ),
            _buildPhotoItem(),
            _buildPdfItem(),
            _buildVideoItem(),
            const SizedBox(height: 24),
            _buildUploadZone(context),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Text(
                'CHAIN OF CUSTODY LOG',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF8A9BB0), letterSpacing: 1.2),
              ),
            ),
            _buildChainOfCustodyTable(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF002366), Color(0xFF1A3A6E)],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caseModel.refNumber.toUpperCase(),
            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Case Documentation',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: 'serif'),
          ),
          const SizedBox(height: 12),
          Text(
            'Location: ${caseModel.locationAddress}\nOfficer: Assigned Upon Review',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF002366),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Evidence', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDDE3EE))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFF0D1B2A), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, color: Colors.white24, size: 48),
                SizedBox(height: 8),
                Text('Scene Photograph', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('IMAGE FILE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF8A9BB0))),
                    _buildMiniBadge('Analysing', const Color(0xFFE8F0FE), const Color(0xFF1A56DB)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Photo of scene at time of incident.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('12 Aug 2024, 14:22 \u2022 ID: IMG_0812_SAPS', style: TextStyle(fontSize: 11, color: Color(0xFF8A9BB0))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfItem() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDDE3EE))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.picture_as_pdf, color: Color(0xFFCC0000), size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('medical_report_signed.pdf', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('1.2 MB \u2022 Document', style: TextStyle(fontSize: 11, color: Color(0xFF8A9BB0))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniBadge('Transcribed', const Color(0xFFE8F0FE), const Color(0xFF1A56DB)),
              const SizedBox(width: 8),
              _buildMiniBadge('Verified', const Color(0xFFD1FAE5), const Color(0xFF065F46)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6FA),
              border: Border(left: BorderSide(color: Color(0xFF002366), width: 3)),
            ),
            child: const Text(
              '"Patient presents with bruising on upper left arm consistent with blunt force trauma..."',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF4A5568)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF002366))),
                  child: const Text('Download', style: TextStyle(color: Color(0xFF002366), fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF002366), elevation: 0),
                  child: const Text('Preview', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoItem() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDDE3EE))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.videocam, color: Color(0xFF1A56DB), size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Video Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Video \u2022 0:45 duration', style: TextStyle(fontSize: 11, color: Color(0xFF8A9BB0))),
                  ],
                ),
              ),
              _buildMiniBadge('Processing', const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('CCTV footage from street corner.', style: TextStyle(fontSize: 12, color: Color(0xFF4A5568))),
        ],
      ),
    );
  }

  Widget _buildUploadZone(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3EE), width: 1),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.file_upload_outlined, color: Color(0xFF8A9BB0), size: 32),
          SizedBox(height: 8),
          Text('Upload additional evidence', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A5568))),
          Text('JPG, PDF, MP4 up to 50MB', style: TextStyle(fontSize: 10, color: Color(0xFF8A9BB0))),
        ],
      ),
    );
  }

  Widget _buildChainOfCustodyTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDDE3EE))),
      child: DataTable(
        columnSpacing: 8,
        dataRowMinHeight: 48,
        columns: const [
          DataColumn(label: Text('DATE/TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('OFFICER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
        ],
        rows: [
          DataRow(cells: [
            const DataCell(Text('12/08 14:45', style: TextStyle(fontSize: 11))),
            const DataCell(Text('Collected', style: TextStyle(fontSize: 11))),
            const DataCell(Text('System', style: TextStyle(fontSize: 11))),
            DataCell(_buildMiniBadge('In Transit', const Color(0xFFE8F0FE), const Color(0xFF1A56DB))),
          ]),
          DataRow(cells: [
            const DataCell(Text('12/08 15:10', style: TextStyle(fontSize: 11))),
            const DataCell(Text('Encrypted', style: TextStyle(fontSize: 11))),
            const DataCell(Text('Vault-01', style: TextStyle(fontSize: 11))),
            DataCell(_buildMiniBadge('Secured', const Color(0xFFD1FAE5), const Color(0xFF065F46))),
          ]),
          DataRow(cells: [
            const DataCell(Text('13/08 09:00', style: TextStyle(fontSize: 11))),
            const DataCell(Text('Hashed', style: TextStyle(fontSize: 11))),
            const DataCell(Text('Audit-SAPS', style: TextStyle(fontSize: 11))),
            DataCell(_buildMiniBadge('Finalised', const Color(0xFFF3F4F6), const Color(0xFF6B7280))),
          ]),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
