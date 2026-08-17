import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_providers.dart';
import '../api/paperless_api.dart';
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

  @override
  void build() {
    ref.listen(connectivityNotifierProvider, (previous, next) {
      if (previous == false && next == true) {
        _drainQueue();
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
        _drainQueue();
      }
    });

    Future.microtask(_drainQueue);
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
      final pending = await cache.getPendingUploads();

      const maxRetries = 5;
      for (final upload in pending) {
        if (upload.isFailed) {
          await _releaseStaleFailure(store, upload);
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

          await cache.removePendingUpload(upload.id);
          uploaded = true;
        } catch (e) {
          await cache.incrementRetryCount(
            upload.id,
            e.toString(),
            maxRetries: maxRetries,
          );
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
    } on Exception catch (e) {
      // The drain is fire-and-forget (a microtask on startup, a ref.listen on
      // the auth edge), so anything escaping here is an unhandled async error
      // that kills the pass silently. Queue rows are untouched by a failed
      // pass, so the next trigger retries them.
      debugPrint('Upload queue drain aborted: $e');
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
