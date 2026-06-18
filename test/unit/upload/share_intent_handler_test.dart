import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/upload/share_intent_handler.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

SharedMediaFile _shared(String path, SharedMediaType type) =>
    SharedMediaFile(path: path, type: type);

void main() {
  group('resolveShareRoute', () {
    test('single shared image launches the PDF scan pipeline', () {
      // Regression: a single shared image used to route to /scan/upload as a
      // raw image, bypassing the PDF pipeline. It must now go to /scan/review.
      final route = resolveShareRoute([
        _shared('/tmp/photo.jpg', SharedMediaType.image),
      ]);

      expect(route, isNotNull);
      expect(route!.location, '/scan/review');
      expect(route.extra, ['/tmp/photo.jpg']);
    });

    test('multiple shared images launch the PDF scan pipeline', () {
      final route = resolveShareRoute([
        _shared('/tmp/a.jpg', SharedMediaType.image),
        _shared('/tmp/b.png', SharedMediaType.image),
      ]);

      expect(route!.location, '/scan/review');
      expect(route.extra, ['/tmp/a.jpg', '/tmp/b.png']);
    });

    test('single shared PDF uploads directly without the pipeline', () {
      final route = resolveShareRoute([
        _shared('/tmp/invoice.pdf', SharedMediaType.file),
      ]);

      expect(route!.location, '/scan/upload');
      expect(
        route.extra,
        {'filePath': '/tmp/invoice.pdf', 'filename': 'invoice.pdf'},
      );
    });

    test('mixed share with at least one image prefers the pipeline', () {
      final route = resolveShareRoute([
        _shared('/tmp/scan.png', SharedMediaType.image),
        _shared('/tmp/notes.pdf', SharedMediaType.file),
      ]);

      expect(route!.location, '/scan/review');
      expect(route.extra, ['/tmp/scan.png']);
    });

    test('empty and path-less shares resolve to null', () {
      expect(resolveShareRoute([]), isNull);
      expect(
        resolveShareRoute([_shared('', SharedMediaType.image)]),
        isNull,
      );
    });
  });
}
