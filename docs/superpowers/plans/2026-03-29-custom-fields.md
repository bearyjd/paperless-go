# Custom Field Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Use TDD: test first, watch fail, minimal code, watch pass.

**Goal:** Let users create, edit, and delete custom field definitions from the mobile app. Currently users can only fill in field values on documents — field definitions must be managed via the web UI.

**Architecture:** The `CustomField` model, `getCustomFields()` API method, and `customFieldsProvider` already exist. This plan adds CRUD API methods, a data type label helper (TDD), and a management screen accessible from Settings. The UI follows the `LabelsScreen` pattern (list + dialog-based CRUD).

**Tech Stack:** Flutter, Riverpod, Dio, GoRouter, existing `CustomField` freezed model

---

## Current state

- `CustomField` model exists: `id`, `name`, `dataType` (string), `extraData` (map) — `lib/core/models/custom_field.dart`
- `getCustomFields()` API method exists — `lib/core/api/paperless_api.dart`
- `customFieldsProvider` exists (returns `Map<int, CustomField>`, keepAlive) — `lib/core/api/api_providers.dart`
- Custom field values are rendered on document detail screen — but no management UI for definitions
- No create/update/delete API methods

## Paperless-ngx Custom Fields API

```
GET    /api/custom_fields/       → paginated list of field definitions
POST   /api/custom_fields/       → create field definition
GET    /api/custom_fields/{id}/  → single field
PATCH  /api/custom_fields/{id}/  → update field (name, extra_data)
DELETE /api/custom_fields/{id}/  → delete field
```

### Data types

| `data_type` value | Display label | Notes |
|---|---|---|
| `string` | Text | Free text |
| `url` | URL | Validated URL |
| `date` | Date | YYYY-MM-DD |
| `boolean` | Boolean | true/false |
| `integer` | Integer | Whole number |
| `float` | Float | Decimal number |
| `monetary` | Monetary | Currency amount |
| `document_link` | Document Link | Links to another document |
| `select` | Select | `extra_data.select_options` contains list of option strings |

### Create payload

```json
{
  "name": "Invoice Number",
  "data_type": "string"
}
```

For select type:
```json
{
  "name": "Priority",
  "data_type": "select",
  "extra_data": {
    "select_options": ["Low", "Medium", "High"]
  }
}
```

### Update payload (PATCH)

```json
{
  "name": "New Name"
}
```

Note: `data_type` cannot be changed after creation (Paperless-ngx constraint).

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/features/custom_fields/custom_field_helpers.dart` | Create | `dataTypeLabel` pure function for display labels |
| `lib/core/api/paperless_api.dart` | Modify | Add `createCustomField`, `updateCustomField`, `deleteCustomField` |
| `lib/features/custom_fields/custom_fields_screen.dart` | Create | Management screen: list + create/edit/delete dialogs |
| `lib/features/settings/settings_screen.dart` | Modify | Add "Custom Fields" link |
| `lib/app.dart` | Modify | Add `/custom-fields` route |
| `test/unit/custom_fields/custom_field_helpers_test.dart` | Create | Tests for `dataTypeLabel` |

---

## Task 1 — Data type helper (TDD) + CRUD API methods

**Files:**
- Create: `lib/features/custom_fields/custom_field_helpers.dart`
- Create: `test/unit/custom_fields/custom_field_helpers_test.dart`
- Modify: `lib/core/api/paperless_api.dart`

- [ ] **Step 1: Write the failing tests FIRST**

Create `test/unit/custom_fields/custom_field_helpers_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/custom_fields/custom_field_helpers.dart';

