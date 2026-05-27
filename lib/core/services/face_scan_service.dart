import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// FaceScanService handles ML Kit initialization and frame processing logic.
class FaceScanService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.25,
    ),
  );

  Future<List<Face>> getFaces(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  void dispose() {
    _faceDetector.close();
  }

  /// Processes the captured frame: compresses, hashes, and prepares for upload.
  /// 1. Compress to 800x800 JPEG quality 85
  /// 2. SHA-256 hash the compressed bytes
  Future<FaceCaptureResult> finalizeCapture(XFile file) async {
    final bytes = await file.readAsBytes();
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/face_capture_final.jpg';

    // Compress to 800x800 quality 85
    final compressedBytes = await FlutterImageCompress.compressWithList(
      bytes,
      minHeight: 800,
      minWidth: 800,
      quality: 85,
      format: CompressFormat.jpeg,
    );

    // SHA-256 hash
    final hash = sha256.convert(compressedBytes).toString();

    // Save to temp file for upload
    final finalFile = File(targetPath);
    await finalFile.writeAsBytes(compressedBytes);

    return FaceCaptureResult(
      file: finalFile,
      hash: hash,
    );
  }
}

class FaceCaptureResult {
  final File file;
  final String hash;

  FaceCaptureResult({required this.file, required this.hash});
}
