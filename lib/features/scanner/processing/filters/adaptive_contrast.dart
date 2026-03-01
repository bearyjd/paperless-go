import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Applies adaptive contrast enhancement with bilinear interpolation
/// between tile regions to avoid visible grid artifacts.
img.Image applyAdaptiveContrast(img.Image source, {double strength = 1.0}) {
  if (source.width < 3 || source.height < 3) return source;
  final result = source.clone();
  final width = result.width;
  final height = result.height;

  const tileSize = 64;
  final tilesX = (width / tileSize).ceil();
  final tilesY = (height / tileSize).ceil();

  // Compute min/max luminance for each tile
  final tileMin = Float64List(tilesX * tilesY);
  final tileMax = Float64List(tilesX * tilesY);
  final tileRange = Float64List(tilesX * tilesY);

  for (var ty = 0; ty < tilesY; ty++) {
    for (var tx = 0; tx < tilesX; tx++) {
      final x0 = tx * tileSize;
      final y0 = ty * tileSize;
      final x1 = min(x0 + tileSize, width);
      final y1 = min(y0 + tileSize, height);

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

      final idx = ty * tilesX + tx;
      tileMin[idx] = minL;
      tileMax[idx] = maxL;
      tileRange[idx] = maxL - minL;
    }
  }

  // Apply contrast with bilinear interpolation between tile centers.
  // Each pixel blends the mapping from its 4 nearest tile centers,
  // eliminating hard boundaries between tiles.
  final halfTile = tileSize / 2.0;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      // Position relative to tile grid centers
      final gx = (x - halfTile) / tileSize;
      final gy = (y - halfTile) / tileSize;

      // Four nearest tile indices
      final tx0 = gx.floor().clamp(0, tilesX - 1);
      final ty0 = gy.floor().clamp(0, tilesY - 1);
      final tx1 = (tx0 + 1).clamp(0, tilesX - 1);
      final ty1 = (ty0 + 1).clamp(0, tilesY - 1);

      // Interpolation weights
      final fx = (gx - tx0).clamp(0.0, 1.0);
      final fy = (gy - ty0).clamp(0.0, 1.0);

      final pixel = result.getPixel(x, y);
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();

      // Stretch pixel through each of the 4 tile mappings, then blend
      double stretchChannel(double val, int tIdx) {
        final range = tileRange[tIdx];
        if (range < 10) return val; // Near-uniform tile, no stretch
        return ((val - tileMin[tIdx]) / range * 255).clamp(0, 255);
      }

      double blendChannel(double val) {
        final s00 = stretchChannel(val, ty0 * tilesX + tx0);
        final s10 = stretchChannel(val, ty0 * tilesX + tx1);
        final s01 = stretchChannel(val, ty1 * tilesX + tx0);
        final s11 = stretchChannel(val, ty1 * tilesX + tx1);

        // Bilinear interpolation
        final top = s00 + (s10 - s00) * fx;
        final bot = s01 + (s11 - s01) * fx;
        final stretched = top + (bot - top) * fy;

        // Blend with original based on strength
        return (val + (stretched - val) * strength).clamp(0, 255);
      }

      result.setPixelRgb(
        x, y,
        blendChannel(r).round(),
        blendChannel(g).round(),
        blendChannel(b).round(),
      );
    }
  }

  return result;
}
