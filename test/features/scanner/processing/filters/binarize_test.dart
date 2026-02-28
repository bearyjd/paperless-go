import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:paperless_go/features/scanner/processing/filters/binarize.dart';

void main() {
  group('applyBinarize', () {
    test('returns image with same dimensions', () {
      final source = img.Image(width: 30, height: 30);
      final result = applyBinarize(source);
      expect(result.width, equals(30));
      expect(result.height, equals(30));
    });

    test('output contains only black and white pixels', () {
      final source = img.Image(width: 30, height: 30);
      // Fill with gradient
      for (var y = 0; y < 30; y++) {
        for (var x = 0; x < 30; x++) {
          final val = ((x + y) * 4).clamp(0, 255);
          source.setPixelRgb(x, y, val, val, val);
        }
      }

      final result = applyBinarize(source);

      for (var y = 0; y < 30; y++) {
        for (var x = 0; x < 30; x++) {
          final pixel = result.getPixel(x, y);
          final r = pixel.r.toInt();
          expect(r == 0 || r == 255, isTrue,
              reason: 'Pixel ($x,$y) has value $r, expected 0 or 255');
        }
      }
    });

    test('white image stays white', () {
      final source = img.Image(width: 20, height: 20);
      for (var y = 0; y < 20; y++) {
        for (var x = 0; x < 20; x++) {
          source.setPixelRgb(x, y, 255, 255, 255);
        }
      }

      final result = applyBinarize(source);
      final pixel = result.getPixel(10, 10);
      expect(pixel.r.toInt(), equals(255));
    });
  });
}
