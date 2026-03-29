import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_providers.dart';
import '../api/paperless_api.dart';
import '../database/app_database.dart';
import '../services/connectivity_service.dart';
import 'edit_queue_service.dart';

part 'edit_queue_processor.g.dart';

@Riverpod(keepAlive: true)
class EditQueueProcessor extends _$EditQueueProcessor {
  @override
  Future<void> build() async {
    final isOnline = ref.watch(connectivityNotifierProvider);
    if (isOnline) {
      await _processQueue();
    }
  }

  Future<void> _processQueue() async {
    final queue = ref.read(editQueueServiceProvider);
    final api = ref.read(paperlessApiProvider);
    final edits = await queue.pending();

    for (final edit in edits) {
      try {
        await _applyEdit(api, edit);
        await queue.dequeue(edit.id);
      } catch (e) {
        debugPrint(
          'Failed to sync edit ${edit.field} on doc ${edit.documentId}: $e',
        );
        break; // Stop on first failure to preserve order
      }
    }
  }

  Future<void> _applyEdit(PaperlessApi api, PendingEdit edit) async {
    final data = <String, dynamic>{};
    switch (edit.field) {
      case 'title':
        data['title'] = edit.value;
      case 'correspondent':
        data['correspondent'] = int.tryParse(edit.value);
      case 'document_type':
        data['document_type'] = int.tryParse(edit.value);
      case 'storage_path':
        data['storage_path'] = int.tryParse(edit.value);
      default:
        data[edit.field] = edit.value;
    }
    await api.updateDocument(edit.documentId, data);
  }
}
