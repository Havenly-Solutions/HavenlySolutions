import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'dart:async';

class IdentityVerificationView extends StatefulWidget {
  final VoidCallback onComplete;
  const IdentityVerificationView({super.key, required this.onComplete});

  @override
  State<IdentityVerificationView> createState() =>
      _IdentityVerificationViewState();
}

class _IdentityVerificationViewState extends State<IdentityVerificationView> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;
  bool _isScanning = false;
  String _statusMessage = 'Position your face\nwithin the frame';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Find front camera if possible
        CameraDescription? frontCamera;
        try {
          frontCamera = _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
          );
        } catch (e) {
          frontCamera = _cameras!.first;
        }

        _controller = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _controller!.initialize();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning face...';
    });

    // Simulate scanning process
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Verification Successful!';
        });
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            widget.onComplete();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('Identity Verification',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3D3D))),
          const SizedBox(height: 4),
          const Text('Step 2 of 2',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 32),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3D3D)),
          ),
          const SizedBox(height: 12),
          const Text('Ensure good lighting and remove glasses if possible.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 48),

          // Face Frame with Camera Preview
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 20)
                  ],
                ),
                child: ClipOval(
                  child: _isInitializing
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF003333)))
                      : (_controller != null &&
                              _controller!.value.isInitialized)
                          ? AspectRatio(
                              aspectRatio: 1.0,
                              child: CameraPreview(_controller!),
                            )
                          : const Center(
                              child: Icon(Icons.camera_alt,
                                  size: 50, color: Colors.grey)),
                ),
              ),
              // Oval Overlay
              Container(
                width: 180,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isScanning ? Colors.green : Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              if (_isScanning)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 3),
                  builder: (context, value, child) {
                    return Positioned(
                      top: 20 + (180 * value),
                      child: Container(
                        width: 180,
                        height: 2,
                        color: Colors.green.withOpacity(0.5),
                      ),
                    );
                  },
                ),
            ],
          ),

          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 18, height: 18),
              const SizedBox(width: 8),
              const Text('Emergency Services Access',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A3D3D))),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'This scan helps emergency services identify you in urgent situations. Your data is encrypted locally.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
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
                  decoration: BoxDecoration(
                      color: Colors.blue[50], shape: BoxShape.circle),
                  child: Image.asset('assets/images/logo.png',
                      width: 20, height: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Why is this needed?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        'To guarantee that requested dispatches are sent to the verified account holder, preventing false alarms.',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _isScanning || _isInitializing ? null : _startScan,
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.qr_code_scanner,
                    color: Colors.white, size: 18),
            label: Text(
              _isScanning ? 'Verifying...' : 'Start Scan',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003333),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
