import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Applies adaptive binarization (Sauvola-inspired) for converting
/// documents to pure black & white. Works well with uneven lighting.
/// Writes binarized result in-place to avoid extra allocations.
img.Image applyBinarize(img.Image source, {int windowSize = 15, double k = 0.2}) {
  if (source.width < 3 || source.height < 3) return source;
  final gray = img.grayscale(source);
  final width = gray.width;
  final height = gray.height;
  final nc = gray.numChannels;
  final bytes = gray.data!.toUint8List();
  final half = windowSize ~/ 2;

  // Build integral image and integral squared image for fast mean/variance
  // Flat Float64List indexed as [y * stride + x] where stride = width + 1
  final stride = width + 1;
  final integral = Float64List(stride * (height + 1));
  final integralSq = Float64List(stride * (height + 1));

  for (var y = 0; y < height; y++) {
    final rowOffset = y * width * nc;
    final iRow1 = (y + 1) * stride;
    final iRow0 = y * stride;
    for (var x = 0; x < width; x++) {
      final val = bytes[rowOffset + x * nc].toDouble();
      final ix1 = iRow1 + x + 1;
      final ix0 = iRow1 + x;
      final iy0 = iRow0 + x + 1;
      final iy00 = iRow0 + x;
      integral[ix1] = val + integral[iy0] + integral[ix0] - integral[iy00];
      integralSq[ix1] = val * val + integralSq[iy0] + integralSq[ix0] - integralSq[iy00];
    }
  }

  for (var y = 0; y < height; y++) {
    final rowOffset = y * width * nc;
    for (var x = 0; x < width; x++) {
      final x0 = max(0, x - half);
      final y0 = max(0, y - half);
      final x1 = min(width, x + half + 1);
      final y1 = min(height, y + half + 1);
      final area = (x1 - x0) * (y1 - y0);

      final iy1 = y1 * stride;
      final iy0 = y0 * stride;
      final sum = integral[iy1 + x1] - integral[iy0 + x1] - integral[iy1 + x0] + integral[iy0 + x0];
      final sumSq = integralSq[iy1 + x1] - integralSq[iy0 + x1] - integralSq[iy1 + x0] + integralSq[iy0 + x0];

      final mean = sum / area;
      final variance = (sumSq / area) - (mean * mean);
      final stdDev = sqrt(max(0, variance));

      // Sauvola threshold
      final threshold = mean * (1 + k * (stdDev / 128 - 1));

      final idx = rowOffset + x * nc;
      final pixel = bytes[idx].toDouble();
      final output = pixel > threshold ? 255 : 0;
      bytes[idx] = output;
      if (nc > 1) bytes[idx + 1] = output;
      if (nc > 2) bytes[idx + 2] = output;
    }
  }

  return gray;
}
