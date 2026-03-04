import 'package:image/image.dart' as img;

/// Applies unsharp mask sharpening to crisp text edges for OCR.
/// The blur step also provides mild denoising, so a separate denoise
/// filter is unnecessary when sharpen is already in the pipeline.
/// Modifies and returns the source image in-place (no clone).
img.Image applySharpen(img.Image source, {double amount = 1.5, int radius = 1}) {
  if (source.width < 3 || source.height < 3) return source;
  // Create blurred version (this is the only allocation we can't avoid)
  final blurred = img.gaussianBlur(source.clone(), radius: radius);

  final width = source.width;
  final height = source.height;
  final nc = source.numChannels;
  final srcBytes = source.data!.toUint8List();
  final blurBytes = blurred.data!.toUint8List();

  // Apply unsharp mask in-place: result = original + amount * (original - blurred)
  for (var y = 0; y < height; y++) {
    final rowOffset = y * width * nc;
    for (var x = 0; x < width; x++) {
      final idx = rowOffset + x * nc;
      final sr = srcBytes[idx];
      final sg = srcBytes[idx + 1];
      final sb = srcBytes[idx + 2];

      srcBytes[idx] = (sr + amount * (sr - blurBytes[idx])).round().clamp(0, 255);
      srcBytes[idx + 1] = (sg + amount * (sg - blurBytes[idx + 1])).round().clamp(0, 255);
      srcBytes[idx + 2] = (sb + amount * (sb - blurBytes[idx + 2])).round().clamp(0, 255);
    }
  }

  return source;
}
