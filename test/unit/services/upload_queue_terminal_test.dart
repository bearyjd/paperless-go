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
}
