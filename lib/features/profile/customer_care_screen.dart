import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class CustomerCareScreen extends StatelessWidget {
  const CustomerCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Image.asset('assets/images/logo.png', width: 22, height: 22),
        ),
        title: Text('Havenly',
            style: AppTypography.heading2
                .copyWith(fontSize: 18, color: AppColors.darkNav)),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/images/logo.png')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('How can we help you?',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3D3D))),
            const SizedBox(height: 12),
            Text(
              'Search our knowledge base or reach out to our support team.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 32),
            _buildSearchBar(),
            const SizedBox(height: 32),
            _buildLiveChatCard(context),
            const SizedBox(height: 16),
            _buildOperatingHoursCard(),
            const SizedBox(height: 16),
            _buildContactMethod(Icons.phone_outlined, 'Phone Support',
                'Speak directly with a specialist.', '1-800-555-0199'),
            const SizedBox(height: 16),
            _buildContactMethod(
                Icons.email_outlined,
                'Email Support',
                'For detailed inquiries and attachments.',
                'support@havenly.com'),
            const SizedBox(height: 16),
            _buildCommunityForum(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey),
          hintText: 'Search for articles, guides, or keywords',
          hintStyle: TextStyle(fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildLiveChatCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
                color: Color(0xFF2D4F4F), shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline,
                color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          const Text('Live Chat',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3D3D))),
          const SizedBox(height: 8),
          Text(
            'Get immediate assistance from our support agents. Best for quick questions and troubleshooting.',
            style:
                TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFF2D4F4F), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    const Text('Online Now',
                        style: TextStyle(
                            color: Color(0xFF2D4F4F),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () =>
                    context.push('/chat/support?title=Live Support'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3D3D),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Start Chat'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperatingHoursCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F3F4),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Color(0xFF1A3D3D)),
              SizedBox(width: 8),
              Text('Operating Hours',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF1A3D3D))),
            ],
          ),
          const SizedBox(height: 16),
          _buildHourRow('Mon - Fri', '8:00 AM - 8:00 PM EST'),
          const Divider(height: 20),
          _buildHourRow('Saturday', '10:00 AM - 4:00 PM EST'),
          const Divider(height: 20),
          _buildHourRow('Sunday', 'Closed', isClosed: true),
        ],
      ),
    );
  }

  Widget _buildHourRow(String days, String time, {bool isClosed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(days, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        Text(time,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isClosed ? Colors.grey : Colors.black87)),
      ],
    );
  }

  Widget _buildContactMethod(
      IconData icon, String title, String sub, String val) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF3F51B5), size: 20),
          ),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 12),
          Text(val,
              style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildCommunityForum() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12)),
            child:
                const Icon(Icons.forum_outlined, color: Colors.blue, size: 20),
          ),
          const SizedBox(height: 16),
          const Text('Community Forum',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Connect with other users for tips.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {},
            icon: const Text('Browse Discussions',
                style: TextStyle(
                    color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            label: const Icon(Icons.arrow_forward,
                size: 16, color: Colors.blueAccent),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }
}
