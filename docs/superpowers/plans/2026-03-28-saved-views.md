# Saved Views — Complete Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the saved views feature: expand filter rule coverage, add CRUD (create/delete/rename) from within the app, and add a "save current filter" shortcut.

**Architecture:** The saved views chips bar already exists in `DocumentsScreen` and `_applySavedView()` converts rules to a `DocumentsFilter`. This plan (1) extracts that conversion to a testable helper file, (2) adds create/delete/rename API calls, (3) adds a "save as view" button to the active filters bar, and (4) adds long-press chip management for delete and rename.

**Tech Stack:** Flutter, Riverpod, Dio, Paperless-ngx REST API (`/api/saved_views/`)

---

## Current state

- `SavedView` model + `savedViewsProvider` + `getSavedViews()` API method — **done**
- Horizontal chip bar in `DocumentsScreen` — **done**
- `_applySavedView()` handles rule types 3/4/6 only — **incomplete**
- No create/delete/rename — **missing**
- No "save current filter" — **missing**

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/features/documents/saved_view_helpers.dart` | Create | Pure conversion functions: `filterRulesToDocumentsFilter`, `documentsFilterToFilterRules`, `parseOrdering` |
| `lib/core/api/paperless_api.dart` | Modify | Add `createSavedView`, `deleteSavedView`, `updateSavedView` |
| `lib/features/documents/documents_screen.dart` | Modify | Use helpers in `_applySavedView`; add save button to `_ActiveFiltersBar`; add long-press chip management |
| `test/unit/documents/saved_view_helpers_test.dart` | Create | Tests for both conversion directions and edge cases |

---

## Paperless-ngx filter rule type constants

The following rule types are used in Paperless-ngx (from `filter_rule_type.py`):

```
0  = TITLE           → title contains  → passes as query param
1  = TITLE_WORD      → title word      → passes as query param
2  = EXTENDED_MATCH  → extended        → passes as query param
3  = CORRESPONDENT   → correspondent id
4  = DOCUMENT_TYPE   → document type id
6  = HAS_TAG         → tag id (additive, multiple rules allowed)
7  = HAS_ANY_TAG     → tag id (any match)
9  = CREATED_AFTER   → YYYY-MM-DD
10 = CREATED_BEFORE  → YYYY-MM-DD
22 = FULLTEXT_QUERY  → full text search → passes as query param
```

---

## Task 1 — Extract conversion helpers + expand rule coverage

**Files:**
- Create: `lib/features/documents/saved_view_helpers.dart`
- Create: `test/unit/documents/saved_view_helpers_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/unit/documents/saved_view_helpers_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/saved_view.dart';
import 'package:paperless_go/features/documents/documents_notifier.dart';
import 'package:paperless_go/features/documents/saved_view_helpers.dart';

