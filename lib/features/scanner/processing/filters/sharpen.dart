import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Applies unsharp mask sharpening to crisp text edges for OCR.
/// The blur step also provides mild denoising, so a separate denoise
/// filter is unnecessary when sharpen is already in the pipeline.
///
/// For radius=1 (all presets), uses a hand-rolled 3×3 mean blur that avoids
/// cloning the entire image. Falls back to img.gaussianBlur for radius > 1.
/// Modifies and returns the source image in-place (no clone for radius=1).
img.Image applySharpen(
  img.Image source, {
  double amount = 1.5,
  int radius = 1,
}) {
  if (source.width < 3 || source.height < 3) return source;

  // For radius > 1, fall back to the generic path (rare — all presets use radius=1)
  if (radius > 1) {
    return _sharpenGeneric(source, amount, radius);
  }

  final width = source.width;
  final height = source.height;
  final nc = source.numChannels;
  final bytes = source.data!.toUint8List();

  // Snapshot source pixels into flat channel arrays so we can read originals
  // while writing sharpened values back into `bytes` in-place.
  final srcR = Float32List(width * height);
  final srcG = Float32List(width * height);
  final srcB = Float32List(width * height);

  for (var y = 0; y < height; y++) {
    final rowOff = y * width * nc;
    final yi = y * width;
    for (var x = 0; x < width; x++) {
      final idx = rowOff + x * nc;
      final i = yi + x;
      srcR[i] = bytes[idx].toDouble();
      srcG[i] = bytes[idx + 1].toDouble();
      srcB[i] = bytes[idx + 2].toDouble();
    }
  }

  // Unsharp mask: result = original + amount * (original - blur3x3)
  const inv9 = 1.0 / 9.0;

  for (var y = 0; y < height; y++) {
    final rowOff = y * width * nc;
    final y0 = (y > 0 ? y - 1 : 0) * width;
    final y1 = y * width;
    final y2 = (y < height - 1 ? y + 1 : height - 1) * width;

    for (var x = 0; x < width; x++) {
      final x0 = x > 0 ? x - 1 : 0;
      final x2 = x < width - 1 ? x + 1 : width - 1;

      // 3×3 mean for each channel
      final blurR =
          (srcR[y0 + x0] +
              srcR[y0 + x] +
              srcR[y0 + x2] +
              srcR[y1 + x0] +
              srcR[y1 + x] +
              srcR[y1 + x2] +
              srcR[y2 + x0] +
              srcR[y2 + x] +
              srcR[y2 + x2]) *
          inv9;
      final blurG =
          (srcG[y0 + x0] +
              srcG[y0 + x] +
              srcG[y0 + x2] +
              srcG[y1 + x0] +
              srcG[y1 + x] +
              srcG[y1 + x2] +
              srcG[y2 + x0] +
              srcG[y2 + x] +
              srcG[y2 + x2]) *
          inv9;
      final blurB =
          (srcB[y0 + x0] +
              srcB[y0 + x] +
              srcB[y0 + x2] +
              srcB[y1 + x0] +
              srcB[y1 + x] +
              srcB[y1 + x2] +
              srcB[y2 + x0] +
              srcB[y2 + x] +
              srcB[y2 + x2]) *
          inv9;

      final idx = rowOff + x * nc;
      final oR = srcR[y1 + x];
      final oG = srcG[y1 + x];
      final oB = srcB[y1 + x];

      bytes[idx] = (oR + amount * (oR - blurR)).round().clamp(0, 255);
      bytes[idx + 1] = (oG + amount * (oG - blurG)).round().clamp(0, 255);
      bytes[idx + 2] = (oB + amount * (oB - blurB)).round().clamp(0, 255);
    }
  }

  return source;
}

/// Fallback for radius > 1: uses img.gaussianBlur (slower but handles arbitrary radii).
img.Image _sharpenGeneric(img.Image source, double amount, int radius) {
  final blurred = img.gaussianBlur(source.clone(), radius: radius);

  final width = source.width;
  final height = source.height;
  final nc = source.numChannels;
  final srcBytes = source.data!.toUint8List();
  final blurBytes = blurred.data!.toUint8List();

  for (var y = 0; y < height; y++) {
    final rowOffset = y * width * nc;
    for (var x = 0; x < width; x++) {
      final idx = rowOffset + x * nc;
      final sr = srcBytes[idx];
      final sg = srcBytes[idx + 1];
      final sb = srcBytes[idx + 2];

      srcBytes[idx] = (sr + amount * (sr - blurBytes[idx])).round().clamp(
        0,
        255,
      );
      srcBytes[idx + 1] = (sg + amount * (sg - blurBytes[idx + 1]))
          .round()
          .clamp(0, 255);
      srcBytes[idx + 2] = (sb + amount * (sb - blurBytes[idx + 2]))
          .round()
          .clamp(0, 255);
    }
  }

  return source;
}
