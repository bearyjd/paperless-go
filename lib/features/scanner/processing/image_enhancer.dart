import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'filters/deskew.dart';
import 'presets.dart';

/// Coordinates image enhancement processing.
/// ML Kit deskew angle detection runs on the main isolate (platform channels).
/// All pixel processing runs in a background isolate.
class ImageEnhancer {
  /// Max dimension for processing. Full-res scans (4000x3000) are downscaled
  /// to this before filters run. 1600px is plenty for document OCR/viewing
  /// and keeps per-pixel filter work under ~2.5MP for reasonable speed.
  static const _processingMaxDimension = 1600;

  /// Enhance an image file with the given preset.
  /// Returns the path to the enhanced image file.
  static Future<String> enhanceImage({
    required String inputPath,
    required ProcessingPreset preset,
    int? maxDimension,
  }) async {
    final inputBytes = await File(inputPath).readAsBytes();

    // Only ML Kit angle detection runs on main isolate (needs platform channels).
    // All pixel work moves to the compute isolate.
    double? deskewAngle;
    if (preset != ProcessingPreset.none && preset != ProcessingPreset.photo) {
      deskewAngle = await _detectDeskewAngle(inputPath);
    }

    final outputBytes = await compute(
      _processInIsolate,
      _ProcessingParams(
        imageBytes: inputBytes,
        preset: preset,
        maxDimension: maxDimension ?? _processingMaxDimension,
        deskewAngle: deskewAngle,
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
        maxDimension: maxDimension ?? _processingMaxDimension,
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

  /// Run ML Kit angle detection on main isolate.
  /// Returns just the angle (degrees), or null if no skew detected.
  /// No pixel processing happens here — that all moves to the isolate.
  static Future<double?> _detectDeskewAngle(String imagePath) async {
    try {
      return await detectAngleWithMlKit(imagePath);
    } catch (_) {
      return null; // ML Kit unavailable; isolate will use fallback
    }
  }
}

class _ProcessingParams {
  final Uint8List imageBytes;
  final ProcessingPreset preset;
  final int? maxDimension;
  final double? deskewAngle;

  _ProcessingParams({
    required this.imageBytes,
    required this.preset,
    this.maxDimension,
    this.deskewAngle,
  });
}

Uint8List _processInIsolate(_ProcessingParams params) {
  var image = img.decodeImage(params.imageBytes);
  if (image == null) {
    throw Exception('Failed to decode image');
  }

  // Bake EXIF orientation once
  image = img.bakeOrientation(image);

  // Resize to processing cap before any filters run
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

  // Apply deskew in the isolate (no redundant decode/encode)
  final needsDeskew = params.preset != ProcessingPreset.none &&
      params.preset != ProcessingPreset.photo;
  if (needsDeskew) {
    if (params.deskewAngle != null &&
        params.deskewAngle!.abs() > 0.3 &&
        params.deskewAngle!.abs() < 30) {
      // Apply the ML Kit-detected angle
      image = applyDeskewWithAngle(image, params.deskewAngle!);
    } else if (params.deskewAngle == null) {
      // No ML Kit result — use pure Dart fallback
      image = applyDeskew(image);
    }
    // If angle was detected but too small (<=0.3), skip deskew
  }

  final enhanced = applyPreset(image, params.preset, skipDeskew: true);
  return Uint8List.fromList(img.encodeJpg(enhanced, quality: 92));
}
