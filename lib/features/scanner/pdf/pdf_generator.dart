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
    String? title,
  }) async {
    final imageBytesList = <Uint8List>[];
    for (final path in imagePaths) {
      imageBytesList.add(await File(path).readAsBytes());
    }

    final pdfBytes = await Isolate.run(() => _buildPdf(
          imageBytesList: imageBytesList,
          jpegQuality: jpegQuality,
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
  String? title,
}) async {
  final pdf = pw.Document(
    creator: 'Paperless Go',
    title: title ?? 'Scanned Document',
    producer: 'Paperless Go Scanner',
  );

  for (final imageBytes in imageBytesList) {
    // Re-encode as JPEG at desired quality
    var decoded = img.decodeImage(imageBytes);
    if (decoded == null) continue;

    // Auto-orient based on EXIF data
    decoded = img.bakeOrientation(decoded);

    final jpeg = img.encodeJpg(decoded, quality: jpegQuality);
    final pdfImage = pw.MemoryImage(Uint8List.fromList(jpeg));

    // Auto-detect page orientation from aspect ratio
    final isLandscape = decoded.width > decoded.height;
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
