import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/database/cache_provider.dart';
import 'package:paperless_go/core/database/cache_repository.dart';
import 'package:paperless_go/core/services/connectivity_service.dart';
import 'package:paperless_go/core/services/pending_upload_store.dart';
import 'package:paperless_go/core/services/upload_queue_service.dart';
import 'package:paperless_go/features/upload_queue/upload_queue_notifier.dart';
import 'package:path/path.dart' as p;

class _FakeApi extends PaperlessApi {
  _FakeApi() : super(Dio());

  final uploaded = <String>[];
  Object? failure;

  @override
  Future<String> uploadDocument({
    required String filePath,
    required String filename,
    String? title,
    int? correspondent,
    int? documentType,
    List<int>? tags,
    DateTime? created,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final error = failure;
    if (error != null) throw error;
    uploaded.add(filePath);
    return 'task-${uploaded.length}';
  }
}

class _FakeAuthenticated extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.authenticated(
        serverUrl: 'https://paperless.example.com',
        token: 'test-token',
      );
}

/// Deletes every row the drain just snapshotted, standing in for the user
/// tapping Delete in the instant between the snapshot and the send.
class _DeletesAfterSnapshot extends CacheRepository {
  _DeletesAfterSnapshot(super.db);

  @override
  Future<List<PendingUpload>> getPendingUploads() async {
    final rows = await super.getPendingUploads();
    for (final row in rows) {
      await super.removePendingUpload(row.id);
    }
    return rows;
  }
}

