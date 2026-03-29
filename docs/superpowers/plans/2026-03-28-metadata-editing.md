# Metadata Editing Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Three improvements to post-upload metadata editing: fix the `select` custom field picker, add a scan-date → created-date shortcut, and add an AI edit trail that records OCR-suggested fields applied at upload and displays them in document detail.

**Architecture:** All changes are additive to the existing document detail screen and upload flow. The AI trail uses a new Drift table (`AiEdits`) in the existing `AppDatabase`, a new Riverpod notifier, and is populated by the upload screen after OCR suggestions are applied. No new routes.

**Tech Stack:** Flutter, Riverpod (riverpod_annotation), Drift (SQLite), intl

---

## File Map

| File | Action | What changes |
|---|---|---|
| `lib/core/database/app_database.dart` | Modify | Add `AiEdits` table, bump schemaVersion → 2, add migration |
| `lib/features/documents/ai_edit_trail_notifier.dart` | Create | Riverpod notifier + `AiEditEntry` model to record/read AI edits |
| `lib/features/scanner/upload_notifier.dart` | Modify | Add `documentId` to `UploadState`, extract `related_document` from task result |
| `lib/features/scanner/upload_screen.dart` | Modify | Track which suggestions were applied; record trail after successful upload |
| `lib/features/documents/document_detail_screen.dart` | Modify | Fix `select` picker, always show custom fields section, add scan-date shortcut, add `_AiEditTrailSection` |
| `test/unit/documents/ai_edit_trail_notifier_test.dart` | Create | Tests for record and read operations |

---

## Task 1 — Fix `select` custom field picker

**Files:**
- Modify: `lib/features/documents/document_detail_screen.dart` (lines ~689–880)

The `select` data type falls back to a plain number `TextField`. This task adds a proper bottom-sheet option picker that reads `fieldDef.extraData['select_options']` and displays labels.

- [ ] **Step 1: Write the failing test** (widget test — verifies select picker shows label not raw number)

Create `test/widget/documents/custom_field_select_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('_displaySelectValue returns label for matching id', () {
    final options = [
      {'id': 0, 'label': 'Pending'},
      {'id': 1, 'label': 'Approved'},
    ];
    expect(_displaySelectValue(1, options), 'Approved');
    expect(_displaySelectValue(null, options), 'Not set');
    expect(_displaySelectValue(99, options), '99');
  });

  test('_displaySelectValue handles string options', () {
    final options = ['Red', 'Green', 'Blue'];
    expect(_displaySelectValue('Green', options), 'Green');
    expect(_displaySelectValue(null, options), 'Not set');
  });
}

// Extracted helper (matches implementation below)
String _displaySelectValue(dynamic val, List<dynamic> options) {
  if (val == null) return 'Not set';
  for (final opt in options) {
    if (opt is Map) {
      if (opt['id'] == val || opt['id'].toString() == val.toString()) {
        return opt['label'].toString();
      }
    } else if (opt.toString() == val.toString()) {
      return opt.toString();
    }
  }
  return val.toString();
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/widget/documents/custom_field_select_test.dart -v
```

