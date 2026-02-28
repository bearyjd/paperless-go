import 'package:image/image.dart' as img;

/// Applies light noise reduction using gaussian blur with small radius.
/// Preserves text edges while smoothing camera noise.
img.Image applyDenoise(img.Image source, {int radius = 1}) {
  return img.gaussianBlur(source, radius: radius);
}
