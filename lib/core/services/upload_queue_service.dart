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

  /// How long a terminally-failed upload keeps its file on disk.
  ///
  /// A failed row is skipped by the drain forever, so its persisted copy would
  /// otherwise never be released — and app-documents storage is not evictable
  /// by the OS, so it would grow without bound with no way for the user to
  /// reclaim it short of wiping app data. The window is generous because the
  /// file is the document itself; the row (and its error) is kept either way.
  static const _failedRetention = Duration(days: 30);

  Future<void> _releaseStaleFailure(
    PendingUploadStore store,
    PendingUpload upload,
  ) async {
    if (DateTime.now().difference(upload.queuedAt) < _failedRetention) return;
    try {
      await store.discard(upload.filePath);
    } on FileSystemException catch (_) {
      // Nothing to reclaim; the row still records the failure.
    }
  }

  Future<void> _drainQueue() async {
    if (_draining) {
      _drainRequested = true;
      return;
    }
    _draining = true;

    try {
      final cache = ref.read(cacheRepositoryProvider);
      final PaperlessApi api;
      try {
        api = ref.read(paperlessApiProvider);
      } catch (_) {
        // Not logged in — skip drain
        return;
      }
      final store = await ref.read(pendingUploadStoreProvider.future);
      final activeServer = ref.read(authStateProvider).valueOrNull?.serverUrl;
      final pending = await cache.getPendingUploads();

      const maxRetries = 5;
      for (final upload in pending) {
        if (upload.isFailed) {
          await _releaseStaleFailure(store, upload);
          continue;
        }

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

          // At-least-once, not exactly-once. If the process dies between the
          // server accepting the upload and this row being removed, the next
          // drain re-uploads it and paperless-ngx — which does no dedupe by
          // default — keeps both copies. Narrow window, but real; suppressing
          // it needs a checksum check against the server before re-upload.
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
    } finally {
      _draining = false;
    }

    // A share enqueued *during* this pass was not in the snapshot above and
    // would otherwise wait for an unrelated connectivity or auth edge.
    if (_drainRequested) {
      _drainRequested = false;
      await _drainQueue();
    }
  }
}
