# Offline Write Queue Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Use TDD.

**Goal:** Queue document metadata edits (tag changes, correspondent assignment, title updates) when offline and automatically sync them when connectivity returns.

**Architecture:** A `PendingEdit` Drift table stores queued mutations with document ID, field name, and new value. An `EditQueueService` enqueues edits and processes them in order when online. The existing `ConnectivityNotifier` triggers queue processing on reconnect. Providers optimistically update local state immediately (so the UI reflects the change) and the queue syncs to the server in the background.

**Tech Stack:** Drift, Riverpod, existing `ConnectivityNotifier`, existing `PaperlessApi`

---

## Task 1 — PendingEdit Drift table + EditQueueService (TDD)

**Files:**
- Modify: `lib/core/database/app_database.dart` — add `PendingEdits` table
- Create: `lib/core/services/edit_queue_service.dart`
- Create: `test/unit/services/edit_queue_service_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/services/edit_queue_service.dart';

void main() {
  group('PendingEdit', () {
    test('creates with all fields', () {
      final edit = PendingEdit(
        documentId: 42,
        field: 'title',
        value: 'New Title',
        queuedAt: DateTime(2026, 3, 29),
      );
      expect(edit.documentId, 42);
      expect(edit.field, 'title');
      expect(edit.value, 'New Title');
    });
  });

  group('EditQueue', () {
    late EditQueue queue;

    setUp(() {
      queue = EditQueue.forTest();
    });

    test('starts empty', () async {
      expect(await queue.pending(), isEmpty);
    });

    test('enqueue adds edit', () async {
      await queue.enqueue(PendingEdit(
        documentId: 1,
        field: 'title',
        value: 'Test',
        queuedAt: DateTime.now(),
      ));
      expect(await queue.pending(), hasLength(1));
    });

    test('dequeue removes edit', () async {
      await queue.enqueue(PendingEdit(
        documentId: 1,
        field: 'title',
        value: 'Test',
        queuedAt: DateTime.now(),
      ));
      final edits = await queue.pending();
      await queue.dequeue(edits.first);
      expect(await queue.pending(), isEmpty);
    });

    test('coalesces duplicate field edits for same document', () async {
      await queue.enqueue(PendingEdit(
        documentId: 1,
        field: 'title',
        value: 'First',
        queuedAt: DateTime.now(),
      ));
      await queue.enqueue(PendingEdit(
        documentId: 1,
        field: 'title',
        value: 'Second',
        queuedAt: DateTime.now(),
      ));
      final edits = await queue.pending();
      expect(edits, hasLength(1));
      expect(edits.first.value, 'Second');
    });

    test('does not coalesce different fields', () async {
      await queue.enqueue(PendingEdit(
        documentId: 1,
        field: 'title',
        value: 'New Title',
        queuedAt: DateTime.now(),
      ));
      await queue.enqueue(PendingEdit(
        documentId: 1,
        field: 'correspondent',
        value: '5',
        queuedAt: DateTime.now(),
      ));
      expect(await queue.pending(), hasLength(2));
    });
  });
}
```

- [ ] **Step 2: Create PendingEdit model + EditQueue with in-memory test constructor**

```dart
class PendingEdit {
  final int? id; // Drift auto-increment
  final int documentId;
  final String field;
  final String value;
  final DateTime queuedAt;

  PendingEdit({this.id, required this.documentId, required this.field, required this.value, required this.queuedAt});
}

class EditQueue {
  final List<PendingEdit> _queue;

  EditQueue.forTest() : _queue = [];

  Future<List<PendingEdit>> pending() async => List.from(_queue);

  Future<void> enqueue(PendingEdit edit) async {
    // Coalesce: replace existing edit for same doc+field
    _queue.removeWhere((e) => e.documentId == edit.documentId && e.field == edit.field);
    _queue.add(edit);
  }

  Future<void> dequeue(PendingEdit edit) async {
    _queue.remove(edit);
  }
}
```

- [ ] **Step 3: Add Drift table, bump schema, create Drift-backed constructor**

- [ ] **Step 4: Run tests, commit**

---

## Task 2 — EditQueueProcessor (processes queue when online)

**Files:**
- Create: `lib/core/services/edit_queue_processor.dart`

- [ ] **Step 1: Create processor that watches connectivity**

```dart
class EditQueueProcessor {
  final EditQueue _queue;
  final PaperlessApi _api;

  Future<void> processQueue() async {
    final edits = await _queue.pending();
    for (final edit in edits) {
      try {
        await _applyEdit(edit);
        await _queue.dequeue(edit);
      } catch (e) {
        // Log and skip — will retry on next connectivity change
        debugPrint('Failed to sync edit ${edit.field} on doc ${edit.documentId}: $e');
        break; // Stop processing on first failure (preserve order)
      }
    }
  }

  Future<void> _applyEdit(PendingEdit edit) async {
    switch (edit.field) {
      case 'title':
        await _api.updateDocument(edit.documentId, {'title': edit.value});
      case 'correspondent':
        await _api.updateDocument(edit.documentId, {'correspondent': int.tryParse(edit.value)});
      case 'document_type':
        await _api.updateDocument(edit.documentId, {'document_type': int.tryParse(edit.value)});
      // Add more fields as needed
    }
  }
}
```

- [ ] **Step 2: Wire to ConnectivityNotifier — trigger processQueue on reconnect**

- [ ] **Step 3: Run tests, commit**

---

## Task 3 — Integrate with document editing UI

**Files:**
- Modify: `lib/features/documents/document_detail_screen.dart`

- [ ] **Step 1: When offline, enqueue edits instead of calling API directly**

Check connectivity before API calls. If offline, enqueue the edit and optimistically update the local UI state. Show a "Saved offline — will sync when connected" snackbar instead of the normal success snackbar.

- [ ] **Step 2: Show pending edit indicator**

If a document has pending edits in the queue, show a small sync icon or badge on the document detail screen.

- [ ] **Step 3: Run analysis and tests, commit**
