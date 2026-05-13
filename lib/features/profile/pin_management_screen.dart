import 'package:flutter/material.dart';

class PINManagementScreen extends StatelessWidget {
  const PINManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PIN Management')),
      body: const Center(child: Text('PIN Management Content')),
    );
  }
}
