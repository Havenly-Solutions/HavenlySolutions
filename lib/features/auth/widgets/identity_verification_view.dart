import 'package:flutter/material.dart';

class IdentityVerificationView extends StatelessWidget {
  final VoidCallback onComplete;
  const IdentityVerificationView({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('Identity Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3D3D))),
          const SizedBox(height: 4),
          const Text('Step 2 of 2', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 32),
          const Text('Position your face\nwithin the frame', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A3D3D))),
          const SizedBox(height: 12),
          const Text('Ensure good lighting and remove glasses if possible.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 48),
          
          // Face Frame exactly like the image
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                ),
              ),
              Container(
                width: 180,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
            ],
          ),
          
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 18, height: 18),
              const SizedBox(width: 8),
              const Text('Emergency Services Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A3D3D))),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'This scan helps emergency services identify you in urgent situations. Your data is encrypted locally.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                  child: Image.asset('assets/images/logo.png', width: 20, height: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Why is this needed?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        'To guarantee that requested dispatches are sent to the verified account holder, preventing false alarms.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
            label: const Text('Start Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003333),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
