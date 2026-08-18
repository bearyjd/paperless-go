import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_providers.dart';
import '../api/paperless_api.dart';
import '../api/upload_retry_policy.dart';
import '../auth/auth_provider.dart';
import '../database/app_database.dart';
import '../database/cache_provider.dart';
import '../database/cache_repository.dart';
import 'connectivity_service.dart';
import 'pending_upload_store.dart';

part 'upload_queue_service.g.dart';

@Riverpod(keepAlive: true)
class UploadQueueService extends _$UploadQueueService {
  bool _draining = false;
  bool _drainRequested = false;

  /// The drain currently in flight, if any.
  ///
  /// Every trigger is deliberately fire-and-forget, which leaves tests nothing
  /// to await — they used to poll on a wall clock, so a slow CI runner failed
  /// with "expected [x], got []", indistinguishable from a real regression.
  Future<void>? _activeDrain;

  @visibleForTesting
  Future<void>? get debugActiveDrain => _activeDrain;

  @override
  void build() {
    ref.listen(connectivityNotifierProvider, (previous, next) {
      if (previous == false && next == true) {
        _activeDrain = _drainQueue();
      }
    });

    // Connectivity edges alone are not enough. A share queued because no
    // server was configured yet would sit untouched until an unrelated network
    // blip happened to fire — configuring the server, or simply relaunching
    // the app, has to be enough to flush it.
    ref.listen(authStateProvider, (previous, next) {
      final wasAuthenticated =
          previous?.valueOrNull?.isAuthenticated ?? false;
      final isAuthenticated = next.valueOrNull?.isAuthenticated ?? false;
      if (!wasAuthenticated && isAuthenticated) {
        // Deferred a turn on purpose. dioProvider throws while unauthenticated,
        // and Riverpod serves that cached error to dependents
        // until the invalidation from this very state change propagates —
        // draining synchronously here reads the stale error and gives up.
        _activeDrain = Future.microtask(_drainQueue);
      }
    });

    _activeDrain = Future.microtask(_drainQueue);
  }

  /// Retries every queued upload now. Safe to call at any time — a drain
  /// already in flight is a no-op.
  Future<void> drainNow() => _drainQueue();

  /// How long the drain keeps retrying a queued upload before giving up on it.
  ///
  /// Four ways a row stops being acted on, and all of them need a stop:
  ///  - terminally failed, so the drain skips it;
  ///  - its server is unreachable, which deliberately does not consume retries;
  ///  - it belongs to another profile, possibly one since deleted;
  ///  - no server is configured at all, so the upload pass never starts.
  ///
  /// The last one is why the sweep runs before the API is resolved rather than
  /// as a guard inside the upload loop.
  ///
  /// Expiring a row records an outcome. It does NOT delete the file, which is
  /// the user's only copy of that document — app-documents storage is not
  /// evictable, so those bytes now accumulate until the user clears app data.
  /// That is a deliberate trade, and it is the wrong way round long-term:
  ///
  ///  - [DateTime.now] is not monotonic. This compares two wall-clock samples
  ///    taken up to 30 days apart with no sanity check on either, so a device
  ///    clock jump can expire a row that is days old — and a [queuedAt]
  ///    stamped while the clock ran ahead makes the difference negative, so
  ///    that row never expires at all.
  ///  - A plausibility heuristic cannot fix the first case: a 45-day forward
  ///    jump is indistinguishable from 45 days elapsed against a 30-day
  ///    window, so any threshold narrows the hole without closing it.
  ///  - There is no queue UI, so the user is never told any of this happens.
  ///
  /// Deleting on a timer you cannot trust, with no way to warn anyone, is how
  /// a document disappears with no trace. Keeping the bytes makes a clock jump
  /// cost storage instead of the document. Once the queue is visible — and can
  /// show a failed row, its `lastError`, and offer retry or delete — releasing
  /// the file here becomes defensible again.
  static const _retention = Duration(days: 30);

  /// Gives up on a row that has outlived [_retention].
  ///
  /// Returns true when the row was handled and the caller should move on. Both
  /// the row and its file are kept: the row because deleting it is how a
  /// document disappears with no trace, the file because it IS the document.
  /// See [_retention] for why nothing is deleted here yet.
  Future<bool> _giveUpIfExpired(
    CacheRepository cache,
    PendingUpload upload,
  ) async {
    if (DateTime.now().difference(upload.queuedAt) < _retention) return false;
    if (!upload.isFailed) {
      await cache.markUploadFailed(
        upload.id,
        'Gave up after ${_retention.inDays} days without reaching the server.',
      );
    }
    return true;
  }

  /// Drains until nothing new has been requested.
  ///
  /// A loop rather than tail recursion: a share enqueued during every pass
  /// would otherwise grow the stack one frame per pass with no bound.
  Future<void> _drainQueue() async {
    if (_draining) {
      _drainRequested = true;
      return;
    }
    _draining = true;
    try {
      do {
        _drainRequested = false;
        await _drainOnce();
      } while (_drainRequested);
    } finally {
      _draining = false;
    }
  }

