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

/// Nobody signed in, which is also why `paperlessApiProvider` throws.
class _FakeSignedOut extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.unauthenticated();
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

/// Fails the bookkeeping for whichever row the sweep reaches first, so the
/// per-row fault boundary is exercised with the failure it actually has to
/// survive: a database write.
///
/// Deliberately keyed on arrival rather than on a fixed id. `getPendingUploads`
/// has no ORDER BY, and a test that fails the *last* row swept proves nothing —
/// a boundary-less sweep dying after the final row strands nothing, so the
/// assertions pass either way. Failing the first row seen means there is always
/// a row behind it.
class _FailsFirstRow extends CacheRepository {
  _FailsFirstRow(super.db);

  int? failedId;

  @override
  Future<void> markUploadFailed(int id, String error) async {
    // Latched, not once-only. The service drains on build as well as on
    // demand, and a row that failed only on the first pass would simply be
    // marked by the second — the fake has to stay broken for the same row.
    failedId ??= id;
    if (id == failedId) {
      // StateError, not an Exception: `on Exception` would let this escape,
      // and the boundary has to hold for it too.
      throw StateError('database gone');
    }
    return super.markUploadFailed(id, error);
  }
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
    await cache.enqueueUpload(
      filePath: persisted,
      filename: name,
      serverUrl: 'https://paperless.example.com',
    );
    return persisted;
  }

  Future<void> drain() async {
    await container.read(uploadQueueServiceProvider.notifier).drainNow();
  }

  /// Awaits the drain a trigger started, instead of polling a wall clock.
  /// A timed loop fails as "expected [x], got []" on a slow runner, which is
  /// indistinguishable from a real regression.
  Future<void> settle(ProviderContainer c) async {
    for (var i = 0; i < 5; i++) {
      await c.read(uploadQueueServiceProvider.notifier).debugActiveDrain;
      await Future<void>.delayed(Duration.zero);
    }
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
    // retryCount stays 0: an unreachable server says nothing about the
    // document, so it must not spend the budget. See the offline test below.
    expect(pending.retryCount, 0);
    expect(pending.lastError, isNotNull);
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
      serverUrl: 'https://paperless.example.com',
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
    await settle(fresh);

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
      serverUrl: 'https://paperless.example.com',
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
            throw const NotAuthenticatedException();
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
    await settle(pending);

    expect(freshApi.uploaded, [path],
        reason: 'logging in must flush the queue on its own');
    expect(await freshCache.getPendingUploads(), isEmpty);
  });

  test('a row queued for another server is never uploaded to this one',
      () async {
    // Regression: switching profiles calls loginWithToken, which emits
    // AsyncLoading before authenticated. The auth listener reads that as an
    // unauthenticated->authenticated edge and drains, so every document queued
    // for account A was uploaded to account B.
    final source = File(p.join(root.path, 'src', 'other-account.pdf'))
      ..createSync(recursive: true)
      ..writeAsStringSync('PDF');
    final persisted = await store.persist(source.path);
    await cache.enqueueUpload(
      filePath: persisted,
      filename: 'other-account.pdf',
      serverUrl: 'https://someone-elses-server.example.com',
    );

    await drain();

    expect(api.uploaded, isEmpty,
        reason: 'this document belongs to a different account');
    expect(await cache.getPendingUploads(), hasLength(1),
        reason: 'it waits for its own server, it is not discarded');
    expect(await File(persisted).exists(), isTrue);
  });

  test('a row with no recorded server is skipped rather than guessed at',
      () async {
    final source = File(p.join(root.path, 'src', 'legacy.pdf'))
      ..createSync(recursive: true)
      ..writeAsStringSync('PDF');
    final persisted = await store.persist(source.path);
    await cache.enqueueUpload(filePath: persisted, filename: 'legacy.pdf');

    await drain();

    expect(api.uploaded, isEmpty);
    expect(await cache.getPendingUploads(), hasLength(1));
  });

  test('being offline does not consume the retry budget', () async {
    // Regression: ConnectivityNotifier reports online until its first real
    // check lands, so the startup drain runs while offline. Counting those as
    // retries meant five launches out of signal terminally failed a good
    // upload, and the drain then skipped it forever once signal came back.
    await queuedFile('in-a-tunnel.pdf');
    api.failure = DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.connectionError,
    );

    for (var launch = 0; launch < 6; launch++) {
      await drain();
    }

    final row = (await cache.getPendingUploads()).single;
    expect(row.retryCount, 0, reason: 'unreachable server is not the document');
    expect(row.isFailed, isFalse, reason: 'must still upload once back online');
    expect(row.lastError, isNotNull, reason: 'the reason is still recorded');
  });

  test('a server-side rejection still consumes the retry budget', () async {
    await queuedFile('rejected.pdf');
    api.failure = DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.badResponse,
    );

    await drain();

    expect((await cache.getPendingUploads()).single.retryCount, 1);
  });

  /// Ages a row so retention logic can be exercised without waiting 30 days.
  Future<void> ageRow(int id, Duration age) async {
    await (db.update(db.pendingUploads)..where((t) => t.id.equals(id))).write(
      PendingUploadsCompanion(queuedAt: Value(DateTime.now().subtract(age))),
    );
  }

  group('retention records an outcome without destroying the document', () {
    test('a row for a server that never comes back is eventually given up on',
        () async {
      // Regression: unreachable failures stopped consuming retries, so the row
      // never became isFailed and retention — which only ran for isFailed rows
      // — never recorded any outcome for it at all.
      final path = await queuedFile('abandoned.pdf');
      api.failure = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );
      await drain();
      await ageRow((await cache.getPendingUploads()).single.id,
          const Duration(days: 31));

      await drain();

      final row = (await cache.getPendingUploads()).single;
      expect(row.isFailed, isTrue, reason: 'the outcome is on the record');
      expect(row.lastError, contains('Gave up'));
      expect(await File(path).exists(), isTrue,
          reason: 'the file IS the document, and no UI can warn about losing '
              'it — expiry stops retrying, it does not delete');
    });

    test('a row whose profile was deleted is also given up on', () async {
      // Rows for another server are skipped before any cleanup, so a deleted
      // profile used to leave its documents with no recorded outcome forever.
      final source = File(p.join(root.path, 'src', 'deleted-profile.pdf'))
        ..createSync(recursive: true)
        ..writeAsStringSync('PDF');
      final persisted = await store.persist(source.path);
      await cache.enqueueUpload(
        filePath: persisted,
        filename: 'deleted-profile.pdf',
        serverUrl: 'https://server-that-no-longer-exists.example.com',
      );
      await ageRow((await cache.getPendingUploads()).single.id,
          const Duration(days: 31));

      await drain();

      expect((await cache.getPendingUploads()).single.isFailed, isTrue);
      expect(await File(persisted).exists(), isTrue,
          reason: 'a deleted profile is not a reason to destroy the document');
    });

    /// A genuinely signed-out launch.
    ///
    /// The auth state is unauthenticated AND the API throws, because in the app
    /// the second follows from the first: `dioProvider` throws
    /// `NotAuthenticatedException` precisely when authState is not
    /// authenticated (`auth_provider.dart:90-93`). An authenticated auth state
    /// with a throwing API is a combination the app cannot produce, and a
    /// fixture built that way would also leave `activeServer` non-null, which
    /// is not what the drain sees when nobody is signed in.
    ProviderContainer signedOutContainer() {
      final c = ProviderContainer(
        overrides: [
          cacheRepositoryProvider.overrideWithValue(cache),
          pendingUploadStoreProvider.overrideWith((ref) async => store),
          connectivityNotifierProvider.overrideWith(_FakeOnline.new),
          authStateProvider.overrideWith(_FakeSignedOut.new),
          paperlessApiProvider.overrideWith(
            (ref) => throw const NotAuthenticatedException(),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('an expired row is given up on even with no server configured',
        () async {
      // Regression: the drain returned as soon as paperlessApiProvider threw,
      // so the retention sweep never ran for a signed-out user — whose queue
      // then grew with no outcome ever recorded for any of it.
      final path = await queuedFile('signed-out.pdf');
      await ageRow((await cache.getPendingUploads()).single.id,
          const Duration(days: 31));

      await signedOutContainer()
          .read(uploadQueueServiceProvider.notifier)
          .drainNow();

      expect((await cache.getPendingUploads()).single.isFailed, isTrue,
          reason: 'retention cannot depend on being signed in');
      expect(await File(path).exists(), isTrue);
    });

    test('a row the sweep cannot record does not strand the rest', () async {
      await queuedFile('unrecordable.pdf');
      await queuedFile('behind-it.pdf');
      final rows = await cache.getPendingUploads();
      for (final row in rows) {
        await ageRow(row.id, const Duration(days: 31));
      }
      final repo = _FailsFirstRow(db);

      final broken = ProviderContainer(
        overrides: [
          cacheRepositoryProvider.overrideWithValue(repo),
          paperlessApiProvider.overrideWithValue(api),
          pendingUploadStoreProvider.overrideWith((ref) async => store),
          authStateProvider.overrideWith(_FakeAuthenticated.new),
          connectivityNotifierProvider.overrideWith(_FakeOnline.new),
        ],
      );
      addTearDown(broken.dispose);

      await broken.read(uploadQueueServiceProvider.notifier).drainNow();

      // Asserted on database state rather than file existence, so the proof
      // does not depend on which row SQLite happened to return first.
      final swept = await cache.getPendingUploads();
      final threw = repo.failedId;
      expect(threw, isNotNull, reason: 'the sweep must have reached a row');
      expect(swept.where((r) => r.isFailed).map((r) => r.id),
          swept.map((r) => r.id).where((id) => id != threw),
          reason: 'every row behind the one that threw is still swept');

      expect(swept.every((r) => File(r.filePath).existsSync()), isTrue,
          reason: 'the sweep never deletes, whether or not its write succeeds');
    });

    test('a recent row is untouched while signed out', () async {
      final path = await queuedFile('still-waiting.pdf');

      await signedOutContainer()
          .read(uploadQueueServiceProvider.notifier)
          .drainNow();

      expect(await File(path).exists(), isTrue);
      expect((await cache.getPendingUploads()).single.isFailed, isFalse);
    });

    test('a recent row for another server is left completely alone', () async {
      final source = File(p.join(root.path, 'src', 'other-recent.pdf'))
        ..createSync(recursive: true)
        ..writeAsStringSync('PDF');
      final persisted = await store.persist(source.path);
      await cache.enqueueUpload(
        filePath: persisted,
        filename: 'other-recent.pdf',
        serverUrl: 'https://other.example.com',
      );

      await drain();

      expect(await File(persisted).exists(), isTrue);
      expect((await cache.getPendingUploads()).single.isFailed, isFalse);
      expect(api.uploaded, isEmpty);
    });
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
          (ref) => throw const NotAuthenticatedException(),
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
        reason: 'a row still inside its retention window keeps its file');
  });
}