void main() {
  group('filterRulesToDocumentsFilter', () {
    test('converts correspondent rule', () {
      final filter = filterRulesToDocumentsFilter(
        [const FilterRule(ruleType: 3, value: '5')],
        '-created',
      );
      expect(filter.correspondentId, 5);
      expect(filter.ordering, '-created');
    });

    test('converts document type rule', () {
      final filter = filterRulesToDocumentsFilter(
        [const FilterRule(ruleType: 4, value: '12')],
        'title',
      );
      expect(filter.documentTypeId, 12);
      expect(filter.ordering, 'title');
    });

    test('converts has-tag rules (multiple)', () {
      final filter = filterRulesToDocumentsFilter(
        [
          const FilterRule(ruleType: 6, value: '1'),
          const FilterRule(ruleType: 6, value: '2'),
        ],
        '-created',
      );
      expect(filter.tagIds, containsAll([1, 2]));
    });

    test('converts full-text query rule (type 22)', () {
      final filter = filterRulesToDocumentsFilter(
        [const FilterRule(ruleType: 22, value: 'invoice')],
        '-created',
      );
      expect(filter.query, 'invoice');
    });

    test('converts title contains rules (types 0, 1, 2) as query', () {
      for (final type in [0, 1, 2]) {
        final filter = filterRulesToDocumentsFilter(
          [FilterRule(ruleType: type, value: 'test')],
          '-created',
        );
        expect(filter.query, 'test',
            reason: 'rule type $type should map to query');
      }
    });

    test('converts created after rule (type 9)', () {
      final filter = filterRulesToDocumentsFilter(
        [const FilterRule(ruleType: 9, value: '2024-01-01')],
        '-created',
      );
      expect(filter.createdDateFrom, DateTime(2024, 1, 1));
    });

    test('converts created before rule (type 10)', () {
      final filter = filterRulesToDocumentsFilter(
        [const FilterRule(ruleType: 10, value: '2024-12-31')],
        '-created',
      );
      expect(filter.createdDateTo, DateTime(2024, 12, 31));
    });

    test('ignores unknown rule types without throwing', () {
      expect(
        () => filterRulesToDocumentsFilter(
          [const FilterRule(ruleType: 999, value: 'x')],
          '-created',
        ),
        returnsNormally,
      );
    });

    test('empty rules returns default filter with given ordering', () {
      final filter = filterRulesToDocumentsFilter([], 'title');
      expect(filter.ordering, 'title');
      expect(filter.query, isNull);
      expect(filter.tagIds, isNull);
    });
  });

  group('documentsFilterToFilterRules', () {
    test('converts query to full-text rule', () {
      const filter = DocumentsFilter(query: 'invoice 2024', ordering: '-created');
      final rules = documentsFilterToFilterRules(filter);
      expect(rules.any((r) => r.ruleType == 22 && r.value == 'invoice 2024'),
          isTrue);
    });

    test('converts correspondent to rule type 3', () {
      const filter = DocumentsFilter(correspondentId: 7, ordering: '-created');
      final rules = documentsFilterToFilterRules(filter);
      expect(rules.any((r) => r.ruleType == 3 && r.value == '7'), isTrue);
    });

    test('converts each tag to a separate rule type 6', () {
      const filter = DocumentsFilter(tagIds: [1, 2, 3], ordering: '-created');
      final rules = documentsFilterToFilterRules(filter);
      final tagRules = rules.where((r) => r.ruleType == 6).toList();
      expect(tagRules.map((r) => r.value).toSet(), {'1', '2', '3'});
    });

    test('converts date range to rules 9 and 10', () {
      final filter = DocumentsFilter(
        createdDateFrom: DateTime(2024, 1, 1),
        createdDateTo: DateTime(2024, 12, 31),
        ordering: '-created',
      );
      final rules = documentsFilterToFilterRules(filter);
      expect(rules.any((r) => r.ruleType == 9 && r.value == '2024-01-01'),
          isTrue);
      expect(rules.any((r) => r.ruleType == 10 && r.value == '2024-12-31'),
          isTrue);
    });

    test('empty filter produces empty rules', () {
      const filter = DocumentsFilter(ordering: '-created');
      expect(documentsFilterToFilterRules(filter), isEmpty);
    });

    test('round-trip: filter → rules → filter preserves fields', () {
      const original = DocumentsFilter(
        query: 'test',
        correspondentId: 3,
        documentTypeId: 4,
        tagIds: [1, 2],
        ordering: '-created',
      );
      final rules = documentsFilterToFilterRules(original);
      final restored = filterRulesToDocumentsFilter(rules, original.ordering);
      expect(restored.query, original.query);
      expect(restored.correspondentId, original.correspondentId);
      expect(restored.documentTypeId, original.documentTypeId);
      expect(restored.tagIds, containsAll(original.tagIds!));
      expect(restored.ordering, original.ordering);
    });
  });

  group('parseOrdering', () {
    test('parses descending ordering', () {
      final (field, reverse) = parseOrdering('-created');
      expect(field, 'created');
      expect(reverse, isTrue);
    });

    test('parses ascending ordering', () {
      final (field, reverse) = parseOrdering('title');
      expect(field, 'title');
      expect(reverse, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test test/unit/documents/saved_view_helpers_test.dart -v
```

Expected: FAIL — `saved_view_helpers.dart` doesn't exist.

- [ ] **Step 3: Create `lib/features/documents/saved_view_helpers.dart`**

```dart
import '../../core/models/saved_view.dart';
import 'documents_notifier.dart';

// Paperless-ngx filter rule type constants
// See: paperless-ngx/src/documents/data/filter_rule_type.py
const int _kRuleTitle = 0;
const int _kRuleTitleWord = 1;
const int _kRuleExtendedMatch = 2;
const int _kRuleCorrespondent = 3;
const int _kRuleDocumentType = 4;
const int _kRuleHasTag = 6;
const int _kRuleHasAnyTag = 7;
const int _kRuleCreatedAfter = 9;
const int _kRuleCreatedBefore = 10;
const int _kRuleFullTextQuery = 22;

/// Converts a saved view's [filterRules] + [ordering] to a [DocumentsFilter].
DocumentsFilter filterRulesToDocumentsFilter(
    List<FilterRule> rules, String ordering) {
  String? query;
  int? correspondentId;
  int? documentTypeId;
  List<int>? tagIds;
  DateTime? createdDateFrom;
  DateTime? createdDateTo;

  for (final rule in rules) {
    switch (rule.ruleType) {
      case _kRuleTitle:
      case _kRuleTitleWord:
      case _kRuleExtendedMatch:
      case _kRuleFullTextQuery:
        if (rule.value != null && rule.value!.isNotEmpty) {
          query = rule.value;
        }
      case _kRuleCorrespondent:
        correspondentId = int.tryParse(rule.value ?? '');
      case _kRuleDocumentType:
        documentTypeId = int.tryParse(rule.value ?? '');
      case _kRuleHasTag:
      case _kRuleHasAnyTag:
        final id = int.tryParse(rule.value ?? '');
        if (id != null) {
          tagIds = [...?tagIds, id];
        }
      case _kRuleCreatedAfter:
        final date = DateTime.tryParse(rule.value ?? '');
        if (date != null) createdDateFrom = date;
      case _kRuleCreatedBefore:
        final date = DateTime.tryParse(rule.value ?? '');
        if (date != null) createdDateTo = date;
    }
    // Unknown rule types are silently ignored — future-proofing.
  }

  return DocumentsFilter(
    query: query,
    ordering: ordering,
    tagIds: tagIds,
    correspondentId: correspondentId,
    documentTypeId: documentTypeId,
    createdDateFrom: createdDateFrom,
    createdDateTo: createdDateTo,
  );
}

/// Converts a [DocumentsFilter] to the list of [FilterRule]s needed to
/// create or update a saved view via the Paperless-ngx API.
List<FilterRule> documentsFilterToFilterRules(DocumentsFilter filter) {
  final rules = <FilterRule>[];

  if (filter.query != null && filter.query!.isNotEmpty) {
    rules.add(FilterRule(ruleType: _kRuleFullTextQuery, value: filter.query));
  }
  if (filter.correspondentId != null) {
    rules.add(FilterRule(
        ruleType: _kRuleCorrespondent,
        value: filter.correspondentId.toString()));
  }
  if (filter.documentTypeId != null) {
    rules.add(FilterRule(
        ruleType: _kRuleDocumentType,
        value: filter.documentTypeId.toString()));
  }
  for (final tagId in filter.tagIds ?? []) {
    rules.add(FilterRule(ruleType: _kRuleHasTag, value: tagId.toString()));
  }
  if (filter.createdDateFrom != null) {
    rules.add(FilterRule(
        ruleType: _kRuleCreatedAfter,
        value: filter.createdDateFrom!.toIso8601String().split('T').first));
  }
  if (filter.createdDateTo != null) {
    rules.add(FilterRule(
        ruleType: _kRuleCreatedBefore,
        value: filter.createdDateTo!.toIso8601String().split('T').first));
  }

  return rules;
}

/// Parses an ordering string (e.g., `'-created'`) into a `(sortField, sortReverse)` record.
(String sortField, bool sortReverse) parseOrdering(String ordering) {
  if (ordering.startsWith('-')) {
    return (ordering.substring(1), true);
  }
  return (ordering, false);
}
```

- [ ] **Step 4: Run tests**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test test/unit/documents/saved_view_helpers_test.dart -v
```

Expected: all 13 tests pass.

- [ ] **Step 5: Run full suite**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test && flutter analyze
```

Expected: all pass, no issues.

- [ ] **Step 6: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/features/documents/saved_view_helpers.dart \
        test/unit/documents/saved_view_helpers_test.dart
git commit -m "feat: add saved view filter rule conversion helpers with full rule type coverage"
```

---

## Task 2 — Add CRUD API methods for saved views

**Files:**
- Modify: `lib/core/api/paperless_api.dart` (after `getSavedViews` at line ~250)

- [ ] **Step 1: Add `createSavedView`, `deleteSavedView`, `updateSavedView` to `paperless_api.dart`**

After the existing `getSavedViews` method, add:

```dart
  Future<SavedView> createSavedView({
    required String name,
    required List<FilterRule> filterRules,
    required String sortField,
    required bool sortReverse,
    bool showOnDashboard = false,
    bool showInSidebar = false,
  }) async {
    final response = await _dio.post('api/saved_views/', data: {
      'name': name,
      'filter_rules': filterRules
          .map((r) => {
                'rule_type': r.ruleType,
                if (r.value != null) 'value': r.value,
              })
          .toList(),
      'sort_field': sortField,
      'sort_reverse': sortReverse,
      'show_on_dashboard': showOnDashboard,
      'show_in_sidebar': showInSidebar,
    });
    return SavedView.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSavedView(int id) async {
    await _dio.delete('api/saved_views/$id/');
  }

  Future<SavedView> updateSavedView(
    int id, {
    String? name,
    bool? showOnDashboard,
    bool? showInSidebar,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (showOnDashboard != null) data['show_on_dashboard'] = showOnDashboard;
    if (showInSidebar != null) data['show_in_sidebar'] = showInSidebar;
    final response = await _dio.patch('api/saved_views/$id/', data: data);
    return SavedView.fromJson(response.data as Map<String, dynamic>);
  }
```

- [ ] **Step 2: Run analysis**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/core/api/paperless_api.dart
git commit -m "feat: add createSavedView, deleteSavedView, updateSavedView API methods"
```

---

## Task 3 — Wire `_applySavedView` to helpers + "save as view" button

**Files:**
- Modify: `lib/features/documents/documents_screen.dart`

This task:
1. Replaces the inline switch in `_applySavedView` with a call to `filterRulesToDocumentsFilter`
2. Adds a "Save as view" `IconButton` to `_ActiveFiltersBar` (shown when a filter is active)
3. Adds the save dialog logic

- [ ] **Step 1: Replace `_applySavedView` body**

In `documents_screen.dart`, add import at top:
```dart
import 'saved_view_helpers.dart';
```

Then replace `_applySavedView` (lines ~98–136) with:

```dart
  void _applySavedView(SavedView view) {
    final ordering = view.sortReverse
        ? '-${view.sortField}'
        : view.sortField;

    setState(() {
      _activeSavedViewId = view.id;
      _ordering = ordering;
    });

    ref.read(documentsNotifierProvider.notifier).applyFilter(
          filterRulesToDocumentsFilter(view.filterRules, ordering),
        );
  }
```

- [ ] **Step 2: Add `onSave` callback to `_ActiveFiltersBar`**

Update the `_ActiveFiltersBar` constructor and class to accept an `onSave` callback:

```dart
class _ActiveFiltersBar extends StatelessWidget {
  final DocumentsFilter filter;
  final Map<int, dynamic> tags;
  final Map<int, dynamic> correspondents;
  final Map<int, dynamic> docTypes;
  final VoidCallback onClear;
  final VoidCallback onSave;   // NEW

  const _ActiveFiltersBar({
    required this.filter,
    required this.tags,
    required this.correspondents,
    required this.docTypes,
    required this.onClear,
    required this.onSave,       // NEW
  });
```

In the build method of `_ActiveFiltersBar`, add a "Save as view" button next to the clear button. Find where `onClear` is used (the existing clear icon button) and add alongside it:

```dart
  // In the existing Row that contains the clear button, add:
  IconButton(
    icon: const Icon(Icons.bookmark_add_outlined),
    tooltip: 'Save as view',
    onPressed: onSave,
  ),
```

- [ ] **Step 3: Pass `onSave` from the build method**

Find the `_ActiveFiltersBar(...)` instantiation in `DocumentsScreen.build` (line ~320) and add the `onSave` parameter:

```dart
_ActiveFiltersBar(
  filter: currentFilter,
  tags: tags,
  correspondents: correspondents,
  docTypes: docTypes,
  onClear: () {
    ref.read(documentsNotifierProvider.notifier)
        .applyFilter(DocumentsFilter(ordering: _ordering));
  },
  onSave: () => _showSaveViewDialog(context, currentFilter),  // NEW
),
```

- [ ] **Step 4: Add `_showSaveViewDialog` method to `_DocumentsScreenState`**

Add this method to `_DocumentsScreenState`:

```dart
  Future<void> _showSaveViewDialog(
      BuildContext context, DocumentsFilter currentFilter) async {
    final nameController = TextEditingController();
    bool showOnDashboard = false;
    bool showInSidebar = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Save as view'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'View name',
                  hintText: 'e.g. Invoices 2024',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show in sidebar'),
                value: showInSidebar,
                onChanged: (v) => setDialogState(() => showInSidebar = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show on dashboard'),
                value: showOnDashboard,
                onChanged: (v) => setDialogState(() => showOnDashboard = v),
              ),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final name = nameController.text.trim();
    final rules = documentsFilterToFilterRules(currentFilter);
    final (sortField, sortReverse) = parseOrdering(currentFilter.ordering);

    try {
      await ref.read(paperlessApiProvider).createSavedView(
            name: name,
            filterRules: rules,
            sortField: sortField,
            sortReverse: sortReverse,
            showOnDashboard: showOnDashboard,
            showInSidebar: showInSidebar,
          );
      ref.invalidate(savedViewsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" saved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save view: $e')),
        );
      }
    }
  }
```

- [ ] **Step 5: Run analysis and tests**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze && flutter test
```

Expected: no issues, all tests pass.

- [ ] **Step 6: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/features/documents/documents_screen.dart
git commit -m "feat: wire filter rule helpers to saved views, add save-as-view button and dialog"
```

---

## Task 4 — Long-press chip management: delete and rename

**Files:**
- Modify: `lib/features/documents/documents_screen.dart`

When the user long-presses a saved view chip, show a bottom sheet with **Rename** and **Delete** options.

- [ ] **Step 1: Wrap each chip in a `GestureDetector` with `onLongPress`**

In `DocumentsScreen.build`, find the `FilterChip(...)` for saved views (line ~299). Replace the `Padding` + `FilterChip` block with:

```dart
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: GestureDetector(
                                    onLongPress: () =>
                                        _showChipManagementSheet(context, view),
                                    child: FilterChip(
                                      label: Text(view.name),
                                      selected: _activeSavedViewId == view.id,
                                      onSelected: (_) {
                                        if (_activeSavedViewId == view.id) {
                                          setState(
                                              () => _activeSavedViewId = null);
                                          ref
                                              .read(documentsNotifierProvider
                                                  .notifier)
                                              .applyFilter(DocumentsFilter(
                                                  ordering: _ordering));
                                        } else {
                                          _applySavedView(view);
                                        }
                                      },
                                    ),
                                  ),
                                ),
```

- [ ] **Step 2: Add `_showChipManagementSheet` method**

Add to `_DocumentsScreenState`:

```dart
  Future<void> _showChipManagementSheet(
      BuildContext context, SavedView view) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Delete',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;

    if (action == 'delete') {
      await _deleteSavedView(context, view);
    } else if (action == 'rename') {
      await _renameSavedView(context, view);
    }
  }

  Future<void> _deleteSavedView(BuildContext context, SavedView view) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete view?'),
        content: Text('Delete "${view.name}"? This cannot be undone.'),
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
      await ref.read(paperlessApiProvider).deleteSavedView(view.id);
      if (_activeSavedViewId == view.id) {
        setState(() => _activeSavedViewId = null);
        ref.read(documentsNotifierProvider.notifier)
            .applyFilter(DocumentsFilter(ordering: _ordering));
      }
      ref.invalidate(savedViewsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${view.name}" deleted')),
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

  Future<void> _renameSavedView(BuildContext context, SavedView view) async {
    final nameController = TextEditingController(text: view.name);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename view'),
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
    try {
      await ref
          .read(paperlessApiProvider)
          .updateSavedView(view.id, name: newName);
      ref.invalidate(savedViewsProvider);
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
  }
```

- [ ] **Step 3: Run analysis and full test suite**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze && flutter test
```

Expected: no issues, all tests pass.

- [ ] **Step 4: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/features/documents/documents_screen.dart
git commit -m "feat: add long-press chip management for saved view delete and rename"
```

---

## Self-Review

**Spec coverage:**
- ✅ Expand filter rule coverage (types 0/1/2/6/7/9/10/22) — Task 1
- ✅ Create saved view from current filter — Task 3
- ✅ Delete saved view — Task 4
- ✅ Rename saved view — Task 4
- ✅ API methods (create/delete/update) — Task 2
- ✅ Conversion helpers testable independently — Task 1

**Placeholder scan:** None.

**Type consistency:**
- `filterRulesToDocumentsFilter(List<FilterRule>, String)` → `DocumentsFilter` — used in Task 1 (test) and Task 3 (screen)
- `documentsFilterToFilterRules(DocumentsFilter)` → `List<FilterRule>` — used in Task 1 (test) and Task 3 (save dialog)
- `parseOrdering(String)` → `(String, bool)` — used in Task 1 (test) and Task 3 (save dialog)
- `createSavedView(...)` → `Future<SavedView>` — used in Task 3
- `deleteSavedView(int)` → `Future<void>` — used in Task 4
- `updateSavedView(int, {name?, ...})` → `Future<SavedView>` — used in Task 4
- `ref.invalidate(savedViewsProvider)` — used in Tasks 3 and 4 to refresh chips after mutations
