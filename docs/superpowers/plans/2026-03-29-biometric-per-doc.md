# Biometric Lock Per-Document Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Use TDD.

**Goal:** Let users mark specific documents as "sensitive" — opening them requires biometric authentication.

**Architecture:** Store locked document IDs in a local Drift table (not on the server — this is a client-side privacy feature). When navigating to a locked document's detail screen, intercept with a biometric prompt. The existing `BiometricService` handles the actual authentication. A toggle in the document detail popup menu lets users lock/unlock documents.

**Tech Stack:** Drift (local storage), existing `BiometricService`/`local_auth`, GoRouter redirect

---

## Task 1 — Locked documents Drift table + service (TDD)

**Files:**
- Modify: `lib/core/database/app_database.dart` — add `LockedDocuments` table
- Create: `lib/core/services/document_lock_service.dart`
- Create: `test/unit/services/document_lock_service_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/services/document_lock_service.dart';

void main() {
  group('DocumentLockService', () {
    // These test the pure logic; actual Drift tests need in-memory DB
    test('isLocked returns false for unknown doc', () async {
      final service = DocumentLockService.forTest({});
      expect(await service.isLocked(42), false);
    });

    test('isLocked returns true after locking', () async {
      final service = DocumentLockService.forTest({});
      await service.lock(42);
      expect(await service.isLocked(42), true);
    });

    test('unlock removes the lock', () async {
      final service = DocumentLockService.forTest({});
      await service.lock(42);
      await service.unlock(42);
      expect(await service.isLocked(42), false);
    });

    test('getLockedIds returns all locked IDs', () async {
      final service = DocumentLockService.forTest({});
      await service.lock(1);
      await service.lock(5);
      expect(await service.getLockedIds(), containsAll([1, 5]));
    });
  });
}
```

- [ ] **Step 2: Create service with in-memory test constructor**

```dart
class DocumentLockService {
  final Set<int> _lockedIds;
  // Real constructor uses Drift; test constructor uses in-memory Set
  DocumentLockService.forTest(Map<int, dynamic> _) : _lockedIds = {};

  Future<bool> isLocked(int docId) async => _lockedIds.contains(docId);
  Future<void> lock(int docId) async => _lockedIds.add(docId);
  Future<void> unlock(int docId) async => _lockedIds.remove(docId);
  Future<Set<int>> getLockedIds() async => Set.from(_lockedIds);
}
```

- [ ] **Step 3: Add `LockedDocuments` Drift table, bump schema, add Drift-backed constructor**

- [ ] **Step 4: Run tests, commit**

---

## Task 2 — Lock/unlock toggle in document detail

**Files:**
- Modify: `lib/features/documents/document_detail_screen.dart`

- [ ] **Step 1: Add lock/unlock popup menu item**

Check if document is locked, show appropriate icon/label:
```dart
PopupMenuItem(
  value: isLocked ? 'unlock_doc' : 'lock_doc',
  child: ListTile(
    leading: Icon(isLocked ? Icons.lock_open : Icons.lock_outline),
    title: Text(isLocked ? 'Remove Lock' : 'Lock Document'),
    dense: true,
    contentPadding: EdgeInsets.zero,
  ),
),
```

- [ ] **Step 2: Handle lock/unlock action**

```dart
case 'lock_doc':
  await lockService.lock(doc.id);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Document locked')),
  );
case 'unlock_doc':
  await lockService.unlock(doc.id);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Document unlocked')),
  );
```

- [ ] **Step 3: Run analysis and tests, commit**

---

## Task 3 — Biometric gate on document detail navigation

**Files:**
- Modify: `lib/features/documents/document_detail_screen.dart`

- [ ] **Step 1: Add biometric check at build time**

At the top of the document detail screen's build method, check if the document is locked and if biometric hasn't been verified for this session. If locked and not verified, show the biometric prompt overlay (reuse pattern from `LockScreen`).

- [ ] **Step 2: On successful auth, show document normally**

- [ ] **Step 3: Run analysis and tests, commit**
