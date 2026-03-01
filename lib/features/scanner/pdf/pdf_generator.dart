import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates a well-formed PDF from a list of image files.
class PdfGenerator {
  /// Generate a PDF from image file paths.
  /// Returns the path to the generated PDF file.
  static Future<String> generatePdf({
    required List<String> imagePaths,
    int jpegQuality = 85,
    bool preProcessed = false,
    String? title,
  }) async {
    // Read all image files in parallel
    final imageBytesList = await Future.wait(
      imagePaths.map((path) => File(path).readAsBytes()),
    );

    final pdfBytes = await Isolate.run(() => _buildPdf(
          imageBytesList: imageBytesList,
          jpegQuality: jpegQuality,
          preProcessed: preProcessed,
          title: title,
        ));

    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(outputPath).writeAsBytes(pdfBytes);
    return outputPath;
  }

  /// Get the estimated file size for given images at a quality level.
  /// Returns size in bytes.
  static Future<int> estimateSize({
    required List<String> imagePaths,
    int jpegQuality = 85,
  }) async {
    var totalSize = 0;
    for (final path in imagePaths) {
      final file = File(path);
      final size = await file.length();
      // Rough estimate: JPEG at quality Q is approximately Q/100 * original
      totalSize += (size * jpegQuality / 100).round();
    }
    // PDF overhead is roughly 1KB per page + headers
    totalSize += imagePaths.length * 1024 + 2048;
    return totalSize;
  }
}

Future<Uint8List> _buildPdf({
  required List<Uint8List> imageBytesList,
  required int jpegQuality,
  bool preProcessed = false,
  String? title,
}) async {
  final pdf = pw.Document(
    creator: 'Paperless Go',
    title: title ?? 'Scanned Document',
    producer: 'Paperless Go Scanner',
  );

  for (final imageBytes in imageBytesList) {
    Uint8List pdfImageBytes;
    bool isLandscape;

    if (preProcessed) {
      // Images from the enhance pipeline are already EXIF-oriented and
      // JPEG-encoded at quality 92. Skip the expensive decode→encode cycle
      // and use the bytes directly.
      final dims = _readJpegDimensions(imageBytes);
      if (dims == null) continue;
      isLandscape = dims.$1 > dims.$2;
      pdfImageBytes = imageBytes;
    } else {
      // Raw camera images: must decode for EXIF orientation + re-encode
      var decoded = img.decodeImage(imageBytes);
      if (decoded == null) continue;
      decoded = img.bakeOrientation(decoded);
      isLandscape = decoded.width > decoded.height;
      pdfImageBytes =
          Uint8List.fromList(img.encodeJpg(decoded, quality: jpegQuality));
    }

    final pdfImage = pw.MemoryImage(pdfImageBytes);
    final format =
        isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Center(
            child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
          );
        },
      ),
    );
  }

  return pdf.save();
}

/// Read JPEG width and height from the SOF marker without full decode.
/// Returns (width, height) or null if not a valid JPEG.
(int, int)? _readJpegDimensions(Uint8List data) {
  if (data.length < 4 || data[0] != 0xFF || data[1] != 0xD8) return null;
  var i = 2;
  while (i < data.length - 1) {
    if (data[i] != 0xFF) return null;
    final marker = data[i + 1];
    // SOF0, SOF1, SOF2 markers contain image dimensions
    if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
      if (i + 9 > data.length) return null;
      final height = (data[i + 5] << 8) | data[i + 6];
      final width = (data[i + 7] << 8) | data[i + 8];
      return (width, height);
    }
    // Skip this marker segment
    if (i + 3 >= data.length) return null;
    final segLen = (data[i + 2] << 8) | data[i + 3];
    i += 2 + segLen;
  }
  return null;
}
