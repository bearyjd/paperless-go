import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/database/cache_provider.dart';
import 'package:paperless_go/core/database/cache_repository.dart';
import 'package:paperless_go/core/services/pending_upload_store.dart';
import 'package:paperless_go/features/scanner/upload_notifier.dart';
import 'package:path/path.dart' as p;

/// `_enqueueForLater` runs *inside* the catch block of a failed upload, so
/// anything escaping it skips the state assignment and leaves the screen
/// spinning on `uploading` forever — file neither uploaded, nor queued, nor
/// reported. The store read is the risky part: getApplicationDocumentsDirectory
/// throws MissingPlatformDirectoryException and a missing registration throws
/// MissingPluginException, and both `implements Exception` rather than
/// extending FileSystemException, so a narrow catch lets them straight through.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late AppDatabase db;
  late CacheRepository cache;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('upload_enqueue_test');
    db = AppDatabase(NativeDatabase.memory());
    cache = CacheRepository(db);
  });

  tearDown(() async {
    await db.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<File> sourceFile() async {
    final f = File(p.join(root.path, 'shared.pdf'));
    await f.writeAsString('PDF');
    return f;
  }

  ProviderContainer containerWith(Override storeOverride) {
    final c = ProviderContainer(
      overrides: [
        cacheRepositoryProvider.overrideWithValue(cache),
        // Forces the upload to fail the way "no server configured" does, which
        // is what routes execution into _enqueueForLater in the first place.
        paperlessApiProvider
            .overrideWith((ref) => throw const NotAuthenticatedException()),
        storeOverride,
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('an unavailable store still queues, and never wedges on uploading',
      () async {
    final file = await sourceFile();
    final container = containerWith(
      pendingUploadStoreProvider.overrideWith(
        (ref) async => throw MissingPluginException('no path_provider'),
      ),
    );

    await container
        .read(uploadNotifierProvider.notifier)
        .uploadFile(filePath: file.path, filename: 'shared.pdf');

    final state = container.read(uploadNotifierProvider);
    expect(state.status, UploadStatus.queued,
        reason: 'the document must still be parked somewhere');
    expect(state.status, isNot(UploadStatus.uploading),
        reason: 'a stuck spinner is the failure this guards');

    final queued = (await cache.getPendingUploads()).single;
    expect(queued.filePath, file.path,
        reason: 'falls back to the original path when it cannot be persisted');
  });

  test('a healthy store persists the file out of evictable storage', () async {
    final file = await sourceFile();
    final store =
        PendingUploadStore(Directory(p.join(root.path, 'pending_uploads')));
    final container = containerWith(
      pendingUploadStoreProvider.overrideWith((ref) async => store),
    );

    await container
        .read(uploadNotifierProvider.notifier)
        .uploadFile(filePath: file.path, filename: 'shared.pdf');

    expect(container.read(uploadNotifierProvider).status, UploadStatus.queued);
    final queued = (await cache.getPendingUploads()).single;
    expect(queued.filePath, isNot(file.path));
    expect(p.isWithin(store.directory.path, queued.filePath), isTrue);
    expect(await File(queued.filePath).exists(), isTrue);
  });

  test('a source that vanished before queueing fails loudly, not silently',
      () async {
    final container = containerWith(
      pendingUploadStoreProvider.overrideWith(
        (ref) async =>
            PendingUploadStore(Directory(p.join(root.path, 'pending'))),
      ),
    );

    await container.read(uploadNotifierProvider.notifier).uploadFile(
          filePath: p.join(root.path, 'gone.pdf'),
          filename: 'gone.pdf',
        );

    final state = container.read(uploadNotifierProvider);
    expect(state.status, UploadStatus.failure);
    expect(state.errorMessage, isNotNull);
    expect(await cache.getPendingUploads(), isEmpty,
        reason: 'queueing a path with no file behind it is a doomed row');
  });
}
