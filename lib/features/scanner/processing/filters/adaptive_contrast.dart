import 'dart:math';

import 'package:image/image.dart' as img;

/// Applies adaptive contrast enhancement (simplified CLAHE-like approach).
/// Handles uneven lighting across the document by equalizing histogram
/// in local regions.
img.Image applyAdaptiveContrast(img.Image source, {double strength = 1.0}) {
  if (source.width < 3 || source.height < 3) return source;
  final result = source.clone();
  final width = result.width;
  final height = result.height;

  // Convert to grayscale luminance channel for histogram analysis
  // Then apply contrast stretching per-tile

  const tileSize = 64;
  final tilesX = (width / tileSize).ceil();
  final tilesY = (height / tileSize).ceil();

  // For each tile, compute min/max luminance and stretch
  for (var ty = 0; ty < tilesY; ty++) {
    for (var tx = 0; tx < tilesX; tx++) {
      final x0 = tx * tileSize;
      final y0 = ty * tileSize;
      final x1 = min(x0 + tileSize, width);
      final y1 = min(y0 + tileSize, height);

      // Find min/max luminance in tile
      var minL = 255.0;
      var maxL = 0.0;
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final pixel = result.getPixel(x, y);
          final lum = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
          if (lum < minL) minL = lum;
          if (lum > maxL) maxL = lum;
        }
      }

      final range = maxL - minL;
      if (range < 10) continue; // Skip near-uniform tiles

      // Apply contrast stretch with blending
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final pixel = result.getPixel(x, y);
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();

          final stretchedR = ((r - minL) / range * 255).clamp(0, 255);
          final stretchedG = ((g - minL) / range * 255).clamp(0, 255);
          final stretchedB = ((b - minL) / range * 255).clamp(0, 255);

          // Blend original and stretched based on strength
          final newR = (r + (stretchedR - r) * strength).round().clamp(0, 255);
          final newG = (g + (stretchedG - g) * strength).round().clamp(0, 255);
          final newB = (b + (stretchedB - b) * strength).round().clamp(0, 255);

          result.setPixelRgb(x, y, newR, newG, newB);
        }
      }
    }
  }

  return result;
}
