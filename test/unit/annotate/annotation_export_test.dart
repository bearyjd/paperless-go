import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/annotate/annotation_export.dart';

void main() {
  group('buildAnnotatedPdf', () {
    test('returns non-empty bytes for empty page list', () async {
      final result = await buildAnnotatedPdf(
        compositeImages: [],
        jpegQuality: 85,
      );
      expect(result, isNotEmpty);
    });
  });
}
