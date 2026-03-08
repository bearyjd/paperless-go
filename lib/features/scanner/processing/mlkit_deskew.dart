import 'dart:math' as math;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Use ML Kit to detect the average text line angle.
/// Returns the skew angle in degrees (positive = CW tilt).
/// Must be called from the main isolate (ML Kit uses platform channels).
///
/// This file is REPLACED by mlkit_deskew_stub.dart in F-Droid builds
/// (which strips google_mlkit_text_recognition).
Future<double?> detectAngleWithMlKit(String imagePath) async {
  final inputImage = InputImage.fromFilePath(imagePath);
  final recognizer = TextRecognizer();
  try {
    final result = await recognizer.processImage(inputImage);
    if (result.blocks.isEmpty) return null;

    // Collect angles from text lines with sufficient width
    final angles = <double>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final corners = line.cornerPoints;
        if (corners.length < 2) continue;

        // Corner points: top-left, top-right, bottom-right, bottom-left
        final topLeft = corners[0];
        final topRight = corners[1];

        // Line width in pixels — skip very short lines
        final dx = (topRight.x - topLeft.x).toDouble();
        final dy = (topRight.y - topLeft.y).toDouble();
        final width = math.sqrt(dx * dx + dy * dy);
        if (width < 50) continue;

        // Angle of the top edge of this text line
        final angle = math.atan2(dy, dx) * 180 / math.pi;
        angles.add(angle);
      }
    }

    if (angles.isEmpty) return null;

    // Use median angle (robust to outliers from headers, footers, etc.)
    angles.sort();
    return angles[angles.length ~/ 2];
  } finally {
    recognizer.close();
  }
}