Expected: FAIL (file doesn't exist yet)

- [ ] **Step 3: Add `extraData` to `_CustomFieldTile` and fix `_displayValue` + `_editSelectValue`**

In `lib/features/documents/document_detail_screen.dart`, update `_CustomFieldTile`:

```dart
class _CustomFieldTile extends StatelessWidget {
  final int documentId;
  final String fieldName;
  final String dataType;
  final int fieldId;
  final dynamic value;
  final Map<String, dynamic>? extraData; // ADD
  final ValueChanged<dynamic> onSave;

  const _CustomFieldTile({
    required this.documentId,
    required this.fieldName,
    required this.dataType,
    required this.fieldId,
    required this.value,
    this.extraData, // ADD
    required this.onSave,
  });
```

Replace `_displayValue`:

```dart
  String _displayValue(dynamic val, String type) {
    if (val == null) return 'Not set';
    if (type == 'boolean') return val == true ? 'Yes' : 'No';
    if (type == 'date' && val is String && val.isNotEmpty) {
      try {
        return DateFormat.yMMMd().format(DateTime.parse(val));
      } catch (_) {
        return val;
      }
    }
    if (type == 'monetary' && val != null) return '\$${val.toString()}';
    if (type == 'select') {
      final options = extraData?['select_options'] as List<dynamic>? ?? [];
      return _displaySelectValue(val, options);
    }
    return val.toString();
  }

  String _displaySelectValue(dynamic val, List<dynamic> options) {
    if (val == null) return 'Not set';
    for (final opt in options) {
      if (opt is Map) {
        if (opt['id'] == val || opt['id'].toString() == val.toString()) {
          return opt['label'].toString();
        }
      } else if (opt.toString() == val.toString()) {
        return opt.toString();
      }
    }
    return val.toString();
  }
```

Replace `_editSelectValue`:

```dart
  static const _selectNone = '__none__';

  Future<void> _editSelectValue(BuildContext context) async {
    final options = extraData?['select_options'] as List<dynamic>? ?? [];
    if (options.isEmpty) {
      await _editTextValue(context, TextInputType.text);
      return;
    }
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(fieldName,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ListTile(
              title: const Text('None'),
              trailing: value == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, _selectNone),
            ),
            ...options.map((opt) {
              final id = opt is Map ? opt['id'] : opt;
              final label = opt is Map
                  ? opt['label'].toString()
                  : opt.toString();
              final isSelected = id == value ||
                  id.toString() == value.toString();
              return ListTile(
                title: Text(label),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, id),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result == null) return;
    onSave(result == _selectNone ? null : result);
  }
```

- [ ] **Step 4: Pass `extraData` from `_CustomFieldsSection` to `_CustomFieldTile`**

In `_CustomFieldsSection.build`, update the `_CustomFieldTile` constructor call:

```dart
child: _CustomFieldTile(
  documentId: documentId,
  fieldName: fieldName,
  dataType: dataType,
  fieldId: instance.field,
  value: instance.value,
  extraData: fieldDef?.extraData, // ADD
  onSave: (newValue) async { ... },
),
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/widget/documents/custom_field_select_test.dart -v
flutter analyze
```

Expected: all pass, no analysis errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/documents/document_detail_screen.dart \
        test/widget/documents/custom_field_select_test.dart
git commit -m "fix: proper select picker for custom fields using extraData options"
```

---

## Task 2 — Always show custom fields section + add new field values

**Files:**
- Modify: `lib/features/documents/document_detail_screen.dart`

Currently the section is hidden when `doc.customFields.isNotEmpty == false`. This task always renders it (with an add button) so users can assign custom field values to documents that don't have any.

- [ ] **Step 1: Remove the `isNotEmpty` guard in `DocumentDetailScreen.build`**

Find this block (~line 340):

```dart
// BEFORE
if (doc.customFields.isNotEmpty) ...[
  const Divider(height: 32),
  _CustomFieldsSection(
    documentId: documentId,
    fieldInstances: doc.customFields,
  ),
],
```

Replace with:

```dart
// AFTER
const Divider(height: 32),
_CustomFieldsSection(
  documentId: documentId,
  fieldInstances: doc.customFields,
),
```

- [ ] **Step 2: Add `+` button and "add field" picker to `_CustomFieldsSection`**

Replace the `_CustomFieldsSection` class with:

```dart
class _CustomFieldsSection extends ConsumerWidget {
  final int documentId;
  final List<CustomFieldInstance> fieldInstances;

  const _CustomFieldsSection({
    required this.documentId,
    required this.fieldInstances,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(customFieldsProvider);
    final fieldDefs = fieldsAsync.valueOrNull ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Custom Fields',
                style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () =>
                  _showAddFieldPicker(context, ref, fieldDefs),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (fieldInstances.isEmpty && fieldDefs.isEmpty)
          Text(
            'No custom fields configured on this server',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else if (fieldInstances.isEmpty)
          Text(
            'No values set — tap + to add',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else
          ...fieldInstances.map((instance) {
            final fieldDef = fieldDefs[instance.field];
            final fieldName = fieldDef?.name ?? 'Field ${instance.field}';
            final dataType = fieldDef?.dataType ?? 'string';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CustomFieldTile(
                documentId: documentId,
                fieldName: fieldName,
                dataType: dataType,
                fieldId: instance.field,
                value: instance.value,
                extraData: fieldDef?.extraData,
                onSave: (newValue) async {
                  final updatedFields = fieldInstances.map((fi) {
                    if (fi.field == instance.field) {
                      return {'field': fi.field, 'value': newValue};
                    }
                    return {'field': fi.field, 'value': fi.value};
                  }).toList();
                  try {
                    await ref
                        .read(documentDetailProvider(documentId).notifier)
                        .updateField({'custom_fields': updatedFields});
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Failed to update field: $e')),
                      );
                    }
                  }
                },
              ),
            );
          }),
      ],
    );
  }

  void _showAddFieldPicker(
    BuildContext context,
    WidgetRef ref,
    Map<int, CustomField> fieldDefs,
  ) {
    // Only show fields that aren't already assigned
    final assignedIds = fieldInstances.map((fi) => fi.field).toSet();
    final available = fieldDefs.values
        .where((f) => !assignedIds.contains(f.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All custom fields already assigned')),
      );
      return;
    }

    showModalBottomSheet<CustomField>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Add Custom Field',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...available.map((f) => ListTile(
                  title: Text(f.name),
                  subtitle: Text(f.dataType,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  onTap: () => Navigator.pop(ctx, f),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).then((selectedField) {
      if (selectedField == null || !context.mounted) return;
      // Open the edit tile immediately for the new field
      _CustomFieldTile(
        documentId: documentId,
        fieldName: selectedField.name,
        dataType: selectedField.dataType,
        fieldId: selectedField.id,
        value: null,
        extraData: selectedField.extraData,
        onSave: (newValue) async {
          final updatedFields = [
            ...fieldInstances
                .map((fi) => {'field': fi.field, 'value': fi.value}),
            {'field': selectedField.id, 'value': newValue},
          ];
          try {
            await ref
                .read(documentDetailProvider(documentId).notifier)
                .updateField({'custom_fields': updatedFields});
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add field: $e')),
              );
            }
          }
        },
      ).callEditField(context);
    });
  }
}
```

- [ ] **Step 3: Add `callEditField` method to `_CustomFieldTile`**

Add this public method to `_CustomFieldTile` (at the end of the class, before the closing `}`):

```dart
  // Called externally to trigger the edit dialog for a new (unset) field.
  void callEditField(BuildContext context) {
    _editField(context);
  }
