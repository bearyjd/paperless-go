import 'package:image/image.dart' as img;

import 'filters/adaptive_contrast.dart';
import 'filters/binarize.dart';
import 'filters/deskew.dart';
import 'filters/shadow_removal.dart';
import 'filters/sharpen.dart';

/// Available enhancement presets for scanned documents.
enum ProcessingPreset {
  none('None', 'No processing applied'),
  auto('Auto', 'Deskew + contrast + sharpen'),
  receipt('Receipt', 'Deskew + high contrast + binarize for thermal paper'),
  bwText('B&W Text', 'Deskew + contrast + sharpen + binarize'),
  colorDocument('Color Doc', 'Deskew + contrast + sharpen, preserves color'),
  photo('Photo', 'Light sharpen, preserves everything');

  final String label;
  final String description;
  const ProcessingPreset(this.label, this.description);
}

/// Applies the filter pipeline for a given preset.
/// If [skipDeskew] is true, deskew is skipped (already done by caller).
/// If [onProgress] is provided, it's called before each filter step with
/// a label and progress fraction (0.0–1.0). Used by the isolate progress stream.
img.Image applyPreset(
  img.Image source,
  ProcessingPreset preset, {
  bool skipDeskew = false,
  void Function(String label, double percent)? onProgress,
}) {
  switch (preset) {
    case ProcessingPreset.none:
      return source;

    case ProcessingPreset.auto:
      var result = skipDeskew ? source : applyDeskew(source);
      onProgress?.call('Adjusting contrast', 0.40);
      result = applyAdaptiveContrast(result, strength: 0.7);
      onProgress?.call('Sharpening', 0.65);
      result = applySharpen(result, amount: 1.2, radius: 1);
      return result;

    case ProcessingPreset.receipt:
      var result = skipDeskew ? source : applyDeskew(source);
      onProgress?.call('Adjusting contrast', 0.40);
      result = applyAdaptiveContrast(result, strength: 1.0);
      onProgress?.call('Removing shadows', 0.55);
      result = applyShadowRemoval(result, blurRadius: 20);
      onProgress?.call('Binarizing', 0.70);
      result = applyBinarize(result, windowSize: 15, k: 0.3);
      return result;

    case ProcessingPreset.bwText:
      var result = skipDeskew ? source : applyDeskew(source);
      onProgress?.call('Adjusting contrast', 0.40);
      result = applyAdaptiveContrast(result, strength: 0.8);
      onProgress?.call('Sharpening', 0.55);
      result = applySharpen(result, amount: 1.5, radius: 1);
      onProgress?.call('Binarizing', 0.70);
      result = applyBinarize(result, windowSize: 15, k: 0.2);
      return result;

    case ProcessingPreset.colorDocument:
      var result = skipDeskew ? source : applyDeskew(source);
      onProgress?.call('Adjusting contrast', 0.40);
      result = applyAdaptiveContrast(result, strength: 0.6);
      onProgress?.call('Sharpening', 0.65);
      result = applySharpen(result, amount: 1.0, radius: 1);
      return result;

    case ProcessingPreset.photo:
      onProgress?.call('Sharpening', 0.40);
      return applySharpen(source, amount: 0.8, radius: 1);
  }
}
