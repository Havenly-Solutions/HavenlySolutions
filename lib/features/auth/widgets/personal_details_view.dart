import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

class PersonalDetailsView extends StatelessWidget {
  final VoidCallback onContinue;
  const PersonalDetailsView({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STEP 1 OF 2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1A3D3D), letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('Personal Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A3D3D))),
          const SizedBox(height: 8),
          Text(
            'Please provide your accurate information to ensure a secure setup within Havenly.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdown('Title', 'Select Title'),
                const SizedBox(height: 16),
                _buildTextField('First Name', 'Enter your first name'),
                const SizedBox(height: 16),
                _buildTextField('Surname', 'Enter your surname'),
                const SizedBox(height: 16),
                _buildDropdown('Gender', 'Select Gender'),
                const SizedBox(height: 16),
                _buildTextField('Date of Birth', 'mm/dd/yyyy', suffixIcon: Icons.calendar_today_outlined),
                const SizedBox(height: 16),
                _buildTextField('ID Number / Passport', 'Enter ID number'),
                const SizedBox(height: 16),
                _buildDropdown('Race / Ethnicity', 'Select Identity'),
                const SizedBox(height: 16),
                _buildTextField('Phone Number', '+1 (555) 000-0000'),
                const SizedBox(height: 16),
                _buildTextField('Email Address', 'name@example.com'),
                const SizedBox(height: 16),
                _buildTextField('Residential Address', '123 Havenly Lane, Suite 100'),
                const SizedBox(height: 16),
                _buildTextField('Community / Neighborhood', 'Search for your community...', icon: Icons.location_on_outlined),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003333),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue to Identity Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {IconData? icon, IconData? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            decoration: InputDecoration(
              icon: icon != null ? Icon(icon, size: 18, color: Colors.grey) : null,
              suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18, color: Colors.black87) : null,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13)),
              const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }
}
