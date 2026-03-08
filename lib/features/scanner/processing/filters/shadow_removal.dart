import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Removes shadows using difference-of-background approach.
/// Estimates the background illumination with a fast 3-pass box blur
/// (approximating Gaussian), then normalizes the image to remove
/// uneven lighting / finger shadows.
/// Modifies and returns the source image in-place (no clone).
img.Image applyShadowRemoval(img.Image source, {int blurRadius = 25}) {
  if (source.width < 3 || source.height < 3) return source;

  final width = source.width;
  final height = source.height;
  final nc = source.numChannels;
  final srcBytes = source.data!.toUint8List();

  // Build background estimate using 3-pass separable box blur.
  // 3 passes of box blur closely approximates a Gaussian blur but runs
  // in O(w*h*3) instead of O(w*h*r^2) — dramatically faster at large radii.
  final bgR = Float32List(width * height);
  final bgG = Float32List(width * height);
  final bgB = Float32List(width * height);

  // Seed from source pixels
  for (var y = 0; y < height; y++) {
    final row = y * width;
    final rowOffset = y * width * nc;
    for (var x = 0; x < width; x++) {
      final idx = rowOffset + x * nc;
      final i = row + x;
      bgR[i] = srcBytes[idx].toDouble();
      bgG[i] = srcBytes[idx + 1].toDouble();
      bgB[i] = srcBytes[idx + 2].toDouble();
    }
  }

  // Temp buffers for the blur pass
  final tmpR = Float32List(width * height);
  final tmpG = Float32List(width * height);
  final tmpB = Float32List(width * height);

  // Run 3 passes of separable box blur
  for (var pass = 0; pass < 3; pass++) {
    // Horizontal pass: bg → tmp
    _boxBlurH(bgR, tmpR, width, height, blurRadius);
    _boxBlurH(bgG, tmpG, width, height, blurRadius);
    _boxBlurH(bgB, tmpB, width, height, blurRadius);

    // Vertical pass: tmp → bg
    _boxBlurV(tmpR, bgR, width, height, blurRadius);
    _boxBlurV(tmpG, bgG, width, height, blurRadius);
    _boxBlurV(tmpB, bgB, width, height, blurRadius);
  }

  // Normalize: result = original / background * 255
  for (var y = 0; y < height; y++) {
    final row = y * width;
    final rowOffset = y * width * nc;
    for (var x = 0; x < width; x++) {
      final idx = rowOffset + x * nc;
      final i = row + x;
      final br = bgR[i];
      final bg = bgG[i];
      final bb = bgB[i];

      srcBytes[idx] = br > 1
          ? (srcBytes[idx] / br * 255).round().clamp(0, 255)
          : srcBytes[idx];
      srcBytes[idx + 1] = bg > 1
          ? (srcBytes[idx + 1] / bg * 255).round().clamp(0, 255)
          : srcBytes[idx + 1];
      srcBytes[idx + 2] = bb > 1
          ? (srcBytes[idx + 2] / bb * 255).round().clamp(0, 255)
          : srcBytes[idx + 2];
    }
  }

  return source;
}

/// Horizontal box blur pass using a sliding window accumulator.
/// Reads from [src], writes to [dst]. O(width * height) regardless of radius.
void _boxBlurH(Float32List src, Float32List dst, int w, int h, int r) {
  final diameter = 2 * r + 1;
  final invDiam = 1.0 / diameter;

  for (var y = 0; y < h; y++) {
    final row = y * w;

    // Initialize accumulator: left edge pixel repeated for out-of-bounds
    var acc = src[row] * (r + 1);
    for (var i = 0; i < r; i++) {
      acc += src[row + (i < w ? i : w - 1)];
    }

    for (var x = 0; x < w; x++) {
      // Add the pixel entering the window on the right
      final right = x + r;
      acc += right < w ? src[row + right] : src[row + w - 1];

      dst[row + x] = acc * invDiam;

      // Remove the pixel leaving the window on the left
      final left = x - r;
      acc -= left >= 0 ? src[row + left] : src[row];
    }
  }
}

/// Vertical box blur pass using a sliding window accumulator.
/// Reads from [src], writes to [dst]. O(width * height) regardless of radius.
void _boxBlurV(Float32List src, Float32List dst, int w, int h, int r) {
  final diameter = 2 * r + 1;
  final invDiam = 1.0 / diameter;

  for (var x = 0; x < w; x++) {
    // Initialize accumulator: top edge pixel repeated for out-of-bounds
    var acc = src[x] * (r + 1);
    for (var i = 0; i < r; i++) {
      acc += src[(i < h ? i : h - 1) * w + x];
    }

    for (var y = 0; y < h; y++) {
      final bottom = y + r;
      acc += bottom < h ? src[bottom * w + x] : src[(h - 1) * w + x];

      dst[y * w + x] = acc * invDiam;

      final top = y - r;
      acc -= top >= 0 ? src[top * w + x] : src[x];
    }
  }
}
