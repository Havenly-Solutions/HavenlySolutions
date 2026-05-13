import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'widgets/sos_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final firstName = user?.fullName.split(' ').first ?? 'Officer';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(backgroundImage: AssetImage('assets/images/logo.png')),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Public Safety', style: AppTypography.heading2.copyWith(fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_outlined, color: Colors.black), onPressed: () => context.push('/notifications')),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Good morning, $firstName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text('Your patrol shift is currently active in District 4.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 20),
              
              _buildStatsCard(),
              const SizedBox(height: 20),
              
              _buildMapSector(),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Alerts', style: AppTypography.heading2),
                  TextButton(onPressed: () {}, child: const Text('View Dispatch', style: TextStyle(color: Colors.blueGrey, fontSize: 12))),
                ],
              ),
              const SizedBox(height: 12),
              _buildAlertItem(Icons.error_outline, Colors.red[100]!, Colors.red[800]!, 'Vehicle Theft in Progress', 'Oak Street & 5th Avenue • Dispatch ID #8812', '2m ago'),
              _buildAlertItem(null, Colors.orange[100]!, Colors.orange[800]!, 'Medical Assistance Needed', 'Central Plaza Park • Dispatch ID #8809', '14m ago', logo: true),
              
              const SizedBox(height: 24),
              Text('Quick Actions', style: AppTypography.heading2),
              const SizedBox(height: 16),
              _buildQuickActionsGrid(context),
              
              const SizedBox(height: 120), // Bottom padding for nav
            ],
          ),
          
          // SOS BUTTON - CENTER MIDDLE
          Center(
            child: SosButton(
              onTriggered: () => context.push('/emergency'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTIVE ALERTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text('04', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.description_outlined, color: Colors.blueAccent),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              _buildStatDetail('PATROL TIME', '05h 12m'),
              const Spacer(),
              _buildStatDetail('AREA STATUS', 'High Alert', isAlert: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDetail(String label, String val, {bool isAlert = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isAlert ? Colors.red[800] : Colors.black87)),
      ],
    );
  }

  Widget _buildMapSector() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(image: AssetImage('assets/images/stay_safe.png'), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]),
        ),
        padding: const EdgeInsets.all(16),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CURRENT SECTOR', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('North Downtown Transit', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(IconData? icon, Color bg, Color iconColor, String title, String sub, String time, {bool logo = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[100]!)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: logo 
              ? Image.asset('assets/images/logo.png', width: 20, height: 20)
              : Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildActionCard(Icons.edit_document, 'New Report', () {}),
        _buildActionCard(Icons.search, 'ID Lookup', () {}),
        _buildActionCard(Icons.radio, 'Radio Sync', () {}),
        _buildActionCard(Icons.folder_open, 'Documents', () {}),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
