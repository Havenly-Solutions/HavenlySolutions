import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../Shared/theme/app_theme.dart';
import '../../core/widgets/saps_badge.dart';
import '../../core/widgets/saps_official_banner.dart';
import './providers/case_provider.dart';
import './widgets/case_card.dart';
import './widgets/activity_log_item.dart';
import './case_create_screen.dart';
import './evidence_screen.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final caseProvider = context.read<CaseProvider>();
      caseProvider.loadCases().then((_) {
        caseProvider.syncPendingCases();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final caseProvider = context.watch<CaseProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            const SapsBadge(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOUTH AFRICAN POLICE SERVICE',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Case Management Portal',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search, color: AppColors.textSecondary),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.filter_list, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const SapsOfficialBanner(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(context),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'YOUR ACTIVE REPORTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8A9BB0),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (caseProvider.isLoading)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator()))
                    else if (caseProvider.cases.isEmpty)
                      _buildEmptyState()
                    else
                      ...caseProvider.cases.map((c) => CaseCard(
                            caseModel: c,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => EvidenceScreen(caseModel: c)),
                            ),
                          )),
                    if (caseProvider.cases.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
                        child: Text(
                          'RECENT ACTIVITY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8A9BB0),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...caseProvider.cases.take(5).map((c) => ActivityLogItem(
                            title:
                                'Case ${c.status.replaceAll('_', ' ').toUpperCase()}',
                            description:
                                'Your report ${c.refNumber} for ${c.incidentType} is currently ${c.status.replaceAll('_', ' ')}.',
                            timestamp: c.createdAt,
                            isUrgent: c.status == 'urgent',
                          )),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CaseCreateScreen()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Report Incident',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF002366), Color(0xFF1A3A6E)],
        ),
        boxShadow: [
          const BoxShadow(
            color: Color.fromRGBO(0, 35, 102, 0.18),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SapsBadge(),
          const SizedBox(height: 16),
          Text(
            'Your safety, officially documented.',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Every report you submit is received directly by SAPS. You are safe and your case matters.',
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CaseCreateScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF002366),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text(
              'Report an Incident',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.description_outlined,
              size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text(
            'No reports yet',
            style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
