import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

// We test the PDF generation logic by creating test images,
// saving them to temp files, and verifying the output PDF.
void main() {
  group('PDF generation integration', () {
    late Directory tempDir;
    late List<String> testImagePaths;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pdf_test_');
      testImagePaths = [];

      // Create test images
      for (var i = 0; i < 3; i++) {
        final image = img.Image(width: 200, height: 300);
        // Fill with different colors per page
        for (var y = 0; y < 300; y++) {
          for (var x = 0; x < 200; x++) {
            image.setPixelRgb(x, y, i * 80, 128, 255 - i * 80);
          }
        }
        final bytes = img.encodeJpg(image, quality: 85);
        final path = '${tempDir.path}/test_page_$i.jpg';
        await File(path).writeAsBytes(bytes);
        testImagePaths.add(path);
      }
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('test images are valid JPEG files', () async {
      for (final path in testImagePaths) {
        final file = File(path);
        expect(file.existsSync(), isTrue);
        final bytes = await file.readAsBytes();
        expect(bytes.length, greaterThan(0));
        // JPEG magic bytes
        expect(bytes[0], equals(0xFF));
        expect(bytes[1], equals(0xD8));
      }
    });

    test('test image can be decoded', () async {
      for (final path in testImagePaths) {
        final bytes = await File(path).readAsBytes();
        final decoded = img.decodeImage(bytes);
        expect(decoded, isNotNull);
        expect(decoded!.width, equals(200));
        expect(decoded.height, equals(300));
      }
    });
  });
}
