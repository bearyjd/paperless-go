import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';

part 'edit_queue_service.g.dart';

class EditQueueService {
  final AppDatabase _db;
  EditQueueService(this._db);

  Future<List<PendingEdit>> pending() async {
    return (_db.select(_db.pendingEdits)
          ..orderBy([(t) => OrderingTerm.asc(t.queuedAt)]))
        .get();
  }

  Future<bool> hasPending() async {
    final count = await _db.select(_db.pendingEdits).get();
    return count.isNotEmpty;
  }

  Future<void> enqueue({
    required int documentId,
    required String field,
    required String value,
  }) async {
    // Coalesce: delete existing edit for same doc+field
    await (_db.delete(_db.pendingEdits)
          ..where(
            (t) => t.documentId.equals(documentId) & t.field.equals(field),
          ))
        .go();
    await _db.into(_db.pendingEdits).insert(
      PendingEditsCompanion.insert(
        documentId: documentId,
        field: field,
        value: value,
        queuedAt: DateTime.now(),
      ),
    );
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
