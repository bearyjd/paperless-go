import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/database/cache_repository.dart';

/// One corrupt row must not take the queue down with it.
///
/// SQLite's column affinity accepts a text value in the `queued_at` INTEGER
/// column, so a corrupt row is reachable — and a whole-result-set decode then
/// throws `FormatException` for every row, killing the retention sweep and the
/// upload pass permanently.
void main() {
  late AppDatabase db;
  late CacheRepository cache;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cache = CacheRepository(db);
  });

  tearDown(() async => db.close());

  /// Writes a row SQLite accepts but the mapper cannot decode.
  Future<void> insertCorruptRow(String filename) async {
    await db.customStatement(
      "INSERT INTO pending_uploads (file_path, filename, queued_at, "
      "retry_count, is_failed) VALUES ('/queue/$filename', '$filename', "
      "'not-a-date', 0, 0)",
    );
  }

  test('a corrupt row does not hide the healthy ones', () async {
    await cache.enqueueUpload(
        filePath: '/queue/first.pdf',
        filename: 'first.pdf',
        serverUrl: 'https://s');
    await insertCorruptRow('corrupt.pdf');
    await cache.enqueueUpload(
        filePath: '/queue/last.pdf',
        filename: 'last.pdf',
        serverUrl: 'https://s');

    final rows = await cache.getPendingUploads();

    expect(rows.map((r) => r.filename), ['first.pdf', 'last.pdf'],
        reason: 'the rows on both sides of the corrupt one must survive');
  });

  test('the corrupt row is counted, not silently swallowed', () async {
    await cache.enqueueUpload(
        filePath: '/queue/ok.pdf', filename: 'ok.pdf', serverUrl: 'https://s');
    await insertCorruptRow('corrupt.pdf');

    // It still holds a file, so the user has to be able to find out it exists.
    expect(await cache.countUnreadablePendingUploads(), 1);
  });

  test('a healthy queue reports nothing unreadable', () async {
    await cache.enqueueUpload(
        filePath: '/queue/ok.pdf', filename: 'ok.pdf', serverUrl: 'https://s');

    expect(await cache.countUnreadablePendingUploads(), 0);
  });

  test('the live stream also survives a corrupt row', () async {
    await insertCorruptRow('corrupt.pdf');
    await cache.enqueueUpload(
        filePath: '/queue/ok.pdf', filename: 'ok.pdf', serverUrl: 'https://s');

    final rows = await cache.watchPendingUploads().first;

    expect(rows.map((r) => r.filename), ['ok.pdf'],
        reason: 'the queue screen must render rather than showing an error');
  });
}
