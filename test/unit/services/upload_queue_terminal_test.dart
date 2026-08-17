import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/database/cache_repository.dart';

void main() {
  late AppDatabase db;
  late CacheRepository cache;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cache = CacheRepository(db);
  });

  tearDown(() => db.close());

  test('markUploadFailed keeps the row so the document is not lost silently',
      () async {
    await cache.enqueueUpload(filePath: '/gone/obb tix.pdf', filename: 'obb tix.pdf');
    final queued = (await cache.getPendingUploads()).single;

    await cache.markUploadFailed(queued.id, 'The queued file is no longer available on this device.');

    final failed = (await cache.getFailedUploads()).single;
    expect(failed.id, queued.id);
    expect(failed.isFailed, isTrue);
    expect(failed.lastError, contains('no longer available'));
  });

  test('markUploadFailed does not consume a retry', () async {
    await cache.enqueueUpload(filePath: '/gone/x.pdf', filename: 'x.pdf');
    final queued = (await cache.getPendingUploads()).single;

    await cache.markUploadFailed(queued.id, 'missing');

    expect((await cache.getPendingUploads()).single.retryCount, 0);
  });

  test('incrementRetryCount tolerates a row a concurrent drain removed',
      () async {
    await cache.enqueueUpload(filePath: '/tmp/x.pdf', filename: 'x.pdf');
    final queued = (await cache.getPendingUploads()).single;
    await cache.removePendingUpload(queued.id);

    await expectLater(
      cache.incrementRetryCount(queued.id, 'boom', maxRetries: 5),
      completes,
    );
  });

  group('logout must not destroy the queue', () {
    // Regression: logout() called clearAll(), which deleted pendingUploads.
    // Switching server profiles goes through logout() — so the single most
    // likely fix for "server unreachable" wiped the uploads waiting on it.
    test('clearServerCache keeps queued uploads', () async {
      await cache.enqueueUpload(
        filePath: '/docs/obb tix.pdf',
        filename: 'obb tix.pdf',
      );

      await cache.clearServerCache();

      expect(await cache.getPendingUploads(), hasLength(1));
    });

    test('clearAll still wipes them, for a full local reset', () async {
      await cache.enqueueUpload(filePath: '/docs/x.pdf', filename: 'x.pdf');

      await cache.clearAll();

      expect(await cache.getPendingUploads(), isEmpty);
    });
  });
}
