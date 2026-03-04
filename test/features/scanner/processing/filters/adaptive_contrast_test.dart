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

    test('increases contrast range in moderate-contrast tile', () {
      final source = img.Image(width: 32, height: 32);
      // Fill with range of 60 (100-160) — above the skip threshold of 40
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final val = 100 + (x * 60 ~/ 31);
          source.setPixelRgb(x, y, val, val, val);
        }
      }

      // Save original values before in-place modification
      final origValues = <int>[];
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          origValues.add(source.getPixel(x, y).r.toInt());
        }
      }

      final result = applyAdaptiveContrast(source, strength: 1.0);

      // Check that range is expanded beyond the original 60
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
      expect(maxVal - minVal, greaterThan(60));
    });

    test('preserves near-uniform regions (no grey splotches)', () {
      final source = img.Image(width: 32, height: 32);
      // Fill with very narrow range (250-255) simulating white paper
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final val = 250 + (x % 6);
          source.setPixelRgb(x, y, val, val, val);
        }
      }

      final result = applyAdaptiveContrast(source, strength: 1.0);

      // Near-uniform tiles (range < 40) should be untouched
      var minVal = 255;
      var maxVal = 0;
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final v = result.getPixel(x, y).r.toInt();
          if (v < minVal) minVal = v;
          if (v > maxVal) maxVal = v;
        }
      }
      // Range should NOT be expanded — still approximately 5
      expect(maxVal - minVal, lessThan(20));
    });

    test('strength=0 returns near-original image', () {
      final source = img.Image(width: 32, height: 32);
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          source.setPixelRgb(x, y, x * 8, y * 8, 128);
        }
      }

      // Save original values before in-place modification
      final origR = source.getPixel(5, 5).r.toInt();
      final origG = source.getPixel(5, 5).g.toInt();

      final result = applyAdaptiveContrast(source, strength: 0.0);
      // Pixels should be unchanged
      final resultPixel = result.getPixel(5, 5);
      expect(resultPixel.r.toInt(), equals(origR));
      expect(resultPixel.g.toInt(), equals(origG));
    });
  });
}