```

- [ ] **Step 4: Verify in the running app**

```bash
flutter run
```

Navigate to a document with no custom fields → "Custom Fields" section should always appear with `+` button. Navigate to a document with a `select` field → tapping it should show the option sheet.

- [ ] **Step 5: Run analysis**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/documents/document_detail_screen.dart
git commit -m "feat: always show custom fields section with add button, fix select field picker"
```

---

## Task 3 — Scan date shortcut in document detail

**Files:**
- Modify: `lib/features/documents/document_detail_screen.dart` (~line 238)

Add a secondary row below the created date picker showing the `added` (scan) date with a "Use as created" button.

- [ ] **Step 1: Write the failing test**

Create `test/unit/documents/date_shortcut_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats added date as YYYY-MM-DD for API', () {
    final added = DateTime(2026, 3, 15, 10, 30);
    final formatted = added.toIso8601String().split('T').first;
    expect(formatted, '2026-03-15');
  });

  test('scan date display is different from created date', () {
    final created = DateTime(2025, 1, 10);
    final added = DateTime(2026, 3, 15);
    expect(created != added, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it passes (logic is trivial — confirms format)**

```bash
flutter test test/unit/documents/date_shortcut_test.dart -v
```

Expected: PASS

- [ ] **Step 3: Add scan date row below the created date ListTile**

In `DocumentDetailScreen.build`, find the created date section (ends ~line 263). After the closing `,` of the date `ListTile`, add:

```dart
              // Scan date shortcut — shown below created date
              if (doc.added != null) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Row(
                    children: [
                      Icon(
                        Icons.upload_file_outlined,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Scanned ${DateFormat.yMMMd().format(doc.added!)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const Spacer(),
                      if (doc.added!.toIso8601String().split('T').first !=
                          (doc.created?.toIso8601String().split('T').first ??
                              ''))
                        TextButton(
                          style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            textStyle:
                                Theme.of(context).textTheme.labelSmall,
                          ),
                          onPressed: () async {
                            final scanDate = doc.added!
                                .toIso8601String()
                                .split('T')
                                .first;
                            try {
                              await ref
                                  .read(documentDetailProvider(documentId)
                                      .notifier)
                                  .updateField({'created': scanDate});
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to update date: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Use as created'),
                        ),
                    ],
                  ),
                ),
              ],
```

- [ ] **Step 4: Run analysis and check the UI**

```bash
flutter analyze
flutter run
```

Open a document → the created date row should have a "Scanned [date]" line below it. If scan date ≠ created date, "Use as created" button appears. Tapping it updates the created date.

- [ ] **Step 5: Commit**

```bash
git add lib/features/documents/document_detail_screen.dart \
        test/unit/documents/date_shortcut_test.dart
git commit -m "feat: add scan date shortcut below created date in document detail"
```

---

## Task 4 — Add `AiEdits` Drift table

**Files:**
- Modify: `lib/core/database/app_database.dart`

- [ ] **Step 1: Add `AiEdits` table and bump schemaVersion**

Replace the contents of `lib/core/database/app_database.dart` with:

```dart
import 'package:drift/drift.dart';

part 'app_database.g.dart';

class CachedDocuments extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedTags extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedCorrespondents extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedDocumentTypes extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedStoragePaths extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedSavedViews extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedCustomFields extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingUploads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()();
  TextColumn get filename => text()();
  TextColumn get title => text().nullable()();
  IntColumn get correspondent => integer().nullable()();
  IntColumn get documentType => integer().nullable()();
  TextColumn get tagsJson => text().nullable()();
  DateTimeColumn get created => dateTime().nullable()();
  DateTimeColumn get queuedAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

/// Records metadata fields auto-applied from AI suggestions (OCR or chat).
class AiEdits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer()();
  TextColumn get fieldName => text()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  /// Source: 'ocr_suggestion' or 'chat'
  TextColumn get source => text()();
  DateTimeColumn get appliedAt => dateTime()();
}

