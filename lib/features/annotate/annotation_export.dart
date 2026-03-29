import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'annotation_model.dart';
import 'annotation_painter.dart';

/// Composites annotation strokes onto a page image.
/// Returns PNG bytes of the composited result.
Future<Uint8List> compositePageImage({
  required Uint8List pageImagePng,
  required List<Stroke> strokes,
  required int pageWidth,
  required int pageHeight,
}) async {
  if (strokes.isEmpty) return pageImagePng;

  final codec = await ui.instantiateImageCodec(pageImagePng);
  final frame = await codec.getNextFrame();
  final pageImage = frame.image;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, pageWidth.toDouble(), pageHeight.toDouble()),
  );

  canvas.drawImage(pageImage, Offset.zero, Paint());

  final painter = AnnotationPainter(strokes: strokes);
  painter.paint(canvas, Size(pageWidth.toDouble(), pageHeight.toDouble()));

  final picture = recorder.endRecording();
  final composited = await picture.toImage(pageWidth, pageHeight);
  final byteData = await composited.toByteData(format: ui.ImageByteFormat.png);

  pageImage.dispose();
  composited.dispose();

  return byteData!.buffer.asUint8List();
}

/// Builds a PDF from composited page images.
Future<Uint8List> buildAnnotatedPdf({
  required List<Uint8List> compositeImages,
  required int jpegQuality,
}) async {
  final doc = pw.Document();

  for (final pngBytes in compositeImages) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) continue;

    final jpeg = Uint8List.fromList(img.encodeJpg(decoded, quality: jpegQuality));
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

  return Uint8List.fromList(await doc.save());
}
