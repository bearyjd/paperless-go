import 'dart:math';

import 'package:image/image.dart' as img;

/// Applies adaptive binarization (Sauvola-inspired) for converting
/// documents to pure black & white. Works well with uneven lighting.
img.Image applyBinarize(img.Image source, {int windowSize = 15, double k = 0.2}) {
  if (source.width < 3 || source.height < 3) return source;
  final gray = img.grayscale(source.clone());
  final width = gray.width;
  final height = gray.height;
  final result = gray.clone();
  final half = windowSize ~/ 2;

  // Build integral image and integral squared image for fast mean/variance
  final integral = List.generate(height + 1, (_) => List.filled(width + 1, 0.0));
  final integralSq = List.generate(height + 1, (_) => List.filled(width + 1, 0.0));

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final val = gray.getPixel(x, y).r.toDouble();
      integral[y + 1][x + 1] = val + integral[y][x + 1] + integral[y + 1][x] - integral[y][x];
      integralSq[y + 1][x + 1] =
          val * val + integralSq[y][x + 1] + integralSq[y + 1][x] - integralSq[y][x];
    }
  }

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final x0 = max(0, x - half);
      final y0 = max(0, y - half);
      final x1 = min(width, x + half + 1);
      final y1 = min(height, y + half + 1);
      final area = (x1 - x0) * (y1 - y0);

      final sum = integral[y1][x1] - integral[y0][x1] - integral[y1][x0] + integral[y0][x0];
      final sumSq =
          integralSq[y1][x1] - integralSq[y0][x1] - integralSq[y1][x0] + integralSq[y0][x0];

      final mean = sum / area;
      final variance = (sumSq / area) - (mean * mean);
      final stdDev = sqrt(max(0, variance));

      // Sauvola threshold
      final threshold = mean * (1 + k * (stdDev / 128 - 1));

      final pixel = gray.getPixel(x, y).r.toDouble();
      final output = pixel > threshold ? 255 : 0;
      result.setPixelRgb(x, y, output, output, output);
    }
  }

  return result;
}
