import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'presets.dart';

/// Coordinates image enhancement processing.
/// Runs heavy image operations in an isolate to keep UI responsive.
class ImageEnhancer {
  /// Enhance an image file with the given preset.
  /// Returns the path to the enhanced image file.
  /// Runs in a background isolate.
  static Future<String> enhanceImage({
    required String inputPath,
    required ProcessingPreset preset,
    int? maxDimension,
  }) async {
    final inputBytes = await File(inputPath).readAsBytes();
    final outputBytes = await compute(
      _processInIsolate,
      _ProcessingParams(
        imageBytes: inputBytes,
        preset: preset,
        maxDimension: maxDimension,
      ),
    );
    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outputPath).writeAsBytes(outputBytes);
    return outputPath;
  }

  /// Enhance raw image bytes with the given preset.
  /// Returns enhanced image bytes (JPEG).
  /// Runs in a background isolate.
  static Future<Uint8List> enhanceBytes({
    required Uint8List imageBytes,
    required ProcessingPreset preset,
    int? maxDimension,
  }) async {
    return compute(
      _processInIsolate,
      _ProcessingParams(
        imageBytes: imageBytes,
        preset: preset,
        maxDimension: maxDimension,
      ),
    );
  }

  /// Generate a thumbnail preview of enhancement.
  /// Uses a smaller image for fast preview.
  static Future<Uint8List> previewEnhancement({
    required Uint8List imageBytes,
    required ProcessingPreset preset,
  }) async {
    return compute(
      _processInIsolate,
      _ProcessingParams(
        imageBytes: imageBytes,
        preset: preset,
        maxDimension: 800,
      ),
    );
  }
}

class _ProcessingParams {
  final Uint8List imageBytes;
  final ProcessingPreset preset;
  final int? maxDimension;

  _ProcessingParams({
    required this.imageBytes,
    required this.preset,
    this.maxDimension,
  });
}

Uint8List _processInIsolate(_ProcessingParams params) {
  var image = img.decodeImage(params.imageBytes);
  if (image == null) {
    throw Exception('Failed to decode image');
  }

  // Resize for preview if maxDimension is set
  if (params.maxDimension != null) {
    final maxDim = params.maxDimension!;
    if (image.width > maxDim || image.height > maxDim) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? maxDim : null,
        height: image.height >= image.width ? maxDim : null,
        interpolation: img.Interpolation.linear,
      );
    }
  }

  final enhanced = applyPreset(image, params.preset);
  return Uint8List.fromList(img.encodeJpg(enhanced, quality: 92));
}
