import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class NewsFeedScreen extends ConsumerStatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  ConsumerState<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends ConsumerState<NewsFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: AssetImage('assets/images/logo.png'),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Public Safety',
                style: AppTypography.heading2.copyWith(fontSize: 18)),
            Text('Precinct Central',
                style: AppTypography.label
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined,
                color: Colors.black),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                _buildTab('All Alerts', true),
                _buildTab('Missing Persons', false),
                _buildTab('Security Concerns', false),
                _buildTab('Weather', false),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildPostAlertButton(),
          const SizedBox(height: 16),
          _buildSilverAlert(),
          const SizedBox(height: 16),
          _buildSuspiciousActivityReport(),
          const SizedBox(height: 16),
          _buildNeighborhoodSafetyScore(),
          const SizedBox(height: 16),
          _buildWeatherWarning(),
          const SizedBox(height: 100), // Space for floating nav
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPostAlertButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.post_add),
        label: const Text('Post Alert'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildSilverAlert() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset('assets/images/stay_safe.png',
                    height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.red[800],
                      borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('URGENT ALERT',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('SILVER ALERT: James Peterson',
                          style: AppTypography.heading2.copyWith(fontSize: 18)),
                    ),
                    Text('2h ago', style: AppTypography.label),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Last seen near the North Precinct Central Park at 4:30 PM. Wearing a tan windbreaker...',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoBadge('AGE', '68 Years'),
                    const SizedBox(width: 12),
                    _buildInfoBadge('LOCATION', 'Central District'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.phone),
                        label: const Text('Contact Authorities'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.share_outlined, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuspiciousActivityReport() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8)),
                child: Image.asset('assets/images/logo.png',
                    width: 20, height: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Suspicious Activity Report',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Oakwood Residential Area • 45m ago',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
              'Residents reported an unidentified white van circulating the cul-de-sac multiple times this morning.'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/images/stay_safe.png',
                height: 150, width: double.infinity, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  Widget _buildNeighborhoodSafetyScore() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NEIGHBORHOOD SAFETY SCORE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('94',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              const Text(' /100',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const Spacer(),
              Text('+4% improvement from last month',
                  style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildScoreBar('Patrol Frequency', 0.9, 'High'),
          const SizedBox(height: 12),
          _buildScoreBar('Response Time', 0.8, '4.2 min'),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, double value, String status) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(status,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation(Colors.black),
            minHeight: 4),
      ],
    );
  }

  Widget _buildWeatherWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[100]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_outlined, color: Colors.orange),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4)),
                child: const Text('CAUTION',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Severe Weather Warning',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Text(
              'High winds and potential flooding expected near coastal areas after 8:00 PM tonight.',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}
