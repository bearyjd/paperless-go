import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:paperless_go/features/scanner/processing/filters/adaptive_contrast.dart';

void main() {
  group('applyAdaptiveContrast', () {
    test('returns image with same dimensions', () {
      final source = img.Image(width: 100, height: 80);
      // Fill with mid-gray
      for (var y = 0; y < 80; y++) {
        for (var x = 0; x < 100; x++) {
          source.setPixelRgb(x, y, 128, 128, 128);
        }
      }

      final result = applyAdaptiveContrast(source);
      expect(result.width, equals(100));
      expect(result.height, equals(80));
    });

    test('does not crash on tiny image', () {
      final source = img.Image(width: 2, height: 2);
      source.setPixelRgb(0, 0, 0, 0, 0);
      source.setPixelRgb(1, 0, 255, 255, 255);
      source.setPixelRgb(0, 1, 128, 128, 128);
      source.setPixelRgb(1, 1, 64, 64, 64);

      expect(() => applyAdaptiveContrast(source), returnsNormally);
    });

    test('increases contrast range in low-contrast tile', () {
      final source = img.Image(width: 32, height: 32);
      // Fill with narrow range (120-136)
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final val = 120 + (x % 17);
          source.setPixelRgb(x, y, val, val, val);
        }
      }

      final result = applyAdaptiveContrast(source, strength: 1.0);

      // Check that range is expanded
      var minVal = 255;
      var maxVal = 0;
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final p = result.getPixel(x, y);
          final v = p.r.toInt();
          if (v < minVal) minVal = v;
          if (v > maxVal) maxVal = v;
        }
      }
      expect(maxVal - minVal, greaterThan(16));
    });

    test('strength=0 returns near-original image', () {
      final source = img.Image(width: 32, height: 32);
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          source.setPixelRgb(x, y, x * 8, y * 8, 128);
        }
      }

      final result = applyAdaptiveContrast(source, strength: 0.0);
      // Pixels should be unchanged
      final origPixel = source.getPixel(5, 5);
      final resultPixel = result.getPixel(5, 5);
      expect(resultPixel.r.toInt(), equals(origPixel.r.toInt()));
      expect(resultPixel.g.toInt(), equals(origPixel.g.toInt()));
    });
  });
}
