import 'dart:math' as math;
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// Detect and correct skew angle in document images.
/// Primary: uses ML Kit text recognition to detect text line angles.
/// Fallback: edge-weighted projection profiles.
///
/// Note: ML Kit requires the main isolate (uses platform channels),
/// so this must be called from the main isolate, not from compute().
Future<img.Image> applyDeskewAsync(img.Image source, String imagePath) async {
  try {
    final angle = await _detectAngleWithMlKit(imagePath);
    if (angle != null && angle.abs() > 0.3 && angle.abs() < 30) {
      final rotated = img.copyRotate(source,
          angle: -angle, interpolation: img.Interpolation.linear);
      return _cropRotationBorders(rotated, source.width, source.height, angle);
    }
  } catch (_) {
    // ML Kit not available, fall through to edge-based method
  }
  return applyDeskew(source);
}

/// After rotation, the canvas expands and has black fill in the corners.
/// Crop back to original dimensions, then fill the black corner triangles
/// with white so no artifacts remain.
img.Image _cropRotationBorders(
    img.Image rotated, int origW, int origH, double angleDeg) {
  final cropW = math.min(origW, rotated.width);
  final cropH = math.min(origH, rotated.height);

  if (cropW <= 0 || cropH <= 0) return rotated;

  final x = ((rotated.width - cropW) / 2).round();
  final y = ((rotated.height - cropH) / 2).round();

  final cropped = img.copyCrop(rotated, x: x, y: y, width: cropW, height: cropH);

  // Fill black corner triangles with white.
  // The rotation leaves black (0,0,0) fill pixels in the corners.
  // Flood-fill from each corner, replacing near-black pixels with white.
  final white = img.ColorRgb8(255, 255, 255);
  _fillCorner(cropped, 0, 0, 1, 1, white);
  _fillCorner(cropped, cropW - 1, 0, -1, 1, white);
  _fillCorner(cropped, 0, cropH - 1, 1, -1, white);
  _fillCorner(cropped, cropW - 1, cropH - 1, -1, -1, white);

  return cropped;
}

/// Scan from a corner, replacing near-black pixels with [fill].
/// Scans row by row from the corner, stopping when no black pixels found.
void _fillCorner(
    img.Image image, int startX, int startY, int dx, int dy, img.Color fill) {
  final w = image.width;
  final h = image.height;

  for (var row = 0; row < h; row++) {
    final y = startY + row * dy;
    if (y < 0 || y >= h) break;
    var foundBlack = false;
    for (var col = 0; col < w; col++) {
      final x = startX + col * dx;
      if (x < 0 || x >= w) break;
      final p = image.getPixel(x, y);
      if (p.rNormalized < 0.05 && p.gNormalized < 0.05 && p.bNormalized < 0.05) {
        image.setPixel(x, y, fill);
        foundBlack = true;
      } else {
        break; // Stop at first non-black pixel in this row
      }
    }
    if (!foundBlack) break; // No more black in this row direction — done
  }
}

/// Use ML Kit to detect the average text line angle.
/// Returns the skew angle in degrees (positive = CW tilt).
Future<double?> _detectAngleWithMlKit(String imagePath) async {
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

/// Pure Dart fallback: edge-weighted projection profiles.
img.Image applyDeskew(img.Image source, {double maxAngle = 15.0}) {
  if (source.width < 3 || source.height < 3) return source;
  final maxDim = math.max(source.width, source.height);
  final scale = math.min(1.0, 1200.0 / maxDim);
  final small = scale < 1.0
      ? img.copyResize(source,
          width: (source.width * scale).round(),
          interpolation: img.Interpolation.average)
      : source;

  final w = small.width;
  final h = small.height;

  final lum = Float32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      lum[y * w + x] = small.getPixel(x, y).luminanceNormalized * 255;
    }
  }

  // Vertical Sobel gradient (Gy) — detects horizontal text edges
  final gyMag = Float32List(w * h);
  var maxGy = 0.0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final gy = -lum[(y - 1) * w + (x - 1)] +
          -2 * lum[(y - 1) * w + x] +
          -lum[(y - 1) * w + (x + 1)] +
          lum[(y + 1) * w + (x - 1)] +
          2 * lum[(y + 1) * w + x] +
          lum[(y + 1) * w + (x + 1)];
      final absGy = gy.abs();
      gyMag[y * w + x] = absGy;
      if (absGy > maxGy) maxGy = absGy;
    }
  }

  if (maxGy < 30) return source;

  final edgeThreshold = maxGy * 0.10;
  final mx = (w * 0.10).round();
  final my = (h * 0.10).round();
  final cw = w - mx * 2;
  final ch = h - my * 2;

  final edges = Float32List(cw * ch);
  var edgeCount = 0;
  for (var y = 0; y < ch; y++) {
    for (var x = 0; x < cw; x++) {
      final mag = gyMag[(y + my) * w + (x + mx)];
      if (mag >= edgeThreshold) {
        edges[y * cw + x] = mag;
        edgeCount++;
      }
    }
  }

  if (edgeCount < cw * ch * 0.005) return source;

  final coarseAngle =
      _findBestAngle(edges, cw, ch, -maxAngle, maxAngle, 0.5);
  final fineAngle = _findBestAngle(
    edges, cw, ch,
    coarseAngle - 0.75,
    coarseAngle + 0.75,
    0.05,
  );

  if (fineAngle.abs() < 0.3) return source;

  final rotated = img.copyRotate(source,
      angle: fineAngle, interpolation: img.Interpolation.linear);
  return _cropRotationBorders(rotated, source.width, source.height, fineAngle);
}

double _findBestAngle(
  Float32List edges, int w, int h,
  double minAngle, double maxAngle, double step,
) {
  double bestAngle = 0;
  double bestVariance = -1;
  for (var angle = minAngle; angle <= maxAngle; angle += step) {
    final variance = _edgeProjectionVariance(edges, w, h, angle);
    if (variance > bestVariance) {
      bestVariance = variance;
      bestAngle = angle;
    }
  }
  return bestAngle;
}

double _edgeProjectionVariance(
    Float32List edges, int w, int h, double angleDeg) {
  final rad = angleDeg * math.pi / 180.0;
  final sinA = math.sin(rad);
  final cosA = math.cos(rad);
  final cx = w / 2.0;
  final cy = h / 2.0;
  final sums = Float32List(h);
  for (var y = 0; y < h; y++) {
    var sum = 0.0;
    for (var x = 0; x < w; x += 2) {
      final dx = x - cx;
      final dy = y - cy;
      final sx = (cosA * dx + sinA * dy + cx).round();
      final sy = (-sinA * dx + cosA * dy + cy).round();
      if (sx >= 0 && sx < w && sy >= 0 && sy < h) {
        sum += edges[sy * w + sx];
      }
    }
    sums[y] = sum;
  }
  final n = h;
  var total = 0.0;
  for (var i = 0; i < n; i++) {
    total += sums[i];
  }
  final mean = total / n;
  var variance = 0.0;
  for (var i = 0; i < n; i++) {
    final diff = sums[i] - mean;
    variance += diff * diff;
  }
  return variance / n;
}