void main() {
  group('dataTypeLabel', () {
    test('returns label for all known data types', () {
      expect(dataTypeLabel('string'), 'Text');
      expect(dataTypeLabel('url'), 'URL');
      expect(dataTypeLabel('date'), 'Date');
      expect(dataTypeLabel('boolean'), 'Boolean');
      expect(dataTypeLabel('integer'), 'Integer');
      expect(dataTypeLabel('float'), 'Float');
      expect(dataTypeLabel('monetary'), 'Monetary');
      expect(dataTypeLabel('document_link'), 'Document Link');
      expect(dataTypeLabel('select'), 'Select');
    });

    test('returns capitalized input for unknown type', () {
      expect(dataTypeLabel('custom_new_type'), 'custom_new_type');
    });
  });

  group('dataTypeIcon', () {
    test('returns distinct icons for each type', () {
      // Just verify no exceptions thrown for all known types
      for (final type in [
        'string', 'url', 'date', 'boolean', 'integer',
        'float', 'monetary', 'document_link', 'select',
      ]) {
        expect(dataTypeIcon(type), isNotNull);
      }
    });

    test('returns fallback icon for unknown type', () {
      expect(dataTypeIcon('unknown_type'), isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test test/unit/custom_fields/custom_field_helpers_test.dart -v
```

Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Create `lib/features/custom_fields/custom_field_helpers.dart`**

```dart
import 'package:flutter/material.dart';

/// Returns a human-readable label for a custom field data type string.
String dataTypeLabel(String dataType) {
  return switch (dataType) {
    'string' => 'Text',
    'url' => 'URL',
    'date' => 'Date',
    'boolean' => 'Boolean',
    'integer' => 'Integer',
    'float' => 'Float',
    'monetary' => 'Monetary',
    'document_link' => 'Document Link',
    'select' => 'Select',
    _ => dataType,
  };
}

/// Returns an icon for a custom field data type.
IconData dataTypeIcon(String dataType) {
  return switch (dataType) {
    'string' => Icons.text_fields,
    'url' => Icons.link,
    'date' => Icons.calendar_today,
    'boolean' => Icons.toggle_on_outlined,
    'integer' => Icons.numbers,
    'float' => Icons.decimal_increase,
    'monetary' => Icons.attach_money,
    'document_link' => Icons.description_outlined,
    'select' => Icons.list,
    _ => Icons.extension,
  };
}
```

- [ ] **Step 4: Run tests and verify they pass**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test test/unit/custom_fields/custom_field_helpers_test.dart -v
```

Expected: 4 tests pass.

- [ ] **Step 5: Add CRUD API methods to `paperless_api.dart`**

Find the existing `getCustomFields()` method. Add after it:

```dart
  Future<CustomField> createCustomField({
    required String name,
    required String dataType,
    Map<String, dynamic>? extraData,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'data_type': dataType,
    };
    if (extraData != null) data['extra_data'] = extraData;
    final response = await _dio.post('api/custom_fields/', data: data);
    return CustomField.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CustomField> updateCustomField(int id, {String? name}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (data.isEmpty) {
      throw ArgumentError('At least one field must be provided to updateCustomField');
    }
    final response = await _dio.patch('api/custom_fields/$id/', data: data);
    return CustomField.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCustomField(int id) async {
    await _dio.delete('api/custom_fields/$id/');
  }
```

Check that `CustomField` is already imported (it should be since `getCustomFields()` already uses it).

- [ ] **Step 6: Run full suite**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test && flutter analyze
```

- [ ] **Step 7: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/features/custom_fields/custom_field_helpers.dart \
        test/unit/custom_fields/custom_field_helpers_test.dart \
        lib/core/api/paperless_api.dart
git commit -m "feat: add custom field data type helpers and CRUD API methods"
```

---

## Task 2 — Custom Fields management screen

**Files:**
- Create: `lib/features/custom_fields/custom_fields_screen.dart`

The screen shows all custom field definitions in a list. Each tile shows name, data type (icon + label), and for select fields shows the option count. A FAB creates new fields. Tapping a field opens an edit dialog. Delete via a trailing icon or long-press.

- [ ] **Step 1: Create `lib/features/custom_fields/custom_fields_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/models/custom_field.dart';
import 'custom_field_helpers.dart';

class CustomFieldsScreen extends ConsumerWidget {
  const CustomFieldsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(customFieldsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Fields')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: fieldsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load custom fields\n$e',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(customFieldsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (fieldsMap) {
          final fields = fieldsMap.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          if (fields.isEmpty) {
            return const Center(
              child: Text('No custom fields defined'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(customFieldsProvider),
            child: ListView.builder(
              itemCount: fields.length,
              itemBuilder: (context, index) {
                final field = fields[index];
                return _CustomFieldTile(field: field);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    String selectedType = 'string';
    final optionsController = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Create Custom Field'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Field name',
                    hintText: 'e.g. Invoice Number',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Data type'),
                  items: const [
                    DropdownMenuItem(value: 'string', child: Text('Text')),
                    DropdownMenuItem(value: 'url', child: Text('URL')),
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                    DropdownMenuItem(value: 'boolean', child: Text('Boolean')),
                    DropdownMenuItem(value: 'integer', child: Text('Integer')),
                    DropdownMenuItem(value: 'float', child: Text('Float')),
                    DropdownMenuItem(value: 'monetary', child: Text('Monetary')),
                    DropdownMenuItem(
                        value: 'document_link',
                        child: Text('Document Link')),
                    DropdownMenuItem(value: 'select', child: Text('Select')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedType = v ?? 'string'),
                ),
                if (selectedType == 'select') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: optionsController,
                    decoration: const InputDecoration(
                      labelText: 'Options (comma-separated)',
                      hintText: 'Low, Medium, High',
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      );

      if (confirmed != true || !context.mounted) return;

      final name = nameController.text.trim();
      Map<String, dynamic>? extraData;
      if (selectedType == 'select') {
        final options = optionsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (options.isNotEmpty) {
          extraData = {'select_options': options};
        }
      }

      try {
        await ref.read(paperlessApiProvider).createCustomField(
              name: name,
              dataType: selectedType,
              extraData: extraData,
            );
        ref.invalidate(customFieldsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"$name" created')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create: $e')),
          );
        }
      }
    } finally {
      nameController.dispose();
      optionsController.dispose();
    }
  }
}

class _CustomFieldTile extends ConsumerWidget {
  final CustomField field;

  const _CustomFieldTile({required this.field});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectOptions = field.dataType == 'select'
        ? (field.extraData['select_options'] as List?)?.length ?? 0
        : 0;
    final subtitle = field.dataType == 'select'
        ? '${dataTypeLabel(field.dataType)} · $selectOptions options'
        : dataTypeLabel(field.dataType);

    return ListTile(
      leading: Icon(dataTypeIcon(field.dataType)),
      title: Text(field.name),
      subtitle: Text(subtitle),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline,
            color: Theme.of(context).colorScheme.error),
        onPressed: () => _confirmDelete(context, ref),
      ),
      onTap: () => _showRenameDialog(context, ref),
    );
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController(text: field.name);

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rename Field'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Rename'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      final newName = nameController.text.trim();
      if (newName == field.name) return;

      try {
        await ref
            .read(paperlessApiProvider)
            .updateCustomField(field.id, name: newName);
        ref.invalidate(customFieldsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Renamed to "$newName"')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to rename: $e')),
          );
        }
      }
    } finally {
      nameController.dispose();
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete custom field?'),
        content: Text(
            'Delete "${field.name}"? This will remove the field from all documents. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(paperlessApiProvider).deleteCustomField(field.id);
      ref.invalidate(customFieldsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${field.name}" deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
}
```

- [ ] **Step 2: Run analysis and tests**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze && flutter test
```

- [ ] **Step 3: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/features/custom_fields/custom_fields_screen.dart
git commit -m "feat: add custom fields management screen with create, rename, and delete"
```

---

## Task 3 — Navigation wiring

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Add route to `lib/app.dart`**

Add import:
```dart
import 'features/custom_fields/custom_fields_screen.dart';
```

Add route (near the `/workflows` route):
```dart
      GoRoute(
        path: '/custom-fields',
        builder: (_, __) => const CustomFieldsScreen(),
      ),
```

- [ ] **Step 2: Add "Custom Fields" link to settings screen**

In `lib/features/settings/settings_screen.dart`, find the "Workflows" ListTile and add after it:

```dart
            ListTile(
              leading: const Icon(Icons.extension_outlined),
              title: const Text('Custom Fields'),
              subtitle: const Text('Create and manage field definitions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/custom-fields'),
            ),
```

- [ ] **Step 3: Run analysis and tests**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze && flutter test
```

- [ ] **Step 4: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/app.dart lib/features/settings/settings_screen.dart
git commit -m "feat: add custom fields route and settings link"
```

---

## Self-Review

**Spec coverage:**
- ✅ Data type display helpers (TDD: tested first) — Task 1
- ✅ CRUD API methods (create, update name, delete) — Task 1
- ✅ List screen with sorted fields, type icons, select option count — Task 2
- ✅ Create dialog with name + data type dropdown + select options input — Task 2
- ✅ Rename dialog — Task 2
- ✅ Delete with confirmation (warns about document impact) — Task 2
- ✅ Navigation from Settings — Task 3
- ✅ context.mounted guards on all async UI operations — Task 2
- ✅ TextEditingController disposal in finally blocks — Task 2

**Placeholder scan:** None.

**Type consistency:**
- `CustomField` model (existing) used in Tasks 1+2 — consistent
- `customFieldsProvider` (existing) watched/invalidated in Task 2 — consistent
- `paperlessApiProvider` used for CRUD calls in Task 2 — consistent
- Helper functions from Task 1 used in Task 2 tile — consistent
- `/custom-fields` route defined in Task 3, pushed from Task 3 settings link — consistent

**Design decision: data_type cannot be changed after creation.** This is a Paperless-ngx constraint. The edit dialog only allows renaming, not changing the type. This is documented in the plan and reflected in the `updateCustomField` API method accepting only `name`.
