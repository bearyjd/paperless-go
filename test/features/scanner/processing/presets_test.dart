import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:paperless_go/features/scanner/processing/presets.dart';

void main() {
  late img.Image testImage;

  setUp(() {
    // Create a 50x50 test image with varied content
    testImage = img.Image(width: 50, height: 50);
    for (var y = 0; y < 50; y++) {
      for (var x = 0; x < 50; x++) {
        testImage.setPixelRgb(
          x,
          y,
          (x * 5).clamp(0, 255),
          (y * 5).clamp(0, 255),
          128,
        );
      }
    }
  });

  group('applyPreset', () {
    test('none preset returns copy of original', () {
      final result = applyPreset(testImage, ProcessingPreset.none);
      expect(result.width, equals(testImage.width));
      expect(result.height, equals(testImage.height));
      // Should be equal to original
      final origPixel = testImage.getPixel(25, 25);
      final resultPixel = result.getPixel(25, 25);
      expect(resultPixel.r.toInt(), equals(origPixel.r.toInt()));
    });

    for (final preset in ProcessingPreset.values) {
      test('${preset.name} preset produces valid output', () {
        final result = applyPreset(testImage, preset);
        // Deskew may expand canvas, so output >= input
        expect(result.width, greaterThanOrEqualTo(50));
        expect(result.height, greaterThanOrEqualTo(50));

        // Verify all pixel values are in valid range
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            final p = result.getPixel(x, y);
            expect(p.r.toInt(), inInclusiveRange(0, 255));
            expect(p.g.toInt(), inInclusiveRange(0, 255));
            expect(p.b.toInt(), inInclusiveRange(0, 255));
          }
        }
      });
    }

    test('auto preset modifies the image', () {
      final result = applyPreset(testImage, ProcessingPreset.auto);
      // At least some pixels should differ from original
      var diffCount = 0;
      for (var y = 0; y < 50; y++) {
        for (var x = 0; x < 50; x++) {
          final orig = testImage.getPixel(x, y);
          final res = result.getPixel(x, y);
          if (orig.r.toInt() != res.r.toInt()) diffCount++;
        }
      }
      expect(diffCount, greaterThan(0));
    });

    test('bwText preset produces grayscale-like output', () {
      final result = applyPreset(testImage, ProcessingPreset.bwText);
      // Binarize should make all pixels either 0 or 255
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final p = result.getPixel(x, y);
          final r = p.r.toInt();
          expect(r == 0 || r == 255, isTrue);
        }
      }
    });
  });

  group('ProcessingPreset', () {
    test('all presets have labels and descriptions', () {
      for (final preset in ProcessingPreset.values) {
        expect(preset.label, isNotEmpty);
        expect(preset.description, isNotEmpty);
      }
    });
  });
}
