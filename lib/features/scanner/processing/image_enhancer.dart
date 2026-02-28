import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'filters/deskew.dart';
import 'presets.dart';

/// Coordinates image enhancement processing.
/// Deskew runs on main isolate (ML Kit needs platform channels).
/// Filters run in a background isolate to keep UI responsive.
class ImageEnhancer {
  /// Enhance an image file with the given preset.
  /// Returns the path to the enhanced image file.
  static Future<String> enhanceImage({
    required String inputPath,
    required ProcessingPreset preset,
    int? maxDimension,
  }) async {
    var inputBytes = await File(inputPath).readAsBytes();

    // Deskew on main isolate (ML Kit needs platform channels)
    if (preset != ProcessingPreset.none && preset != ProcessingPreset.photo) {
      inputBytes = await _deskewOnMain(inputBytes, inputPath);
    }

    // Filters on background isolate
    final outputBytes = await compute(
      _processInIsolate,
      _ProcessingParams(
        imageBytes: inputBytes,
        preset: preset,
        maxDimension: maxDimension,
        skipDeskew: true, // Already done on main
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

  /// Run ML Kit deskew on the main isolate, return deskewed image bytes.
  static Future<Uint8List> _deskewOnMain(
      Uint8List imageBytes, String imagePath) async {
    try {
      var image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;
      image = img.bakeOrientation(image);
      final deskewed = await applyDeskewAsync(image, imagePath);
      if (identical(deskewed, image)) return imageBytes;
      return Uint8List.fromList(img.encodeJpg(deskewed, quality: 95));
    } catch (_) {
      return imageBytes; // Fallback: return original
    }
  }
}

class _ProcessingParams {
  final Uint8List imageBytes;
  final ProcessingPreset preset;
  final int? maxDimension;
  final bool skipDeskew;

  _ProcessingParams({
    required this.imageBytes,
    required this.preset,
    this.maxDimension,
    this.skipDeskew = false,
  });
}

Uint8List _processInIsolate(_ProcessingParams params) {
  var image = img.decodeImage(params.imageBytes);
  if (image == null) {
    throw Exception('Failed to decode image');
  }

  // Auto-orient based on EXIF data (handles photos taken at angles)
  image = img.bakeOrientation(image);

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

  final enhanced =
      applyPreset(image, params.preset, skipDeskew: params.skipDeskew);
  return Uint8List.fromList(img.encodeJpg(enhanced, quality: 92));
}
