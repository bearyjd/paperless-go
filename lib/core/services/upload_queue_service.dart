import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_providers.dart';
import '../api/paperless_api.dart';
import '../auth/auth_provider.dart';
import '../database/cache_provider.dart';
import 'connectivity_service.dart';
import 'pending_upload_store.dart';

part 'upload_queue_service.g.dart';

@Riverpod(keepAlive: true)
class UploadQueueService extends _$UploadQueueService {
  bool _draining = false;

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

  Future<void> _drainQueue() async {
    if (_draining) return;
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
        if (upload.isFailed) continue;

        // Queued files live in app-private storage (PendingUploadStore), so a
        // missing one means it was cleared out from under us. Retrying is
        // pointless, but deleting the row silently is how a document
        // disappears without trace — mark it failed so it stays on the record.
        if (!File(upload.filePath).existsSync()) {
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
          await store.discard(upload.filePath);
        } catch (e) {
          await cache.incrementRetryCount(
            upload.id,
            e.toString(),
            maxRetries: maxRetries,
          );
        }
      }
    } finally {
      _draining = false;
    }
  }
}
