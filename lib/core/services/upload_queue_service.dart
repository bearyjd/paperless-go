import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_providers.dart';
import '../api/paperless_api.dart';
import '../database/cache_provider.dart';
import 'connectivity_service.dart';

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
  }

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
      final pending = await cache.getPendingUploads();

      const maxRetries = 5;
      for (final upload in pending) {
        if (upload.isFailed) continue;

        // The source file may have been cleaned up by the OS since it was
        // queued. Drop it rather than retrying forever against a missing path.
        if (!File(upload.filePath).existsSync()) {
          await cache.removePendingUpload(upload.id);
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
