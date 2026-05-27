import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/face_scan_service.dart';
import '../../core/validators/face_scan_validator.dart';
import '../../core/theme/app_colors.dart';

class BiometricScanScreen extends StatefulWidget {
  const BiometricScanScreen({super.key});

  @override
  State<BiometricScanScreen> createState() => _BiometricScanScreenState();
}

class _BiometricScanScreenState extends State<BiometricScanScreen> {
  CameraController? _cameraController;
  final FaceScanService _faceScanService = FaceScanService();
  bool _isProcessing = false;
  int _consecutiveValidFrames = 0;
  String _message = 'Initializing camera...';
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      _cameraController!.startImageStream(_processCameraImage);
      setState(() {
        _message = 'Show yourself — look directly at the camera';
      });
    } catch (e) {
      setState(() {
        _message = 'Error initializing camera: $e';
      });
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing || _isCapturing) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceScanService.getFaces(inputImage);
      final validation = FaceScanValidator.validate(
        faces,
        image.width,
        image.height,
      );

      if (!mounted) return;

      setState(() {
        _message = validation.message;
      });

      if (validation.success) {
        _consecutiveValidFrames++;
        if (_consecutiveValidFrames >= 30) {
          _captureFace();
        }
      } else {
        _consecutiveValidFrames = 0;
      }
    } catch (e) {
      debugPrint('[FaceScan] Error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final sensorOrientation = _cameraController!.description.sensorOrientation;
    final InputImageRotation? rotation;
    if (Platform.isAndroid) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      rotation = InputImageRotationValue.fromRawValue(0);
    }

    if (rotation == null) return null;

    final InputImageFormat? format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.yuv420) || (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != 1 && Platform.isIOS) return null;
    if (image.planes.length != 3 && Platform.isAndroid) return null;

    final bytes = Platform.isAndroid 
      ? _concatenatePlanes(image.planes)
      : image.planes[0].bytes;

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

  Future<void> _captureFace() async {
    if (_isCapturing) return;
    _isCapturing = true;

    await _cameraController!.stopImageStream();
    
    try {
      final file = await _cameraController!.takePicture();
      final result = await _faceScanService.finalizeCapture(file);
      
      if (!mounted) return;
      
      // Store result and navigate
      // In a real implementation, we would upload to S3 here or pass to signup provider
      debugPrint('[FaceScan] Capture successful. Hash: ${result.hash}');
      
      context.go('/signup', extra: {'faceImagePath': result.file.path, 'faceImageHash': result.hash});
    } catch (e) {
      setState(() {
        _message = 'Capture failed: $e. Try again.';
        _isCapturing = false;
        _consecutiveValidFrames = 0;
        _cameraController!.startImageStream(_processCameraImage);
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceScanService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_cameraController != null && _cameraController!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          
          // Overlay
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Biometric Face Scan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hold still for 30 frames',
                  style: TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                
                // Progress Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(
                    value: _consecutiveValidFrames / 30,
                    backgroundColor: Colors.white24,
                    color: AppColors.primary,
                    minHeight: 8,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  color: Colors.black54,
                  child: Text(
                    _message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          if (_isCapturing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Optimizing image...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
