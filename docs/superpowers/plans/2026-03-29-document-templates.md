# Document Templates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Use TDD.

**Goal:** Let users save and apply metadata templates (correspondent, document type, tags, storage path) to quickly pre-fill the upload screen for common document types.

**Architecture:** Templates are stored locally in Drift (not on the server). A `DocumentTemplate` model holds the metadata fields. The upload screen gets a "Use template" button that pre-fills fields. Templates are managed from a settings-like screen accessible from the upload screen.

**Tech Stack:** Drift, Riverpod, existing upload screen metadata fields

---

## Task 1 — DocumentTemplate model + Drift table (TDD)

**Files:**
- Create: `lib/core/models/document_template.dart`
- Modify: `lib/core/database/app_database.dart` — add `DocumentTemplates` table
- Create: `lib/core/services/template_service.dart`
- Create: `test/unit/services/template_service_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/document_template.dart';

void main() {
  group('DocumentTemplate', () {
    test('creates with all fields', () {
      final template = DocumentTemplate(
        id: 1,
        name: 'Invoice',
        correspondentId: 5,
        documentTypeId: 3,
        tagIds: [1, 2],
        storagePathId: null,
      );
      expect(template.name, 'Invoice');
      expect(template.tagIds, [1, 2]);
    });

    test('serializes to JSON and back', () {
      final template = DocumentTemplate(
        id: 1,
        name: 'Receipt',
        correspondentId: null,
        documentTypeId: 7,
        tagIds: [],
        storagePathId: 2,
      );
      final json = template.toJson();
      final restored = DocumentTemplate.fromJson(json);
      expect(restored.name, template.name);
      expect(restored.documentTypeId, template.documentTypeId);
      expect(restored.storagePathId, template.storagePathId);
    });
  });
}
```

- [ ] **Step 2: Create model, Drift table, service**

The `DocumentTemplate` model (freezed):
```dart
@freezed
class DocumentTemplate with _$DocumentTemplate {
  const factory DocumentTemplate({
    required int id,
    required String name,
    int? correspondentId,
    int? documentTypeId,
    @Default([]) List<int> tagIds,
    int? storagePathId,
  }) = _DocumentTemplate;

  factory DocumentTemplate.fromJson(Map<String, dynamic> json) =>
      _$DocumentTemplateFromJson(json);
}
```

Drift table stores JSON per template (same pattern as cached entities).

- [ ] **Step 3: Run tests, commit**

---

## Task 2 — Template picker in upload screen

**Files:**
- Modify: `lib/features/scanner/upload_screen.dart`

- [ ] **Step 1: Add "Use template" button above metadata fields**

A `DropdownButton<DocumentTemplate>` or an `IconButton` that shows a bottom sheet with template list. On selection, pre-fill correspondent, document type, tags, and storage path fields.

- [ ] **Step 2: Add "Save as template" button**

After filling metadata, user can tap "Save as template" to persist the current metadata as a new template. Shows a name dialog.

- [ ] **Step 3: Run analysis and tests, commit**

---

## Task 3 — Template management screen

**Files:**
- Create: `lib/features/templates/templates_screen.dart`
- Modify: `lib/app.dart` — add `/templates` route
- Modify: `lib/features/settings/settings_screen.dart` — add link

- [ ] **Step 1: Create list screen with create/edit/delete (follows CustomFieldsScreen pattern)**

- [ ] **Step 2: Wire navigation**

- [ ] **Step 3: Run analysis and tests, commit**
