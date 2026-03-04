import 'package:image/image.dart' as img;

/// Applies unsharp mask sharpening to crisp text edges for OCR.
/// The blur step also provides mild denoising, so a separate denoise
/// filter is unnecessary when sharpen is already in the pipeline.
img.Image applySharpen(img.Image source, {double amount = 1.5, int radius = 1}) {
  if (source.width < 3 || source.height < 3) return source;
  // Create blurred version (this is the only allocation we can't avoid)
  final blurred = img.gaussianBlur(source, radius: radius);

  final width = source.width;
  final height = source.height;

  // Apply unsharp mask in-place: result = original + amount * (original - blurred)
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final orig = source.getPixel(x, y);
      final blur = blurred.getPixel(x, y);

      final r = (orig.r + amount * (orig.r - blur.r)).round().clamp(0, 255);
      final g = (orig.g + amount * (orig.g - blur.g)).round().clamp(0, 255);
      final b = (orig.b + amount * (orig.b - blur.b)).round().clamp(0, 255);

      source.setPixelRgb(x, y, r, g, b);
    }
  }

  return source;
}
