import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:paperless_go/features/scanner/processing/filters/deskew.dart';

void main() {
  test('verify deskew corrects in the RIGHT direction', () {
    // Create page with perfectly horizontal text lines
    final page = img.Image(width: 600, height: 800);
    img.fill(page, color: img.ColorRgb8(245, 245, 245));
    for (var lineY = 60; lineY < 750; lineY += 25) {
      for (var x = 50; x < 520; x++) {
        for (var dy = 0; dy < 2; dy++) {
          if (lineY + dy < 800) {
            page.setPixel(x, lineY + dy, img.ColorRgb8(30, 30, 30));
          }
        }
      }
    }

    // Score the original straight page for reference
    final straightScore = _horizontalTextScore(page);

    // Rotate 5 degrees CW (copyRotate positive = CW in image package)
    final tilted = img.copyRotate(page, angle: 5);

    // Apply deskew
    final corrected = applyDeskew(tilted);

    // Score on center-cropped regions to avoid black border artifacts
    // from canvas expansion inflating the tilted image's score
    final tiltedCropped = _centerCrop(tilted);
    final correctedCropped = _centerCrop(corrected);

    final tiltedScore = _horizontalTextScore(tiltedCropped);
    final correctedScore = _horizontalTextScore(correctedCropped);

    print('Straight page score: $straightScore');
    print('Tilted (cropped) score: $tiltedScore');
    print('Corrected (cropped) score: $correctedScore');
    print('Improvement: ${correctedScore > tiltedScore ? "YES" : "NO (WRONG DIRECTION!)"}');

    expect(correctedScore, greaterThan(tiltedScore),
        reason: 'Deskew should make text MORE horizontal, not less');
  });
}

/// Crop to the center 70% to remove black border artifacts from rotation.
img.Image _centerCrop(img.Image image) {
  final cropW = (image.width * 0.7).round();
  final cropH = (image.height * 0.7).round();
  final x = ((image.width - cropW) / 2).round();
  final y = ((image.height - cropH) / 2).round();
  return img.copyCrop(image, x: x, y: y, width: cropW, height: cropH);
}

/// Score how "horizontal" the text lines are.
/// Compute projection profile variance at 0 degrees (horizontal scan).
/// Higher = text lines align better with horizontal.
double _horizontalTextScore(img.Image image) {
  final w = image.width;
  final h = image.height;

  // Sum luminance per row
  final rowSums = Float64List(h);
  for (var y = 0; y < h; y++) {
    var sum = 0.0;
    for (var x = 0; x < w; x += 2) {
      // Use inverted luminance (dark pixels = high value)
      sum += (1.0 - image.getPixel(x, y).luminanceNormalized);
    }
    rowSums[y] = sum;
  }

  // Compute variance
  var total = 0.0;
  for (final s in rowSums) {
    total += s;
  }
  final mean = total / h;
  var variance = 0.0;
  for (final s in rowSums) {
    final diff = s - mean;
    variance += diff * diff;
  }
  return variance / h;
}
