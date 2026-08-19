import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';

part 'edit_queue_service.g.dart';

class EditQueueService {
  final AppDatabase _db;
  EditQueueService(this._db);

  /// Queued edits in the order they were made.
  ///
  /// Ordered by `id`, not `queuedAt`. The processor applies this list in
  /// sequence and stops at the first failure specifically to preserve order,
  /// so the ordering is load-bearing: get it wrong and the document ends up
  /// with the value of an edit the user made earlier.
  ///
  /// `queuedAt` comes from [DateTime.now], which is not monotonic — an NTP
  /// correction, a manual date change, or a device booting with a reset RTC
  /// moves it backwards, and the newer edit then sorts first. `id` is
  /// autoIncrement and cannot go backwards. Same fix as the upload queue's
  /// `getPendingUploads`.
  Future<List<PendingEdit>> pending() async {
    return (_db.select(_db.pendingEdits)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<bool> hasPending() async {
    final query = _db.select(_db.pendingEdits)..limit(1);
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<void> enqueue({
    required int documentId,
    required String field,
    required String value,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.pendingEdits)
            ..where((t) => t.documentId.equals(documentId) & t.field.equals(field)))
          .go();
      await _db.into(_db.pendingEdits).insert(
        PendingEditsCompanion.insert(
          documentId: documentId,
          field: field,
          value: value,
          queuedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> dequeue(int id) async {
    await (_db.delete(_db.pendingEdits)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearAll() async {
    await _db.delete(_db.pendingEdits).go();
  }
}

@Riverpod(keepAlive: true)
EditQueueService editQueueService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return EditQueueService(db);
}
