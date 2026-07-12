import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/database/cache_repository.dart';

void main() {
  group('CacheRepository pending upload retries', () {
    late AppDatabase db;
    late CacheRepository cache;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      cache = CacheRepository(db);
    });

    tearDown(() async => await db.close());

    Future<int> queueUpload() async {
      await cache.enqueueUpload(
        filePath: '/tmp/doc.pdf',
        filename: 'doc.pdf',
      );
      final pending = await cache.getPendingUploads();
      return pending.single.id;
    }

    test('a permanently-failing upload is marked failed after maxRetries '
        'attempts, not retried forever', () async {
      final id = await queueUpload();

      for (var attempt = 1; attempt <= 5; attempt++) {
        await cache.incrementRetryCount(
          id,
          'server rejected the file',
          maxRetries: 5,
        );
      }

      final failed = await cache.getFailedUploads();
      expect(failed, hasLength(1));
      expect(failed.single.id, id);
      expect(failed.single.retryCount, 5);
    });

    test('stays retryable below maxRetries', () async {
      final id = await queueUpload();

      await cache.incrementRetryCount(id, 'timeout', maxRetries: 5);
      await cache.incrementRetryCount(id, 'timeout', maxRetries: 5);

      expect(await cache.getFailedUploads(), isEmpty);
      final pending = await cache.getPendingUploads();
      expect(pending.single.isFailed, false);
      expect(pending.single.retryCount, 2);
    });

    test('failed upload is still visible via getPendingUploads for the '
        'drain loop to skip, not silently deleted', () async {
      final id = await queueUpload();

      for (var attempt = 1; attempt <= 5; attempt++) {
        await cache.incrementRetryCount(id, 'boom', maxRetries: 5);
      }

      final pending = await cache.getPendingUploads();
      expect(pending, hasLength(1));
      expect(pending.single.isFailed, true);
    });
  });
}
