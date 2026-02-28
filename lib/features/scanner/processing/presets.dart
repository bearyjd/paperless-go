import 'package:image/image.dart' as img;

import 'filters/adaptive_contrast.dart';
import 'filters/binarize.dart';
import 'filters/denoise.dart';
import 'filters/deskew.dart';
import 'filters/shadow_removal.dart';
import 'filters/sharpen.dart';

/// Available enhancement presets for scanned documents.
enum ProcessingPreset {
  none('None', 'No processing applied'),
  auto('Auto', 'Deskew + contrast + sharpen + light denoise'),
  receipt('Receipt', 'Deskew + high contrast + binarize for thermal paper'),
  bwText('B&W Text', 'Deskew + contrast + sharpen + binarize'),
  colorDocument('Color Doc', 'Deskew + contrast + sharpen + denoise, preserves color'),
  photo('Photo', 'Light sharpen + denoise, preserves everything');

  final String label;
  final String description;
  const ProcessingPreset(this.label, this.description);
}

/// Applies the filter pipeline for a given preset.
/// If [skipDeskew] is true, deskew is skipped (already done on main isolate via ML Kit).
img.Image applyPreset(img.Image source, ProcessingPreset preset,
    {bool skipDeskew = false}) {
  switch (preset) {
    case ProcessingPreset.none:
      return source.clone();

    case ProcessingPreset.auto:
      var result = skipDeskew ? source : applyDeskew(source);
      result = applyAdaptiveContrast(result, strength: 0.7);
      result = applySharpen(result, amount: 1.2, radius: 1);
      result = applyDenoise(result, radius: 1);
      return result;

    case ProcessingPreset.receipt:
      var result = skipDeskew ? source : applyDeskew(source);
      result = applyAdaptiveContrast(result, strength: 1.0);
      result = applyShadowRemoval(result, blurRadius: 20);
      result = applyBinarize(result, windowSize: 15, k: 0.3);
      return result;

    case ProcessingPreset.bwText:
      var result = skipDeskew ? source : applyDeskew(source);
      result = applyAdaptiveContrast(result, strength: 0.8);
      result = applySharpen(result, amount: 1.5, radius: 1);
      result = applyBinarize(result, windowSize: 15, k: 0.2);
      return result;

    case ProcessingPreset.colorDocument:
      var result = skipDeskew ? source : applyDeskew(source);
      result = applyAdaptiveContrast(result, strength: 0.6);
      result = applySharpen(result, amount: 1.0, radius: 1);
      result = applyDenoise(result, radius: 1);
      return result;

    case ProcessingPreset.photo:
      var result = applySharpen(source, amount: 0.8, radius: 1);
      result = applyDenoise(result, radius: 1);
      return result;
  }
}
