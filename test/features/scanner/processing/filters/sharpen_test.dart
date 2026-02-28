import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:paperless_go/features/scanner/processing/filters/sharpen.dart';

void main() {
  group('applySharpen', () {
    test('returns image with same dimensions', () {
      final source = img.Image(width: 50, height: 40);
      final result = applySharpen(source);
      expect(result.width, equals(50));
      expect(result.height, equals(40));
    });

    test('does not crash on single-pixel image', () {
      final source = img.Image(width: 1, height: 1);
      source.setPixelRgb(0, 0, 128, 128, 128);
      expect(() => applySharpen(source), returnsNormally);
    });

    test('preserves or enhances contrast at edges', () {
      final source = img.Image(width: 20, height: 20);
      // Left half dark gray, right half light gray (soft edge in middle)
      for (var y = 0; y < 20; y++) {
        for (var x = 0; x < 20; x++) {
          final val = x < 10 ? 80 : 180;
          source.setPixelRgb(x, y, val, val, val);
        }
      }

      final result = applySharpen(source, amount: 2.0);
      // After sharpening, the contrast between left and right should
      // be at least as strong as the original
      final leftVal = result.getPixel(5, 10).r.toInt();
      final rightVal = result.getPixel(15, 10).r.toInt();
      expect(rightVal - leftVal, greaterThanOrEqualTo(100));
    });
  });
}
