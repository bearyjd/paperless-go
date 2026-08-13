import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/upload/share_intent_handler.dart';

SharedFile _shared(String path, {String filename = '', String? mimeType}) =>
    SharedFile(
      path: path,
      filename: filename.isEmpty ? path.split('/').last : filename,
      mimeType: mimeType,
    );

void main() {
  group('resolveShareRoute', () {
    test('single shared image launches the PDF scan pipeline', () {
      // Regression: a single shared image used to route to /scan/upload as a
      // raw image, bypassing the PDF pipeline. It must now go to /scan/review.
      final route = resolveShareRoute([
        _shared('/tmp/photo.jpg', mimeType: 'image/jpeg'),
      ]);

      expect(route, isNotNull);
      expect(route!.location, '/scan/review');
      expect(route.extra, ['/tmp/photo.jpg']);
    });

    test('multiple shared images launch the PDF scan pipeline', () {
      final route = resolveShareRoute([
        _shared('/tmp/a.jpg', mimeType: 'image/jpeg'),
        _shared('/tmp/b.png', mimeType: 'image/png'),
      ]);

      expect(route!.location, '/scan/review');
      expect(route.extra, ['/tmp/a.jpg', '/tmp/b.png']);
    });

    test('single shared PDF uploads directly without the pipeline', () {
      final route = resolveShareRoute([
        _shared(
          '/tmp/share_123_invoice.pdf',
          filename: 'invoice.pdf',
          mimeType: 'application/pdf',
        ),
      ]);

      expect(route!.location, '/scan/upload');
      expect(
        route.extra,
        {'filePath': '/tmp/share_123_invoice.pdf', 'filename': 'invoice.pdf'},
      );
    });

    test('mixed share with at least one image prefers the pipeline', () {
      final route = resolveShareRoute([
        _shared('/tmp/scan.png', mimeType: 'image/png'),
        _shared('/tmp/notes.pdf', mimeType: 'application/pdf'),
      ]);

      expect(route!.location, '/scan/review');
      expect(route.extra, ['/tmp/scan.png']);
    });

    test('empty and path-less shares resolve to null', () {
      expect(resolveShareRoute([]), isNull);
      expect(
        resolveShareRoute([_shared('', mimeType: 'image/jpeg')]),
        isNull,
      );
    });
  });
}
