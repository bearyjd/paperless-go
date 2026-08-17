import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/services/pending_upload_store.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late PendingUploadStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pending_upload_store_test');
    store = PendingUploadStore(Directory(p.join(root.path, 'pending_uploads')));
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<File> writeSource(String name, String contents) async {
    final cache = Directory(p.join(root.path, 'cache'))..createSync(recursive: true);
    final file = File(p.join(cache.path, name));
    await file.writeAsString(contents);
    return file;
  }

  group('persist', () {
    test('copies a cache file into persistent storage, contents intact',
        () async {
      final source = await writeSource('obb tix.pdf', 'PDF-BYTES');

      final persisted = await store.persist(source.path);

      expect(persisted, isNot(source.path));
      expect(p.isWithin(store.directory.path, persisted), isTrue);
      expect(await File(persisted).readAsString(), 'PDF-BYTES');
    });

    test('leaves the original in place so the caller keeps its own copy',
        () async {
      final source = await writeSource('scan.pdf', 'x');

      await store.persist(source.path);

      expect(await source.exists(), isTrue);
    });

    test('survives the source being evicted afterwards — the whole point',
        () async {
      final source = await writeSource('evicted.pdf', 'STILL-HERE');
      final persisted = await store.persist(source.path);

      await source.delete();

      expect(await File(persisted).exists(), isTrue);
      expect(await File(persisted).readAsString(), 'STILL-HERE');
    });

    test('is idempotent for a path already inside the store', () async {
      final source = await writeSource('retry.pdf', 'x');
      final first = await store.persist(source.path);

      final second = await store.persist(first);

      expect(second, first);
      expect(store.directory.listSync().length, 1);
    });

    test('does not collide when two files share a basename', () async {
      final a = await writeSource('invoice.pdf', 'A');
      final persistedA = await store.persist(a.path);
      await a.delete();
      final b = await writeSource('invoice.pdf', 'B');

      final persistedB = await store.persist(b.path);

      expect(persistedB, isNot(persistedA));
      expect(await File(persistedA).readAsString(), 'A');
      expect(await File(persistedB).readAsString(), 'B');
    });

    test('concurrent persists of the same basename do not overwrite each other',
        () async {
      final cache = Directory(p.join(root.path, 'cache'))
        ..createSync(recursive: true);
      final a = File(p.join(cache.path, 'a', 'invoice.pdf'))
        ..createSync(recursive: true)
        ..writeAsStringSync('A');
      final b = File(p.join(cache.path, 'b', 'invoice.pdf'))
        ..createSync(recursive: true)
        ..writeAsStringSync('B');

      final persisted =
          await Future.wait([store.persist(a.path), store.persist(b.path)]);

      expect(persisted.toSet(), hasLength(2));
      expect(
        {
          await File(persisted[0]).readAsString(),
          await File(persisted[1]).readAsString(),
        },
        {'A', 'B'},
      );
    });

    test('returns the input unchanged when the source is missing', () async {
      final missing = p.join(root.path, 'gone.pdf');

      expect(await store.persist(missing), missing);
    });
  });

  group('discard', () {
    test('deletes a persisted copy', () async {
      final source = await writeSource('done.pdf', 'x');
      final persisted = await store.persist(source.path);

      await store.discard(persisted);

      expect(await File(persisted).exists(), isFalse);
    });

    test('never touches a file outside the store', () async {
      final source = await writeSource('mine.pdf', 'x');

      await store.discard(source.path);

      expect(await source.exists(), isTrue);
    });

    test('is a no-op for an already-deleted persisted file', () async {
      final source = await writeSource('twice.pdf', 'x');
      final persisted = await store.persist(source.path);
      await store.discard(persisted);

      await expectLater(store.discard(persisted), completes);
    });
  });
}
