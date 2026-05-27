import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ScanResult {
  final bool success;
  final String message;

  const ScanResult(this.success, this.message);
}

/// Validates a detected face against all acceptance criteria as per Master Build Prompt Section 11.
/// All checks must pass simultaneously for the frame to be accepted.
class FaceScanValidator {
  FaceScanValidator._();

  static ScanResult validate(List<Face> faces, int imgW, int imgH) {
    if (faces.isEmpty) {
      return const ScanResult(false, 'Show yourself — look directly at the camera');
    }
    if (faces.length > 1) {
      return const ScanResult(false, 'One person at a time — step back');
    }

    final face = faces.first;
    final box = face.boundingBox;
    final faceRatio = box.width / imgW;

    if (faceRatio < 0.25) {
      return const ScanResult(false, 'Move closer to the camera');
    }
    if (faceRatio > 0.85) {
      return const ScanResult(false, 'Move back — we cannot see your full face');
    }
    if (box.left < 0 || box.top < 0 || box.right > imgW || box.bottom > imgH) {
      return const ScanResult(false, 'Move into the frame — keep your face centred');
    }

    final rx = face.headEulerAngleX ?? 0;
    final ry = face.headEulerAngleY ?? 0;
    final rz = face.headEulerAngleZ ?? 0;

    if (rx.abs() > 15) {
      return const ScanResult(false, 'Look straight ahead — do not tilt up or down');
    }
    if (ry.abs() > 20) {
      return const ScanResult(false, 'Face the camera — do not turn to the side');
    }
    if (rz.abs() > 15) {
      return const ScanResult(false, 'Level your head — do not tilt sideways');
    }

    final leftEye = face.leftEyeOpenProbability ?? 0;
    final rightEye = face.rightEyeOpenProbability ?? 0;

    if (leftEye < 0.4 || rightEye < 0.4) {
      // Low probability with face present means eyes closed OR sunglasses
      return const ScanResult(false, 'Open both eyes — remove sunglasses if wearing any');
    }

    // Hat/forehead check via contour presence (if enabled in detector)
    final faceContour = face.contours[FaceContourType.face];
    if (faceContour == null || faceContour.points.length < 10) {
      return const ScanResult(false, 'Your full face must be visible — remove your hat');
    }

    return const ScanResult(true, 'Perfect — hold still');
  }
}
