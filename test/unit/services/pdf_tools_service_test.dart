import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/services/pdf_tools_service.dart';

void main() {
  group('CompressionQuality', () {
    test('low gives quality 30', () {
      expect(CompressionQuality.low.jpegQuality, 30);
    });

    test('medium gives quality 60', () {
      expect(CompressionQuality.medium.jpegQuality, 60);
    });

    test('high gives quality 85', () {
      expect(CompressionQuality.high.jpegQuality, 85);
    });

    test('labels are human-readable', () {
      expect(CompressionQuality.low.label, 'Low (smallest file)');
      expect(CompressionQuality.medium.label, 'Medium');
      expect(CompressionQuality.high.label, 'High (best quality)');
    });
  });

  group('estimateCompressedSize', () {
    test('estimates size based on quality ratio', () {
      final estimate = estimateCompressedSize(
        originalBytes: 1000000,
        quality: CompressionQuality.low,
      );
      expect(estimate, 300000);
    });

    test('high quality retains most of original size', () {
      final estimate = estimateCompressedSize(
        originalBytes: 1000000,
        quality: CompressionQuality.high,
      );
      expect(estimate, 850000);
    });
  });
}