class _FakeOnline extends ConnectivityNotifier {
  @override
  bool build() => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late AppDatabase db;
  late CacheRepository cache;
  late PendingUploadStore store;
  late _FakeApi api;
  late ProviderContainer container;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('upload_queue_actions_test');
    db = AppDatabase(NativeDatabase.memory());
    cache = CacheRepository(db);
    store = PendingUploadStore(Directory(p.join(root.path, 'pending_uploads')));
    api = _FakeApi();
    container = ProviderContainer(
      overrides: [
        cacheRepositoryProvider.overrideWithValue(cache),
        paperlessApiProvider.overrideWithValue(api),
        pendingUploadStoreProvider.overrideWith((ref) async => store),
        authStateProvider.overrideWith(_FakeAuthenticated.new),
        connectivityNotifierProvider.overrideWith(_FakeOnline.new),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<PendingUpload> queued(String name, {bool failed = false}) async {
    final source = File(p.join(root.path, 'src', name))
      ..createSync(recursive: true)
      ..writeAsStringSync('PDF');
    final persisted = await store.persist(source.path);
    await cache.enqueueUpload(
      filePath: persisted,
      filename: name,
      serverUrl: 'https://paperless.example.com',
    );
    final row = (await cache.getPendingUploads()).last;
    if (failed) {
      await cache.markUploadFailed(row.id, 'gave up');
      return (await cache.getPendingUploads()).firstWhere((r) => r.id == row.id);
    }
    return row;
  }

  UploadQueueActions actions() =>
      container.read(uploadQueueActionsProvider.notifier);

  group('retry', () {
    test('clears the failure state and uploads on the spot', () async {
      final row = await queued('stuck.pdf', failed: true);

      await actions().retry(row);

      expect(api.uploaded, hasLength(1),
          reason: 'retry must drain now, not wait for the next trigger');
      expect(await cache.getPendingUploads(), isEmpty);
    });

    test('resets the retry budget, not just the failed flag', () async {
      // A reset that left retryCount at the limit would be skipped again on
      // the very next pass, so the button would appear to do nothing.
      final row = await queued('exhausted.pdf');
      for (var i = 0; i < 5; i++) {
        await cache.incrementRetryCount(row.id, 'boom', maxRetries: 5);
      }
      expect((await cache.getPendingUploads()).single.isFailed, isTrue);

      await cache.resetUploadForRetry(row.id);

      final reset = (await cache.getPendingUploads()).single;
      expect(reset.retryCount, 0);
      expect(reset.isFailed, isFalse);
      expect(reset.lastError, isNull);
    });

    test('a retry that fails again leaves the row and its file intact',
        () async {
      final row = await queued('still-broken.pdf', failed: true);
      api.failure = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );

      await actions().retry(row);

      expect(await cache.getPendingUploads(), hasLength(1));
      expect(await File(row.filePath).exists(), isTrue);
    });
  });

  test('retry rescues a row retention already gave up on', () async {
    // Found by /codex review, then reproduced: retention marks a 30-day-old row
    // failed, and the sweep runs BEFORE the upload pass — so a reset that left
    // queuedAt alone was re-failed on the very next drain without a single
    // upload attempt. Retry was a guaranteed no-op on exactly the rows this
    // screen exists to rescue.
    final row = await queued('ancient.pdf');
    await (db.update(db.pendingUploads)..where((t) => t.id.equals(row.id)))
        .write(PendingUploadsCompanion(
            queuedAt: Value(DateTime.now().subtract(const Duration(days: 31)))));
    await container.read(uploadQueueServiceProvider.notifier).drainNow();
    final expired = (await cache.getPendingUploads()).single;
    expect(expired.isFailed, isTrue, reason: 'retention gave up on it');

    await actions().retry(expired);

    expect(api.uploaded, hasLength(1),
        reason: 'retry must actually send a retention-expired document');
    expect(await cache.getPendingUploads(), isEmpty);
  });

  group('delete', () {
    test('removes the row and the file', () async {
      final row = await queued('unwanted.pdf');

      await actions().delete(row);

      expect(await cache.getPendingUploads(), isEmpty);
      expect(await File(row.filePath).exists(), isFalse);
    });

    test('a missing file still removes the row', () async {
      final row = await queued('already-gone.pdf');
      await File(row.filePath).delete();

      await actions().delete(row);

      expect(await cache.getPendingUploads(), isEmpty);
    });
  });

  group('clearFailed', () {
    test('deletes failed rows and leaves everything else alone', () async {
      final waiting = await queued('waiting.pdf');
      await queued('dead-1.pdf', failed: true);
      await queued('dead-2.pdf', failed: true);

      final cleared = await actions().clearFailed();

      expect(cleared, 2);
      // The count is what was actually deleted, not what was attempted.
      final left = await cache.getPendingUploads();
      expect(left.single.id, waiting.id,
          reason: 'a row that might still succeed must survive a bulk clear');
      expect(await File(waiting.filePath).exists(), isTrue);
    });
  });

  test('a row deleted after the drain snapshot is not uploaded anyway',
      () async {
    // The race Codex flagged. Deleting BEFORE the drain proves nothing — the
    // snapshot simply never contains the row. The window that matters is
    // between the snapshot and the POST, so the fake deletes the row at
    // exactly that point.
    final deleting = _DeletesAfterSnapshot(db);
    final racing = ProviderContainer(
      overrides: [
        cacheRepositoryProvider.overrideWithValue(deleting),
        paperlessApiProvider.overrideWithValue(api),
        pendingUploadStoreProvider.overrideWith((ref) async => store),
        authStateProvider.overrideWith(_FakeAuthenticated.new),
        connectivityNotifierProvider.overrideWith(_FakeOnline.new),
      ],
    );
    addTearDown(racing.dispose);
    await queued('deleted-mid-flight.pdf');

    await racing.read(uploadQueueServiceProvider.notifier).drainNow();

    expect(api.uploaded, isEmpty,
        reason: 'a document the user deleted must not reach the server');
  });

  group('uploadsNeedingAttention', () {
    test('counts failed rows but not rows that are merely waiting', () async {
      await queued('waiting.pdf');
      await queued('failed.pdf', failed: true);
      // Let the stream provider emit.
      await container.read(pendingUploadsProvider.future);

      expect(container.read(uploadsNeedingAttentionProvider), 1);
    });
  });
}
