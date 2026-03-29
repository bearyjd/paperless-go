import 'package:flutter/services.dart';

/// Platform channel wrapper for native PDF page rendering.
class PdfRendererChannel {
  static const _channel =
      MethodChannel('com.ventoux.paperlessgo/pdf_renderer');

  /// Renders all pages of a PDF file as PNG byte arrays.
  /// [scale] controls resolution: 1.0 = 72 DPI, 2.0 = 144 DPI.
  static Future<List<Uint8List>> renderPages(
    String filePath, {
    double scale = 1.5,
  }) async {
    final result = await _channel.invokeMethod<List>('renderPages', {
      'filePath': filePath,
      'scale': scale,
    });
    return result
            ?.map((e) => Uint8List.fromList((e as List).cast<int>()))
            .toList() ??
        [];
  }

  /// Returns the number of pages in a PDF file.
  static Future<int> getPageCount(String filePath) async {
    final count = await _channel.invokeMethod<int>('getPageCount', {
      'filePath': filePath,
    });
    return count ?? 0;
  }
}
