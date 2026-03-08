import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'filters/deskew.dart';
import 'presets.dart';

/// Messages sent from the processing isolate to report progress.
sealed class ProcessingMessage {}

class ProcessingProgress extends ProcessingMessage {
  final String stage;
  final double percent;
  ProcessingProgress(this.stage, this.percent);
}

class ProcessingComplete extends ProcessingMessage {
  final Uint8List result;
  ProcessingComplete(this.result);
}

class ProcessingError extends ProcessingMessage {
  final String error;
  ProcessingError(this.error);
}

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

  /// Enhance an image file with progress reporting via a stream.
  /// Yields [ProcessingProgress] messages during processing and
  /// a final [ProcessingComplete] or [ProcessingError] message.
  static Stream<ProcessingMessage> enhanceImageWithProgress({
    required String inputPath,
    required ProcessingPreset preset,
    int? maxDimension,
  }) async* {
    yield ProcessingProgress('Reading file', 0.0);

    final inputBytes = await File(inputPath).readAsBytes();

    double? deskewAngle;
    if (preset != ProcessingPreset.none && preset != ProcessingPreset.photo) {
      yield ProcessingProgress('Detecting skew', 0.02);
      deskewAngle = await _detectDeskewAngle(inputPath);
    }

    yield ProcessingProgress('Decoding', 0.05);

    final receivePort = ReceivePort();
    final params = _IsolateProgressParams(
      sendPort: receivePort.sendPort,
      imageBytes: inputBytes,
      preset: preset,
      maxDimension: maxDimension ?? _processingMaxDimension,
      deskewAngle: deskewAngle,
    );

    late final Isolate isolate;
    try {
      isolate = await Isolate.spawn(_processInIsolateWithProgress, params);
    } catch (e) {
      yield ProcessingError('Failed to spawn isolate: $e');
      return;
    }

    await for (final message in receivePort) {
      if (message is ProcessingComplete) {
        // Write to file and yield complete with the file path encoded as bytes
        final dir = await getTemporaryDirectory();
        final outputPath =
            '${dir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(outputPath).writeAsBytes(message.result);
        yield ProcessingProgress('Done', 1.0);
        yield ProcessingComplete(Uint8List.fromList(outputPath.codeUnits));
        receivePort.close();
        isolate.kill();
        return;
      } else if (message is List) {
        // Progress: [stage, percent]
        yield ProcessingProgress(message[0] as String, message[1] as double);
      } else if (message is String) {
        // Error
        yield ProcessingError(message);
        receivePort.close();
        isolate.kill();
        return;
      }
    }
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

class _IsolateProgressParams {
  final SendPort sendPort;
  final Uint8List imageBytes;
  final ProcessingPreset preset;
  final int? maxDimension;
  final double? deskewAngle;

  _IsolateProgressParams({
    required this.sendPort,
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
  final needsDeskew =
      params.preset != ProcessingPreset.none &&
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

void _processInIsolateWithProgress(_IsolateProgressParams params) {
  final sendPort = params.sendPort;

  try {
    sendPort.send(['Decoding', 0.05]);

    var image = img.decodeImage(params.imageBytes);
    if (image == null) {
      sendPort.send('Failed to decode image');
      return;
    }

    // Bake EXIF orientation once
    image = img.bakeOrientation(image);

    sendPort.send(['Resizing', 0.10]);

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

    // Apply deskew in the isolate
    final needsDeskew =
        params.preset != ProcessingPreset.none &&
        params.preset != ProcessingPreset.photo;
    if (needsDeskew) {
      sendPort.send(['Deskewing', 0.15]);
      if (params.deskewAngle != null &&
          params.deskewAngle!.abs() > 0.3 &&
          params.deskewAngle!.abs() < 30) {
        image = applyDeskewWithAngle(image, params.deskewAngle!);
      } else if (params.deskewAngle == null) {
        image = applyDeskew(image);
      }
    }

    // Apply preset filters with per-step progress
    sendPort.send(['Applying filters', 0.35]);
    final enhanced = applyPreset(
      image,
      params.preset,
      skipDeskew: true,
      onProgress: (label, percent) => sendPort.send([label, percent]),
    );

    sendPort.send(['Encoding', 0.90]);
    final bytes = Uint8List.fromList(img.encodeJpg(enhanced, quality: 92));

    sendPort.send(ProcessingComplete(bytes));
  } catch (e) {
    sendPort.send('Processing error: $e');
  }
}