  Future<void> _drainOnce() async {
    try {
      final cache = ref.read(cacheRepositoryProvider);
      final store = await ref.read(pendingUploadStoreProvider.future);
      final pending = await cache.getPendingUploads();

      // The retention sweep is a separate pass, ahead of resolving the API on
      // purpose. Anything that stops the drain acting on a row also stops that
      // row's outcome ever being recorded, and the biggest of those is having
      // no server at all: as a guard inside the upload pass, retention never
      // ran for a signed-out user, whose queue then grew without record.
      final live = <PendingUpload>[];
      for (final upload in pending) {
        try {
          if (await _giveUpIfExpired(cache, upload)) continue;
        } catch (e) {
          // One unreadable row must not strand the sweep for every row behind
          // it — the whole point of the sweep is that it always runs.
          //
          // Catches Error as well as Exception, deliberately: the likeliest
          // escapee is a Drift StateError, which `on Exception` would let
          // through to the outer handler — abandoning every row behind this
          // one, which is exactly the boundary this block exists to draw.
          //
          // The assert-guard is NOT for the outer catch's reason. That one
          // hides a DioException, which stringifies with the user's
          // self-hosted server URL; a Drift StateError carries no such
          // payload. It is guarded only because a dropped row has nowhere
          // better to go until the queue has a UI and this can reach
          // `lastError`.
          assert(() {
            debugPrint('Upload queue retention skipped a row: $e');
            return true;
          }());
          continue;
        }
        live.add(upload);
      }

      final PaperlessApi api;
      try {
        api = ref.read(paperlessApiProvider);
      } catch (_) {
        // Not logged in — nothing to upload against, but the sweep above has
        // already run.
        return;
      }
      final activeServer = ref.read(authStateProvider).valueOrNull?.serverUrl;

      const maxRetries = 5;
      for (final upload in live) {
        if (upload.isFailed) continue;

        // Never send someone's document to the wrong account. Switching server
        // profiles calls loginWithToken, which emits AsyncLoading before the
        // new authenticated state — the auth listener reads that as an
        // unauthenticated->authenticated edge and drains immediately, so
        // without this check every row queued for profile A went to profile B.
        //
        // A null serverUrl means the row predates this column. Skipping rather
        // than guessing: uploading to the wrong server is worse than waiting,
        // and the row keeps its file either way.
        if (upload.serverUrl != activeServer) {
          continue;
        }

        // Queued files live in app-private storage (PendingUploadStore), so a
        // missing one means it was cleared out from under us. Retrying is
        // pointless, but deleting the row silently is how a document
        // disappears without trace — mark it failed so it stays on the record.
        var uploaded = false;
        if (!await File(upload.filePath).exists()) {
          await cache.markUploadFailed(
            upload.id,
            'The queued file is no longer available on this device.',
          );
          continue;
        }
        try {
          List<int>? tags;
          if (upload.tagsJson != null) {
            tags = (jsonDecode(upload.tagsJson!) as List<dynamic>)
                .cast<int>();
          }

          await api.uploadDocument(
            filePath: upload.filePath,
            filename: upload.filename,
            title: upload.title,
            correspondent: upload.correspondent,
            documentType: upload.documentType,
            tags: tags,
            created: upload.created,
          );

          // At-least-once, not exactly-once: if the process dies between the
          // server accepting this upload and the row being removed, the next
          // drain sends it again.
          //
          // That does NOT produce a duplicate document. Verified against a real
          // paperless-ngx 2.20: consumption is checksum-deduplicated, and the
          // second copy is rejected with
          //   "Not consuming <file>: It is a duplicate of <doc> (#N)"
          // so the re-upload costs one failed task on the server and nothing
          // else. Client-side checksum suppression would reimplement this.
          await cache.removePendingUpload(upload.id);
          uploaded = true;
        } catch (e) {
          if (isUnreachableServerError(e)) {
            // Says nothing about the document — offline, server unreachable, no
            // session. Consuming a retry here meant five launches out of signal
            // terminally failed a perfectly good upload, and the drain then
            // skipped it forever even once connectivity came back. Made worse
            // by ConnectivityNotifier optimistically reporting online until its
            // first real check lands, so the startup drain runs while offline.
            await cache.recordUploadError(upload.id, e.toString());
          } else {
            await cache.incrementRetryCount(
              upload.id,
              e.toString(),
              maxRetries: maxRetries,
            );
          }
        }

        // Outside the try on purpose. The document is already on the server by
        // now, so a failure to delete our local copy is cosmetic — letting it
        // reach the catch above would retry an upload that already succeeded
        // against a row that no longer exists, and abandon the rest of the
        // queue with it.
        if (uploaded) {
          try {
            await store.discard(upload.filePath);
          } on FileSystemException catch (_) {
            // Leftover file; harmless.
          }
        }
      }
    } catch (e) {
      // Catches Error as well as Exception, deliberately. The drain is
      // fire-and-forget (a startup microtask, a ref.listen on the auth edge),
      // so anything escaping is an unhandled async error that kills the pass
      // silently — and the likeliest escapee is a StateError from a provider,
      // which `on Exception` does not catch. Queue rows are untouched by a
      // failed pass, so the next trigger retries them.
      //
      // Behind an assert: a DioException stringifies with the full request URL,
      // i.e. the user's self-hosted server address, which must not reach a
      // release logcat. Same rule friendlyApiMessage follows.
      assert(() {
        debugPrint('Upload queue drain aborted: $e');
        return true;
      }());
    }
  }
}
