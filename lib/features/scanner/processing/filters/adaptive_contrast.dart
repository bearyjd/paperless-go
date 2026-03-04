import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Applies adaptive contrast enhancement with bilinear interpolation
/// between tile regions to avoid visible grid artifacts.
/// Modifies and returns the source image in-place (no clone).
img.Image applyAdaptiveContrast(img.Image source, {double strength = 1.0}) {
  if (source.width < 3 || source.height < 3) return source;
  final width = source.width;
  final height = source.height;
  final nc = source.numChannels;
  final bytes = source.data!.toUint8List();

  // Larger tiles reduce sensitivity to local noise (dust, texture)
  // and prevent grey splotches in near-uniform regions like white paper.
  const tileSize = 128;
  final tilesX = (width / tileSize).ceil();
  final tilesY = (height / tileSize).ceil();

  // Compute min/max luminance for each tile using percentiles
  // instead of absolute min/max to resist outliers (specs of dust, etc.)
  final tileMin = Float64List(tilesX * tilesY);
  final tileMax = Float64List(tilesX * tilesY);
  final tileRange = Float64List(tilesX * tilesY);

  for (var ty = 0; ty < tilesY; ty++) {
    for (var tx = 0; tx < tilesX; tx++) {
      final x0 = tx * tileSize;
      final y0 = ty * tileSize;
      final x1 = min(x0 + tileSize, width);
      final y1 = min(y0 + tileSize, height);

      // Build a histogram for robust percentile estimation
      final hist = Uint32List(256);
      var count = 0;
      for (var y = y0; y < y1; y++) {
        final rowOffset = y * width * nc;
        for (var x = x0; x < x1; x++) {
          final idx = rowOffset + x * nc;
          final lum = (0.299 * bytes[idx] + 0.587 * bytes[idx + 1] + 0.114 * bytes[idx + 2]).round().clamp(0, 255);
          hist[lum]++;
          count++;
        }
      }

      // Use 2nd and 98th percentile to ignore outlier dust/specks
      final p2 = (count * 0.02).round();
      final p98 = (count * 0.98).round();
      var cumulative = 0;
      var minL = 0.0;
      var maxL = 255.0;
      for (var i = 0; i < 256; i++) {
        cumulative += hist[i];
        if (cumulative >= p2 && minL == 0.0 && i > 0) minL = i.toDouble();
        if (cumulative >= p98) {
          maxL = i.toDouble();
          break;
        }
      }

      final idx = ty * tilesX + tx;
      tileMin[idx] = minL;
      tileMax[idx] = maxL;
      tileRange[idx] = maxL - minL;
    }
  }

  // Apply contrast with bilinear interpolation between tile centers.
  final halfTile = tileSize / 2.0;

  for (var y = 0; y < height; y++) {
    final rowOffset = y * width * nc;
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

      final idx = rowOffset + x * nc;
      final r = bytes[idx].toDouble();
      final g = bytes[idx + 1].toDouble();
      final b = bytes[idx + 2].toDouble();

      // Stretch pixel through each of the 4 tile mappings, then blend
      double stretchChannel(double val, int tIdx) {
        final range = tileRange[tIdx];
        // Skip tiles with narrow range — these are uniform regions
        // (white paper, solid backgrounds) where stretching creates artifacts.
        if (range < 40) return val;
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

      bytes[idx] = blendChannel(r).round();
      bytes[idx + 1] = blendChannel(g).round();
      bytes[idx + 2] = blendChannel(b).round();
    }
  }

  return source;
}
