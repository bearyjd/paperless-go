import 'package:image/image.dart' as img;

/// Applies unsharp mask sharpening to crisp text edges for OCR.
img.Image applySharpen(img.Image source, {double amount = 1.5, int radius = 1}) {
  // Create blurred version
  final blurred = img.gaussianBlur(source, radius: radius);

  final result = source.clone();
  final width = result.width;
  final height = result.height;

  // Unsharp mask: result = original + amount * (original - blurred)
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final orig = source.getPixel(x, y);
      final blur = blurred.getPixel(x, y);

      final r = (orig.r + amount * (orig.r - blur.r)).round().clamp(0, 255);
      final g = (orig.g + amount * (orig.g - blur.g)).round().clamp(0, 255);
      final b = (orig.b + amount * (orig.b - blur.b)).round().clamp(0, 255);

      result.setPixelRgb(x, y, r, g, b);
    }
  }

  return result;
}
