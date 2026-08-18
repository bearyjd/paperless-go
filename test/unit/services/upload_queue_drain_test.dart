import 'dart:io';

import 'package:dio/dio.dart';
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
import 'package:path/path.dart' as p;

/// Drives the real drain loop.
///
/// Everything the queue exists for happens inside `_drainQueue`, and it had no
/// coverage at all — which is how "a discard failure aborts the whole pass"
/// and "a missing file silently deletes the row" both shipped. These tests
/// exercise it end to end against a fake server and a real on-disk store.
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

/// Starts unauthenticated and flips once [authenticate] is called, the way a
/// real launch restores a session after the queue service has already built.
class _DeferredAuth extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.unauthenticated();

  void authenticate() => state = const AsyncData(
        AuthStatus.authenticated(
          serverUrl: 'https://paperless.example.com',
          token: 'test-token',
        ),
      );
}

/// The real one opens a connectivity_plus EventChannel, which needs a platform.
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

  /// Builds the service and lets its startup drain run against an empty queue,
  /// so a test's own [drain] call is the only pass touching its rows.
  Future<void> warmUp() async {
    container.read(uploadQueueServiceProvider);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('upload_queue_drain_test');
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
    await warmUp();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// A file already living in the store, as `_enqueueForLater` would leave it.
  Future<String> queuedFile(String name, {String contents = 'PDF'}) async {
    final source = File(p.join(root.path, 'src', name))
      ..createSync(recursive: true)
      ..writeAsStringSync(contents);
    final persisted = await store.persist(source.path);
    await cache.enqueueUpload(filePath: persisted, filename: name);
    return persisted;
  }

  Future<void> drain() async {
    await container.read(uploadQueueServiceProvider.notifier).drainNow();
  }

  test('a queued upload is sent, its row removed and its file released',
      () async {
    final path = await queuedFile('obb tix.pdf');

    await drain();

    expect(api.uploaded, [path]);
    expect(await cache.getPendingUploads(), isEmpty);
    expect(await File(path).exists(), isFalse,
        reason: 'the persisted copy should not outlive a successful upload');
  });

  test('a failed upload keeps both the row and the file for the next pass',
      () async {
    final path = await queuedFile('retry.pdf');
    api.failure = DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.connectionError,
    );

    await drain();

    final pending = (await cache.getPendingUploads()).single;
    expect(pending.retryCount, 1);
    expect(pending.isFailed, isFalse);
    expect(await File(path).exists(), isTrue);
  });

  test('a later pass uploads what an earlier failure left behind', () async {
    final path = await queuedFile('eventually.pdf');
    api.failure = DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.connectionError,
    );
    await drain();

    api.failure = null;
    await drain();

    expect(api.uploaded, [path]);
    expect(await cache.getPendingUploads(), isEmpty);
  });

  test('a vanished file marks the row failed rather than deleting it',
      () async {
    final path = await queuedFile('evicted.pdf');
    await File(path).delete();

    await drain();

    final row = (await cache.getPendingUploads()).single;
    expect(row.isFailed, isTrue);
    expect(row.lastError, contains('no longer available'));
    expect(api.uploaded, isEmpty);
  });

  test('a terminally failed row is skipped, not retried', () async {
    await queuedFile('dead.pdf');
    final row = (await cache.getPendingUploads()).single;
    await cache.markUploadFailed(row.id, 'gone');

    await drain();

    expect(api.uploaded, isEmpty);
    expect(await cache.getPendingUploads(), hasLength(1));
  });

  test('one failure does not abandon the rest of the queue', () async {
    // Regression: discard/retry bookkeeping used to throw out of the loop,
    // so a single bad entry stranded everything queued behind it.
    final missing = await queuedFile('missing.pdf');
    await File(missing).delete();
    final good = await queuedFile('good.pdf');

    await drain();

    expect(api.uploaded, [good],
        reason: 'the healthy upload after the broken one must still be sent');
  });

  test('a queue left over from a previous run drains on startup', () async {
    // The service used to drain only on a connectivity false->true edge, so a
    // share queued because no server was configured sat there until an
    // unrelated network blip. Relaunching the app has to be enough.
    // Self-contained: the queue must already hold a row before the service is
    // ever built, which is the whole point — so this cannot reuse the
    // already-warmed container from setUp.
    final freshDb = AppDatabase(NativeDatabase.memory());
    final freshCache = CacheRepository(freshDb);
    final freshApi = _FakeApi();
    addTearDown(freshDb.close);

    final source = File(p.join(root.path, 'src', 'from-last-run.pdf'))
      ..createSync(recursive: true)
      ..writeAsStringSync('PDF');
    final path = await store.persist(source.path);
    await freshCache.enqueueUpload(
      filePath: path,
      filename: 'from-last-run.pdf',
    );

    final fresh = ProviderContainer(
      overrides: [
        cacheRepositoryProvider.overrideWithValue(freshCache),
        paperlessApiProvider.overrideWithValue(freshApi),
        pendingUploadStoreProvider.overrideWith((ref) async => store),
        authStateProvider.overrideWith(_FakeAuthenticated.new),
        connectivityNotifierProvider.overrideWith(_FakeOnline.new),
      ],
    );
    addTearDown(fresh.dispose);

    fresh.read(uploadQueueServiceProvider);
    // The startup drain is async (it awaits the store provider), so poll
    // rather than assuming a single microtask turn is enough.
    for (var i = 0; i < 100 && freshApi.uploaded.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(freshApi.uploaded, [path],
        reason: 'no explicit drain was requested — startup alone must flush');
    expect(await freshCache.getPendingUploads(), isEmpty);
  });

  test('logging in flushes a queue that was waiting on authentication',
      () async {
    // Regression, caught on a Pixel 9 Pro Fold: the queue sat there after
    // login and never drained. The auth listener fired correctly, but the api
    // provider throws while unauthenticated and Riverpod still served that
    // cached error to a read one millisecond later — so the drain gave up and
    // nothing retriggered it. The listener has to defer a turn.
    final freshDb = AppDatabase(NativeDatabase.memory());
    final freshCache = CacheRepository(freshDb);
    final freshApi = _FakeApi();
    addTearDown(freshDb.close);

    final source = File(p.join(root.path, 'src', 'after-login.pdf'))
      ..createSync(recursive: true)
      ..writeAsStringSync('PDF');
    final path = await store.persist(source.path);
    await freshCache.enqueueUpload(
      filePath: path,
      filename: 'after-login.pdf',
    );

    final auth = _DeferredAuth();
    final pending = ProviderContainer(
      overrides: [
        cacheRepositoryProvider.overrideWithValue(freshCache),
        pendingUploadStoreProvider.overrideWith((ref) async => store),
        connectivityNotifierProvider.overrideWith(_FakeOnline.new),
        authStateProvider.overrideWith(() => auth),
        // Mirrors dioProvider: throws while unauthenticated, so Riverpod
        // caches the failure exactly as it does in the app.
        paperlessApiProvider.overrideWith((ref) {
          final status = ref.watch(authStateProvider).valueOrNull;
          if (status == null || !status.isAuthenticated) {
            throw StateError('Not authenticated');
          }
          return freshApi;
        }),
      ],
    );
    addTearDown(pending.dispose);

    pending.read(uploadQueueServiceProvider);
    await Future<void>.delayed(Duration.zero);
    expect(freshApi.uploaded, isEmpty, reason: 'not logged in yet');

    auth.authenticate();
    for (var i = 0; i < 100 && freshApi.uploaded.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(freshApi.uploaded, [path],
        reason: 'logging in must flush the queue on its own');
    expect(await freshCache.getPendingUploads(), isEmpty);
  });

  test('drains without a server configured are a no-op, not a crash', () async {
    final path = await queuedFile('waiting.pdf');
    final offline = ProviderContainer(
      overrides: [
        cacheRepositoryProvider.overrideWithValue(cache),
        pendingUploadStoreProvider.overrideWith((ref) async => store),
        connectivityNotifierProvider.overrideWith(_FakeOnline.new),
        authStateProvider.overrideWith(_FakeAuthenticated.new),
        paperlessApiProvider.overrideWith(
          (ref) => throw StateError('Not authenticated'),
        ),
      ],
    );
    addTearDown(offline.dispose);

    await expectLater(
      offline.read(uploadQueueServiceProvider.notifier).drainNow(),
      completes,
    );
    expect(await cache.getPendingUploads(), hasLength(1));
    expect(await File(path).exists(), isTrue,
        reason: 'nothing may be discarded while the server is unreachable');
  });
}
