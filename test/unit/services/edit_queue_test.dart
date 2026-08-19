import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/services/edit_queue_service.dart';

void main() {
  group('EditQueueService', () {
    late AppDatabase db;
    late EditQueueService queue;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      queue = EditQueueService(db);
    });

    tearDown(() async => await db.close());

    test('starts empty', () async {
      expect(await queue.pending(), isEmpty);
    });

    test('enqueue adds edit', () async {
      await queue.enqueue(documentId: 1, field: 'title', value: 'Test');
      expect(await queue.pending(), hasLength(1));
    });

    test('coalesces duplicate field edits for same document', () async {
      await queue.enqueue(documentId: 1, field: 'title', value: 'First');
      await queue.enqueue(documentId: 1, field: 'title', value: 'Second');
      final edits = await queue.pending();
      expect(edits, hasLength(1));
      expect(edits.first.value, 'Second');
    });

    test('applies edits in the order they were made, not by wall clock',
        () async {
      // queuedAt comes from DateTime.now(), which is not monotonic: an NTP
      // correction, a manual date change, or a device booting with a reset RTC
      // moves it backwards. The processor applies this list in order and
      // breaks on first failure "to preserve order", so a reordered list lands
      // the wrong final value on the document.
      await queue.enqueue(documentId: 1, field: 'title', value: 'first');
      await queue.enqueue(documentId: 1, field: 'correspondent', value: '7');
      final rows = await queue.pending();

      // The clock ran backwards between the two enqueues, so the SECOND edit
      // carries the EARLIER timestamp.
      await (db.update(db.pendingEdits)
            ..where((t) => t.id.equals(rows.last.id)))
          .write(PendingEditsCompanion(
              queuedAt: Value(DateTime(2020, 1, 1))));

      final ordered = await queue.pending();
      expect(ordered.map((e) => e.value), ['first', '7'],
          reason: 'insertion order is the truth; the clock is not');
    });

    test('does not coalesce different fields', () async {
      await queue.enqueue(documentId: 1, field: 'title', value: 'Title');
      await queue.enqueue(documentId: 1, field: 'correspondent', value: '5');
      expect(await queue.pending(), hasLength(2));
    });

    test('does not coalesce different documents', () async {
      await queue.enqueue(documentId: 1, field: 'title', value: 'A');
      await queue.enqueue(documentId: 2, field: 'title', value: 'B');
      expect(await queue.pending(), hasLength(2));
    });

    test('dequeue removes specific edit', () async {
      await queue.enqueue(documentId: 1, field: 'title', value: 'Test');
      final edits = await queue.pending();
      await queue.dequeue(edits.first.id);
      expect(await queue.pending(), isEmpty);
    });

    test('hasPending returns true when edits exist', () async {
      expect(await queue.hasPending(), false);
      await queue.enqueue(documentId: 1, field: 'title', value: 'Test');
      expect(await queue.hasPending(), true);
    });
  });
}
