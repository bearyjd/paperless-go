import 'package:image/image.dart' as img;

/// Removes shadows using difference-of-gaussians approach.
/// Estimates the background illumination with a large blur, then
/// normalizes the image to remove uneven lighting / finger shadows.
img.Image applyShadowRemoval(img.Image source, {int blurRadius = 25}) {
  if (source.width < 3 || source.height < 3) return source;
  // Large blur to estimate background illumination
  final background = img.gaussianBlur(source, radius: blurRadius);

  final result = source.clone();
  final width = result.width;
  final height = result.height;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final orig = source.getPixel(x, y);
      final bg = background.getPixel(x, y);

      // Normalize: result = original / background * 255
      // This removes the shadow pattern while preserving text
      final r = bg.r > 0 ? (orig.r / bg.r * 255).round().clamp(0, 255) : orig.r.toInt();
      final g = bg.g > 0 ? (orig.g / bg.g * 255).round().clamp(0, 255) : orig.g.toInt();
      final b = bg.b > 0 ? (orig.b / bg.b * 255).round().clamp(0, 255) : orig.b.toInt();

      result.setPixelRgb(x, y, r, g, b);
    }
  }

  return result;
}
