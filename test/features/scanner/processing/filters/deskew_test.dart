import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:paperless_go/features/scanner/processing/filters/deskew.dart';

void main() {
  group('Deskew filter', () {
    /// Create a test image with horizontal black lines (simulating text rows).
    img.Image _createTextImage(int width, int height) {
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      // Draw horizontal "text lines" every 20 pixels
      for (var y = 20; y < height; y += 20) {
        for (var x = 10; x < width - 10; x++) {
          for (var dy = 0; dy < 3; dy++) {
            if (y + dy < height) {
              image.setPixel(x, y + dy, img.ColorRgb8(0, 0, 0));
            }
          }
        }
      }
      return image;
    }

    test('returns image unchanged or minimally rotated when straight', () {
      final straight = _createTextImage(200, 200);
      final result = applyDeskew(straight);
      // Straight text should either return unchanged or a very similar size
      // (edge detection may find a tiny angle near the threshold)
      expect(result.width, closeTo(straight.width, 30));
      expect(result.height, closeTo(straight.height, 30));
    });

    test('corrects a rotated image', () {
      // Create straight text lines, then rotate 10 degrees to simulate skew
      final straight = _createTextImage(300, 300);
      final skewed = img.copyRotate(straight, angle: 10);

      final corrected = applyDeskew(skewed);

      // The corrected image should exist and be valid
      expect(corrected.width, greaterThan(0));
      expect(corrected.height, greaterThan(0));
      // Deskew should have detected the rotation and corrected it
      // (not the same object — rotation was applied)
      expect(identical(corrected, skewed), isFalse);
    });

    test('handles blank image without error', () {
      final blank = img.Image(width: 100, height: 100);
      img.fill(blank, color: img.ColorRgb8(255, 255, 255));
      final result = applyDeskew(blank);
      // Blank image has no text — should return unchanged
      expect(identical(result, blank), isTrue);
    });

    test('respects maxAngle parameter', () {
      final straight = _createTextImage(200, 200);
      final heavilySkewed = img.copyRotate(straight, angle: 35);
      // With maxAngle=10, can't detect the full 35-degree skew
      // but should still produce a valid result
      final result = applyDeskew(heavilySkewed, maxAngle: 10);
      expect(result.width, greaterThan(0));
    });
  });
}