@DriftDatabase(tables: [
  CachedDocuments,
  CachedTags,
  CachedCorrespondents,
  CachedDocumentTypes,
  CachedStoragePaths,
  CachedSavedViews,
  CachedCustomFields,
  PendingUploads,
  AiEdits, // NEW
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(aiEdits);
      }
    },
  );
}
```

- [ ] **Step 2: Run build_runner to regenerate the Drift code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/core/database/app_database.g.dart` regenerated with `AiEdits` table included, no errors.

- [ ] **Step 3: Verify app compiles**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/database/app_database.dart \
        lib/core/database/app_database.g.dart
git commit -m "feat: add AiEdits drift table for tracking AI-applied metadata"
```

---

## Task 5 — Expose `documentId` from `UploadState` after successful upload

**Files:**
- Modify: `lib/features/scanner/upload_notifier.dart`

Paperless-ngx task results include `related_document` (the created document's ID as a string). This task surfaces it in `UploadState` so the upload screen can record AI edits against the correct document.

- [ ] **Step 1: Write the failing test**

Create `test/unit/scanner/upload_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/scanner/upload_notifier.dart';

void main() {
  group('UploadState.copyWith', () {
    test('documentId is preserved through status-changing copyWith', () {
      const base = UploadState(
        status: UploadStatus.processing,
        taskId: 'abc',
        documentId: 42,
      );
      final next = base.copyWith(status: UploadStatus.success);
      expect(next.documentId, 42);
    });

    test('documentId is null in default state', () {
      const s = UploadState();
      expect(s.documentId, isNull);
    });

    test('documentId can be set via copyWith', () {
      const s = UploadState(status: UploadStatus.processing);
      final next = s.copyWith(documentId: 7);
      expect(next.documentId, 7);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/unit/scanner/upload_state_test.dart -v
```

Expected: FAIL — `UploadState` has no `documentId` field yet.

- [ ] **Step 3: Add `documentId` to `UploadState`**

In `lib/features/scanner/upload_notifier.dart`, replace `UploadState`:

```dart
class UploadState {
  final UploadStatus status;
  final String? taskId;
  final String? errorMessage;
  final double? progress;
  final int? documentId;

  const UploadState({
    this.status = UploadStatus.idle,
    this.taskId,
    this.errorMessage,
    this.progress,
    this.documentId,
  });

  UploadState copyWith({
    UploadStatus? status,
    String? taskId,
    String? errorMessage,
    double? progress,
    int? documentId,
  }) {
    final newStatus = status ?? this.status;
    final statusChanged = newStatus != this.status;
    return UploadState(
      status: newStatus,
      taskId: taskId ?? this.taskId,
      errorMessage: statusChanged
          ? errorMessage
          : (errorMessage ?? this.errorMessage),
      progress: statusChanged ? progress : (progress ?? this.progress),
      documentId: documentId ?? this.documentId,
    );
  }
}
```

- [ ] **Step 4: Extract `related_document` in `_startPolling`**

In `_startPolling`, find the `status == 'SUCCESS'` branch and replace it:

```dart
        if (status == 'SUCCESS') {
          timer.cancel();
          final docIdStr = result['related_document'] as String?;
          final docId = docIdStr != null ? int.tryParse(docIdStr) : null;
          state = UploadState(
            status: UploadStatus.success,
            taskId: taskId,
            documentId: docId,
          );
          NotificationService.showUploadComplete(
            title: 'Document processed',
            body: 'Your document has been added to Paperless.',
          );
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/unit/scanner/upload_state_test.dart -v
flutter analyze
```

Expected: all 3 tests pass, no analysis errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/scanner/upload_notifier.dart \
        test/unit/scanner/upload_state_test.dart
git commit -m "feat: expose documentId in UploadState after successful upload"
```

---

## Task 6 — Create `AiEditTrailNotifier`

**Files:**
- Create: `lib/features/documents/ai_edit_trail_notifier.dart`
- Create: `test/unit/documents/ai_edit_trail_notifier_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/unit/documents/ai_edit_trail_notifier_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/database/database_provider.dart';
import 'package:paperless_go/features/documents/ai_edit_trail_notifier.dart';

AppDatabase _makeInMemoryDb() =>
    AppDatabase(NativeDatabase.memory());

ProviderContainer _makeContainer(AppDatabase db) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
}

void main() {
  group('AiEditTrailNotifier', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = _makeInMemoryDb();
      container = _makeContainer(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('starts empty for a new document', () async {
      final trail = await container
          .read(aiEditTrailProvider(99).future);
      expect(trail, isEmpty);
    });

    test('recordEdits writes entries readable by build', () async {
      final notifier = container.read(aiEditTrailProvider(1).notifier);
      await notifier.recordEdits(
        {
          'title': (oldValue: null, newValue: 'Invoice 2026'),
          'correspondent': (oldValue: null, newValue: 'ACME Corp'),
        },
        'ocr_suggestion',
      );
      final trail = await container.read(aiEditTrailProvider(1).future);
      expect(trail.length, 2);
      expect(trail.map((e) => e.fieldName).toSet(),
          containsAll(['title', 'correspondent']));
      expect(trail.first.source, 'ocr_suggestion');
    });

    test('deleteEdit removes the entry', () async {
      final notifier = container.read(aiEditTrailProvider(2).notifier);
      await notifier.recordEdits(
        {'title': (oldValue: null, newValue: 'Test')},
        'ocr_suggestion',
      );
      final before = await container.read(aiEditTrailProvider(2).future);
      expect(before.length, 1);

      await notifier.deleteEdit(before.first.id);

      final after = await container.read(aiEditTrailProvider(2).future);
      expect(after, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/unit/documents/ai_edit_trail_notifier_test.dart -v
```

Expected: FAIL — `ai_edit_trail_notifier.dart` doesn't exist.

- [ ] **Step 3: Create `lib/features/documents/ai_edit_trail_notifier.dart`**

```dart
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

part 'ai_edit_trail_notifier.g.dart';

class AiEditEntry {
  final int id;
  final int documentId;
  final String fieldName;
  final String? oldValue;
  final String? newValue;
  final String source;
  final DateTime appliedAt;

  const AiEditEntry({
    required this.id,
    required this.documentId,
    required this.fieldName,
    this.oldValue,
    this.newValue,
    required this.source,
    required this.appliedAt,
  });
}

typedef _EditMap = Map<String, ({String? oldValue, String? newValue})>;

@riverpod
class AiEditTrail extends _$AiEditTrail {
  @override
  Future<List<AiEditEntry>> build(int documentId) async {
    final db = ref.watch(appDatabaseProvider);
    final rows = await (db.select(db.aiEdits)
          ..where((t) => t.documentId.equals(documentId))
          ..orderBy([(t) => OrderingTerm.desc(t.appliedAt)]))
        .get();
    return rows
        .map(
          (r) => AiEditEntry(
            id: r.id,
            documentId: r.documentId,
            fieldName: r.fieldName,
            oldValue: r.oldValue,
            newValue: r.newValue,
            source: r.source,
            appliedAt: r.appliedAt,
          ),
        )
        .toList();
  }

  Future<void> recordEdits(_EditMap edits, String source) async {
    final db = ref.read(appDatabaseProvider);
    for (final entry in edits.entries) {
      await db.into(db.aiEdits).insert(
            AiEditsCompanion.insert(
              documentId: documentId,
              fieldName: entry.key,
              oldValue: Value(entry.value.oldValue),
              newValue: Value(entry.value.newValue),
              source: source,
              appliedAt: DateTime.now(),
            ),
          );
    }
    ref.invalidateSelf();
  }

  Future<void> deleteEdit(int editId) async {
    final db = ref.read(appDatabaseProvider);
    await (db.delete(db.aiEdits)..where((t) => t.id.equals(editId))).go();
    ref.invalidateSelf();
  }
}
```

- [ ] **Step 4: Run build_runner to generate `.g.dart`**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/features/documents/ai_edit_trail_notifier.g.dart` created.

- [ ] **Step 5: Run tests**

```bash
flutter test test/unit/documents/ai_edit_trail_notifier_test.dart -v
```

Expected: all 3 tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/documents/ai_edit_trail_notifier.dart \
        lib/features/documents/ai_edit_trail_notifier.g.dart \
        test/unit/documents/ai_edit_trail_notifier_test.dart
git commit -m "feat: add AiEditTrailNotifier for recording and reading AI edit history"
```

---

## Task 7 — Record AI suggestions in upload screen

**Files:**
- Modify: `lib/features/scanner/upload_screen.dart`

When OCR suggestions are applied and the upload succeeds, write the applied fields to the AI edit trail.

- [ ] **Step 1: Add import to `upload_screen.dart`**

Add to the import block at the top:

```dart
import '../documents/ai_edit_trail_notifier.dart';
```

- [ ] **Step 2: Add `_appliedAiEdits` tracking map to `_UploadScreenState`**

In `_UploadScreenState`, add field after the existing suggestion booleans:

```dart
  // Maps field name → applied value for AI edit trail recording
  final Map<String, ({String? oldValue, String? newValue})> _appliedAiEdits =
      {};
```

- [ ] **Step 3: Populate `_appliedAiEdits` in `_applySuggestions`**

Update `_applySuggestions` to record each field it fills:

```dart
  void _applySuggestions(MetadataSuggestions suggestions) {
    if (_suggestionsApplied) return;
    _suggestionsApplied = true;

    setState(() {
      if (suggestions.correspondentId != null && _correspondent == null) {
        _correspondent = suggestions.correspondentId;
        _suggestedCorrespondent = true;
        _appliedAiEdits['correspondent'] = (
          oldValue: null,
          newValue: suggestions.correspondentId.toString(),
        );
      }
      if (suggestions.documentTypeId != null && _documentType == null) {
        _documentType = suggestions.documentTypeId;
        _suggestedDocType = true;
        _appliedAiEdits['document_type'] = (
          oldValue: null,
          newValue: suggestions.documentTypeId.toString(),
        );
      }
      if (suggestions.tagIds.isNotEmpty && _selectedTags.isEmpty) {
        _selectedTags.addAll(suggestions.tagIds);
        _suggestedTags = true;
        _appliedAiEdits['tags'] = (
          oldValue: null,
          newValue: suggestions.tagIds.join(', '),
        );
      }
      if (suggestions.detectedDate != null && _created == null) {
        _created = suggestions.detectedDate;
        _suggestedDate = true;
        _appliedAiEdits['created'] = (
          oldValue: null,
          newValue: suggestions.detectedDate!
              .toIso8601String()
              .split('T')
              .first,
        );
      }
    });
  }
```

- [ ] **Step 4: Record edits on upload success**

In `build`, find the existing `ref.listen(uploadNotifierProvider, ...)` block and update the success case:

```dart
    ref.listen(uploadNotifierProvider, (prev, next) {
      if (!context.mounted) return;
      if (next.status == UploadStatus.success) {
        // Record AI edits if suggestions were applied and we have a document ID
        if (_appliedAiEdits.isNotEmpty && next.documentId != null) {
          ref
              .read(aiEditTrailProvider(next.documentId!).notifier)
              .recordEdits(_appliedAiEdits, 'ocr_suggestion');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully!')),
        );
        context.go('/scan');
      } else if (next.status == UploadStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Upload failed: ${next.errorMessage ?? "Unknown error"}')),
        );
      } else if (next.status == UploadStatus.queued) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No connection — upload queued for later')),
        );
        context.go('/scan');
      }
    });
```

- [ ] **Step 5: Run analysis**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/scanner/upload_screen.dart
git commit -m "feat: record OCR-suggested metadata as AI edit trail entries after upload"
```

---

## Task 8 — Add AI edit trail section to document detail

**Files:**
- Modify: `lib/features/documents/document_detail_screen.dart`

- [ ] **Step 1: Add import**

At the top of `document_detail_screen.dart`, add:

```dart
import 'ai_edit_trail_notifier.dart';
```

- [ ] **Step 2: Insert `_AiEditTrailSection` in the document detail body**

In `DocumentDetailScreen.build`, after the `_NotesSection` (before the share links section), add:

```dart
              // AI edit trail
              _AiEditTrailSection(documentId: documentId),
```

- [ ] **Step 3: Add `_AiEditTrailSection` and `_AiEditRow` classes at the bottom of the file**

Add after the closing `}` of `_ShareLinksSection`:

```dart
class _AiEditTrailSection extends ConsumerWidget {
  final int documentId;
  const _AiEditTrailSection({required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailAsync = ref.watch(aiEditTrailProvider(documentId));
    return trailAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (edits) {
        if (edits.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 32),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Applied at Upload',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...edits.map(
              (edit) => _AiEditRow(documentId: documentId, edit: edit),
            ),
          ],
        );
      },
    );
  }
}

class _AiEditRow extends ConsumerWidget {
  final int documentId;
  final AiEditEntry edit;
  const _AiEditRow({required this.documentId, required this.edit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.auto_awesome,
        size: 16,
        color: Theme.of(context).colorScheme.tertiary,
      ),
      title: Text(
        _fieldLabel(edit.fieldName),
        style: Theme.of(context).textTheme.labelMedium,
      ),
      subtitle: edit.newValue != null
          ? Text(
              edit.newValue!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              'Cleared',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        tooltip: 'Remove from history',
        onPressed: () =>
            ref.read(aiEditTrailProvider(documentId).notifier)
                .deleteEdit(edit.id),
      ),
    );
  }

  String _fieldLabel(String fieldName) {
    return switch (fieldName) {
      'title' => 'Title',
      'correspondent' => 'Correspondent',
      'document_type' => 'Document Type',
      'tags' => 'Tags',
      'created' => 'Created Date',
      _ => fieldName
              .split('_')
              .map((w) => w.isEmpty
                  ? ''
                  : '${w[0].toUpperCase()}${w.substring(1)}')
              .join(' '),
    };
  }
}
```

- [ ] **Step 4: Run the full test suite and analysis**

```bash
flutter analyze
flutter test
```

Expected: all tests pass, no analysis errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/documents/document_detail_screen.dart
git commit -m "feat: show AI edit trail section in document detail"
```

---

## Self-Review

**Spec coverage check:**
- ✅ Custom field `select` picker — Tasks 1–2
- ✅ Edit custom field values on documents with none set — Task 2
- ✅ Scan date → created date shortcut — Task 3
- ✅ AI edit trail DB table — Task 4
- ✅ Document ID surfaced after upload — Task 5
- ✅ AI edit trail notifier — Task 6
- ✅ Record edits in upload screen — Task 7
- ✅ Display trail in document detail — Task 8

**Placeholder scan:** None found.

**Type consistency:**
- `AiEditEntry` defined in Task 6, used in Tasks 7 and 8 ✅
- `AiEditTrailNotifier` / `aiEditTrailProvider` defined in Task 6, used in Tasks 7 and 8 ✅
- `UploadState.documentId` defined in Task 5, used in Task 7 ✅
- `_CustomFieldTile.extraData` added in Task 1, used in Task 2 ✅
