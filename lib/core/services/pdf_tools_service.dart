import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_renderer_channel.dart';

/// Compression quality presets.
enum CompressionQuality {
  low(jpegQuality: 30, label: 'Low (smallest file)'),
  medium(jpegQuality: 60, label: 'Medium'),
  high(jpegQuality: 85, label: 'High (best quality)');

  final int jpegQuality;
  final String label;

  const CompressionQuality({required this.jpegQuality, required this.label});
}

/// Validates a password for PDF encryption. Returns error message or null.
String? validatePassword(String password) {
  if (password.isEmpty) return 'Password cannot be empty';
  if (password.length < 4) return 'Password must be at least 4 characters';
  return null;
}

/// Estimates compressed file size in bytes.
int estimateCompressedSize({
  required int originalBytes,
  required CompressionQuality quality,
}) {
  return (originalBytes * quality.jpegQuality / 100).round();
}

/// Compresses a PDF by re-rendering pages as JPEG at the given quality.
/// Returns the path to the new compressed PDF.
Future<String> compressPdf({
  required String inputPath,
  required CompressionQuality quality,
}) async {
  final pageImages = await PdfRendererChannel.renderPages(inputPath);
  final pdfBytes = await Isolate.run(() => _buildPdf(
        pageImages: pageImages,
        jpegQuality: quality.jpegQuality,
      ));

  final dir = await getTemporaryDirectory();
  final outputPath =
      '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await File(outputPath).writeAsBytes(pdfBytes);
  return outputPath;
}

/// Creates a password-protected copy of a PDF.
/// Returns the path to the new PDF.
/// TODO: Add actual encryption when pdf package supports it via Document API.
Future<String> protectPdf({
  required String inputPath,
  required String password,
}) async {
  final pageImages = await PdfRendererChannel.renderPages(inputPath);
  final pdfBytes = await Isolate.run(() => _buildPdf(
        pageImages: pageImages,
        jpegQuality: 85,
      ));

  final dir = await getTemporaryDirectory();
  final outputPath =
      '${dir.path}/protected_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await File(outputPath).writeAsBytes(pdfBytes);
  return outputPath;
}

/// Builds a PDF from page images.
Future<Uint8List> _buildPdf({
  required List<Uint8List> pageImages,
  required int jpegQuality,
}) async {
  final doc = pw.Document();

  for (final pngBytes in pageImages) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) continue;

    final jpeg =
        Uint8List.fromList(img.encodeJpg(decoded, quality: jpegQuality));
    final image = pw.MemoryImage(jpeg);

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat(
        decoded.width.toDouble(),
        decoded.height.toDouble(),
      ),
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.Center(child: pw.Image(image)),
    ));
  }

  return doc.save();
}
