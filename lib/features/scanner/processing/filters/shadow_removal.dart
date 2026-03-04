import 'package:image/image.dart' as img;

/// Removes shadows using difference-of-gaussians approach.
/// Estimates the background illumination with a large blur, then
/// normalizes the image to remove uneven lighting / finger shadows.
/// Modifies and returns the source image in-place (no clone).
img.Image applyShadowRemoval(img.Image source, {int blurRadius = 25}) {
  if (source.width < 3 || source.height < 3) return source;
  // Large blur to estimate background illumination
  final background = img.gaussianBlur(source.clone(), radius: blurRadius);

  final width = source.width;
  final height = source.height;
  final nc = source.numChannels;
  final srcBytes = source.data!.toUint8List();
  final bgBytes = background.data!.toUint8List();

  for (var y = 0; y < height; y++) {
    final rowOffset = y * width * nc;
    for (var x = 0; x < width; x++) {
      final idx = rowOffset + x * nc;
      final sr = srcBytes[idx];
      final sg = srcBytes[idx + 1];
      final sb = srcBytes[idx + 2];
      final br = bgBytes[idx];
      final bg = bgBytes[idx + 1];
      final bb = bgBytes[idx + 2];

      // Normalize: result = original / background * 255
      // This removes the shadow pattern while preserving text
      srcBytes[idx] = br > 0 ? (sr / br * 255).round().clamp(0, 255) : sr;
      srcBytes[idx + 1] = bg > 0 ? (sg / bg * 255).round().clamp(0, 255) : sg;
      srcBytes[idx + 2] = bb > 0 ? (sb / bb * 255).round().clamp(0, 255) : sb;
    }
  }

  return source;
}
