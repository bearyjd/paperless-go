import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Static utility for rotating and cropping scanned images.
/// Both methods use [compute] to run in a background isolate
/// so the UI stays responsive with large (4000x3000+) images.
class CropRotate {
  CropRotate._();

  /// Rotate image 90 degrees clockwise or counter-clockwise.
  /// Returns the path to the new rotated image file.
  static Future<String> rotateImage90({
    required String inputPath,
    required bool clockwise,
  }) async {
    final inputBytes = await File(inputPath).readAsBytes();
    final outputBytes = await compute(
      _rotateIsolate,
      _RotateParams(inputBytes, clockwise),
    );
    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outputPath).writeAsBytes(outputBytes);
    return outputPath;
  }

  /// Crop image using normalized coordinates (0.0 - 1.0).
  /// Returns the path to the new cropped image file.
  static Future<String> cropImage({
    required String inputPath,
    required Rect cropNormalized,
  }) async {
    final inputBytes = await File(inputPath).readAsBytes();
    final outputBytes = await compute(
      _cropIsolate,
      _CropParams(inputBytes, cropNormalized),
    );
    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outputPath).writeAsBytes(outputBytes);
    return outputPath;
  }

  static Uint8List _rotateIsolate(_RotateParams params) {
    var image = img.decodeImage(params.inputBytes)!;
    image = img.bakeOrientation(image);
    image = img.copyRotate(image, angle: params.clockwise ? 90 : -90);
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  static Uint8List _cropIsolate(_CropParams params) {
    var image = img.decodeImage(params.inputBytes)!;
    image = img.bakeOrientation(image);

    final x = (params.crop.left * image.width).round();
    final y = (params.crop.top * image.height).round();
    final w = (params.crop.width * image.width).round();
    final h = (params.crop.height * image.height).round();

    image = img.copyCrop(image, x: x, y: y, width: w, height: h);
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }
}

class _RotateParams {
  final Uint8List inputBytes;
  final bool clockwise;
  _RotateParams(this.inputBytes, this.clockwise);
}

class _CropParams {
  final Uint8List inputBytes;
  final Rect crop;
  _CropParams(this.inputBytes, this.crop);
}
