import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:async';
import '../../../core/constants/translations.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/face_scan_service.dart';
import '../../../core/validators/face_scan_validator.dart';
import '../../../core/theme/app_colors.dart';

class IdentityVerificationView extends StatefulWidget {
  final void Function(String faceHash, String faceUrl) onComplete;
  final String verificationToken;

  const IdentityVerificationView({
    super.key,
    required this.onComplete,
    required this.verificationToken,
  });

  @override
  State<IdentityVerificationView> createState() =>
      _IdentityVerificationViewState();
}

class _IdentityVerificationViewState extends State<IdentityVerificationView> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isScanning = false;
  bool _isProcessingFrame = false;
  int _consecutiveValidFrames = 0;
  int _frameCount = 0;
  String _statusMessage = AppTranslations.t('identity_scan_ready');
  String? _cameraError;
  final FaceScanService _faceScanService = FaceScanService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _controller = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await _controller!.initialize();
        _cameraError = null;
      } else {
        _cameraError = 'No camera available on this device.';
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      _cameraError = 'Camera unavailable. Please grant permission.';
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _startScan() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isScanning = true;
      _consecutiveValidFrames = 0;
      _statusMessage = 'Hold still — looking for face';
    });

    _controller!.startImageStream(_processImageFrame);
  }

  void _processImageFrame(CameraImage image) async {
    if (_isProcessingFrame || !_isScanning) return;
    
    // Skip frames to reduce CPU load (Process 1 in every 3 frames for better responsiveness)
    _frameCount++;
    if (_frameCount % 3 != 0) return;

    _isProcessingFrame = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessingFrame = false;
        return;
      }

      final faces = await _faceScanService.getFaces(inputImage);
      final validation = FaceScanValidator.validate(faces, image.width, image.height);

      if (!mounted) return;

      setState(() {
        _statusMessage = validation.message;
      });

      if (validation.success) {
        _consecutiveValidFrames++;
        if (_consecutiveValidFrames >= 30) {
          _finalizeCapture();
        }
      } else {
        _consecutiveValidFrames = 0;
      }
    } catch (e) {
      debugPrint('[FaceScan] Frame error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _finalizeCapture() async {
    setState(() {
      _isScanning = false;
      _statusMessage = 'Capture successful! Finalizing...';
    });

    await _controller!.stopImageStream();

    try {
      final xFile = await _controller!.takePicture();
      final result = await _faceScanService.finalizeCapture(xFile);

      // Upload to S3 (Mocked for Demo if token starts with demo_)
      if (widget.verificationToken.startsWith('demo_')) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          widget.onComplete(result.hash, 'https://havenly.solutions/demo-face.jpg');
        }
        return;
      }

      final api = ApiService();
      final uploadInfo = await api.getFaceUploadUrl(widget.verificationToken);
      await api.uploadFace(uploadInfo['uploadUrl'], result.file);

      if (mounted) {
        widget.onComplete(result.hash, uploadInfo['publicUrl']);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Upload failed: $e. Try again.';
          _isScanning = false;
          _consecutiveValidFrames = 0;
        });
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final sensorOrientation = _controller!.description.sensorOrientation;
    final InputImageRotation? rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final InputImageFormat? format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.yuv420)) return null;

    final bytes = _concatenatePlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceScanService.dispose();
    super.dispose();
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
          const Text('Face Scan (Required)',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 32),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3D3D)),
          ),
          const SizedBox(height: 12),
          if (_isScanning)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 40),
               child: LinearProgressIndicator(
                 value: _consecutiveValidFrames / 30,
                 backgroundColor: Colors.grey[200],
                 color: AppColors.primary,
               ),
             ),
          const SizedBox(height: 48),
          
          if (_cameraError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_cameraError!, style: const TextStyle(color: Colors.red)),
            ),
          ],

          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black12),
                child: ClipOval(
                  child: _isInitializing
                      ? const Center(child: CircularProgressIndicator())
                      : (_controller != null && _controller!.value.isInitialized)
                          ? AspectRatio(
                              aspectRatio: 1.0,
                              child: CameraPreview(_controller!),
                            )
                          : const Center(child: Icon(Icons.camera_alt, size: 50, color: Colors.grey)),
                ),
              ),
              Container(
                width: 180,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: _isScanning ? AppColors.primary : Colors.white54, width: 2),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),
          
          if (!_isScanning)
            ElevatedButton.icon(
              onPressed: _cameraError != null || _isInitializing ? null : _startScan,
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text('Start Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003333),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
            ),
          
          const SizedBox(height: 32),
          const Text(
            'Your full face must be visible. Remove hats, masks, or sunglasses.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
