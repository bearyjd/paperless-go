import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/thumbnail_cache_bust.dart';

void main() {
  group('cacheBustedThumbnailUrl', () {
    const base = 'https://example.com/api/documents/1/thumb/';

    test('appends ?v=<modified ms> when modified is set', () {
      final modified = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      expect(cacheBustedThumbnailUrl(base, modified), '$base?v=1700000000000');
    });

    test('uses ?v=0 when modified is null', () {
      expect(cacheBustedThumbnailUrl(base, null), '$base?v=0');
    });

    test('produces a different URL when modified changes (cache-busts)', () {
      final a = cacheBustedThumbnailUrl(
          base, DateTime.fromMillisecondsSinceEpoch(1));
      final b = cacheBustedThumbnailUrl(
          base, DateTime.fromMillisecondsSinceEpoch(2));
      expect(a, isNot(b));
    });

    test('uses & when the url already has a query string', () {
      expect(
        cacheBustedThumbnailUrl(
            '$base?foo=bar', DateTime.fromMillisecondsSinceEpoch(5)),
        '$base?foo=bar&v=5',
      );
    });
  });
}
