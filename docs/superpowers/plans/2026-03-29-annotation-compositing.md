# Annotation Compositing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Use TDD.

**Goal:** Actually bake annotation drawings into the saved PDF so the shared file contains the annotations visually.

**Architecture:** Use Flutter's `PictureRecorder` + `Canvas` to render each page image with its annotation strokes into a composite bitmap. Then rebuild the PDF from these composited images using the existing `pdf` package pipeline. The `AnnotationPainter` already knows how to draw strokes — we reuse its `paint()` method on the recording canvas.

**Tech Stack:** Flutter `PictureRecorder`, `Canvas`, `dart:ui`, existing `AnnotationPainter`, `pdf` package, `image` package

---

## Task 1 — Annotation export service (TDD)

**Files:**
- Create: `lib/features/annotate/annotation_export.dart`
- Create: `test/unit/annotate/annotation_export_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/annotate/annotation_export.dart';
import 'package:paperless_go/features/annotate/annotation_model.dart';

void main() {
  group('compositePageImage', () {
    test('returns original bytes when no strokes', () async {
      // Create a minimal 1x1 PNG
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(1, 1);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final result = await compositePageImage(
        pageImagePng: pngBytes,
        strokes: [],
        pageWidth: 1,
        pageHeight: 1,
      );
      // Should still produce valid PNG bytes
      expect(result, isNotEmpty);
    });
  });

  group('buildAnnotatedPdf', () {
    test('returns non-empty bytes', () async {
      // Minimal test: no pages should still produce valid (empty) PDF
      final result = await buildAnnotatedPdf(
        compositeImages: [],
        jpegQuality: 85,
      );
      expect(result, isNotEmpty);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

- [ ] **Step 3: Create `lib/features/annotate/annotation_export.dart`**

```dart
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

  // Decode the page image
  final codec = await ui.instantiateImageCodec(pageImagePng);
  final frame = await codec.getNextFrame();
  final pageImage = frame.image;

  // Create a recording canvas
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, pageWidth.toDouble(), pageHeight.toDouble()));

  // Draw the page image
  canvas.drawImage(pageImage, Offset.zero, Paint());

  // Draw annotations on top
  final painter = AnnotationPainter(strokes: strokes);
  painter.paint(canvas, Size(pageWidth.toDouble(), pageHeight.toDouble()));

  // Render to image
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
```

- [ ] **Step 4: Run tests**

- [ ] **Step 5: Run full suite**

- [ ] **Step 6: Commit**

```bash
git add lib/features/annotate/annotation_export.dart \
        test/unit/annotate/annotation_export_test.dart
git commit -m "feat: add annotation compositing export service"
```

---

## Task 2 — Wire export into annotate screen

**Files:**
- Modify: `lib/features/annotate/annotate_screen.dart`

- [ ] **Step 1: Replace the share action**

In `annotate_screen.dart`, find the `_saveAndShare` method. Replace the current implementation (which just shares the original) with proper compositing:

```dart
Future<void> _saveAndShare() async {
  if (!_annotations.hasAnnotations) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Saving annotated PDF...'), duration: Duration(seconds: 30)),
  );

  try {
    // Composite each page
    final compositeImages = <Uint8List>[];
    for (int i = 0; i < _pageImages.length; i++) {
      final strokes = _annotations.strokes(i);
      final decoded = img.decodePng(_pageImages[i]);
      final composited = await compositePageImage(
        pageImagePng: _pageImages[i],
        strokes: strokes,
        pageWidth: decoded?.width ?? 800,
        pageHeight: decoded?.height ?? 1200,
      );
      compositeImages.add(composited);
    }

    // Build PDF
    final pdfBytes = await buildAnnotatedPdf(
      compositeImages: compositeImages,
      jpegQuality: 85,
    );

    // Save to temp and share
    final dir = await getTemporaryDirectory();
    final outputPath = '${dir.path}/annotated_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(outputPath).writeAsBytes(pdfBytes);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await Share.shareXFiles([XFile(outputPath)], text: widget.title);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }
}
```

Add imports:
```dart
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'annotation_export.dart';
```

- [ ] **Step 2: Run analysis and tests**

- [ ] **Step 3: Commit**

```bash
git add lib/features/annotate/annotate_screen.dart
git commit -m "feat: wire annotation compositing into save/share flow"
```
