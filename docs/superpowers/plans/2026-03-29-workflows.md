# Workflows — View & Manage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Use TDD: test first, watch fail, minimal code, watch pass.

**Goal:** Let users view, toggle (enable/disable), and delete Paperless-ngx workflows from the mobile app. Creating and editing workflows stays in the web UI (complex nested forms, YAGNI for mobile).

**Architecture:** Freezed models for `Workflow`, `WorkflowTrigger`, `WorkflowAction`. API methods in `PaperlessApi`. Riverpod provider for caching. A list screen shows all workflows with enabled toggle. A detail screen shows triggers/actions in a readable format. Accessible from Settings screen.

**Tech Stack:** Flutter, Riverpod (`riverpod_annotation`), Freezed, GoRouter, Dio

---

## Current state

- No workflow code exists in the app
- `PaperlessApi` has no workflow methods
- Settings screen (`lib/features/settings/settings_screen.dart`) has a "Manage Labels" link — workflows link goes next to it
- Lookup providers for tags/correspondents/docTypes/storagePaths already exist in `api_providers.dart`

## Paperless-ngx Workflows API

```
GET    /api/workflows/       → paginated list of workflows
POST   /api/workflows/       → create workflow
GET    /api/workflows/{id}/  → single workflow
PATCH  /api/workflows/{id}/  → update workflow
DELETE /api/workflows/{id}/  → delete workflow
```

### Workflow JSON shape

```json
{
  "id": 1,
  "name": "Auto-tag invoices",
  "order": 0,
  "enabled": true,
  "triggers": [
    {
      "id": 1,
      "type": 1,
      "sources": [1, 2],
      "filter_filename": "*.pdf",
      "filter_path": null,
      "filter_mailrule": null,
      "matching_algorithm": 1,
      "match": "invoice",
      "is_insensitive": true,
      "filter_has_tags": [],
      "filter_has_correspondent": null,
      "filter_has_document_type": null
    }
  ],
  "actions": [
    {
      "id": 1,
      "type": 1,
      "assign_title": null,
      "assign_tags": [3, 5],
      "assign_correspondent": 2,
      "assign_document_type": 4,
      "assign_storage_path": null,
      "assign_owner": null,
      "assign_view_users": [],
      "assign_view_groups": [],
      "assign_change_users": [],
      "assign_change_groups": [],
      "assign_custom_fields": []
    }
  ]
}
```

### Constants

**Trigger types:** 1=Consumption, 2=Document Added, 3=Document Updated, 4=Removal, 5=Scheduled

**Action types:** 1=Assignment, 2=Removal, 3=Email

**Sources:** 1=Consume Folder, 2=API Upload, 3=Mail Fetch

**Matching algorithms:** 0=None, 1=Any word, 2=All words, 3=Exact match, 4=RegEx, 5=Fuzzy, 6=Auto

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/core/models/workflow.dart` | Create | Freezed models: `Workflow`, `WorkflowTrigger`, `WorkflowAction` |
| `lib/core/models/workflow.freezed.dart` | Generated | Freezed output |
| `lib/core/models/workflow.g.dart` | Generated | json_serializable output |
| `lib/core/api/paperless_api.dart` | Modify | Add `getWorkflows`, `toggleWorkflow`, `deleteWorkflow` |
| `lib/core/api/api_providers.dart` | Modify | Add `workflowsProvider` |
| `lib/features/workflows/workflows_screen.dart` | Create | List screen with enabled toggle + delete |
| `lib/features/workflows/workflow_detail_screen.dart` | Create | Detail view showing triggers and actions |
| `lib/features/workflows/workflow_helpers.dart` | Create | Pure functions: label lookups for trigger/action types, source names |
| `lib/features/settings/settings_screen.dart` | Modify | Add "Workflows" link |
| `lib/app.dart` | Modify | Add `/workflows` and `/workflows/:id` routes |
| `test/unit/models/workflow_test.dart` | Create | JSON round-trip tests for all 3 models |
| `test/unit/workflows/workflow_helpers_test.dart` | Create | Tests for label lookup functions |

---

## Task 1 — Workflow models (Freezed + json_serializable)

**Files:**
- Create: `lib/core/models/workflow.dart`
- Create: `test/unit/models/workflow_test.dart`

TDD: Write parsing tests first, then create the models, run build_runner.

- [ ] **Step 1: Write failing tests**

Create `test/unit/models/workflow_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/workflow.dart';

void main() {
  group('WorkflowTrigger', () {
    test('parses from JSON', () {
      final json = {
        'id': 1,
        'type': 1,
        'sources': [1, 2],
        'filter_filename': '*.pdf',
        'filter_path': null,
        'filter_mailrule': null,
        'matching_algorithm': 1,
        'match': 'invoice',
        'is_insensitive': true,
        'filter_has_tags': [3],
        'filter_has_correspondent': 2,
        'filter_has_document_type': null,
      };
      final trigger = WorkflowTrigger.fromJson(json);
      expect(trigger.id, 1);
      expect(trigger.type, 1);
      expect(trigger.sources, [1, 2]);
      expect(trigger.filterFilename, '*.pdf');
      expect(trigger.match, 'invoice');
      expect(trigger.isInsensitive, true);
      expect(trigger.filterHasTags, [3]);
      expect(trigger.filterHasCorrespondent, 2);
      expect(trigger.filterHasDocumentType, isNull);
    });

    test('round-trips through toJson/fromJson', () {
      final trigger = WorkflowTrigger(
        id: 5,
        type: 2,
        sources: [3],
        filterFilename: null,
        filterPath: '/docs',
        filterMailrule: null,
        matchingAlgorithm: 0,
        match: '',
        isInsensitive: false,
        filterHasTags: [],
        filterHasCorrespondent: null,
        filterHasDocumentType: 7,
      );
      final restored = WorkflowTrigger.fromJson(trigger.toJson());
      expect(restored, trigger);
    });
  });

  group('WorkflowAction', () {
    test('parses from JSON', () {
      final json = {
        'id': 1,
        'type': 1,
        'assign_title': null,
        'assign_tags': [3, 5],
        'assign_correspondent': 2,
        'assign_document_type': 4,
        'assign_storage_path': null,
        'assign_owner': null,
        'assign_view_users': <int>[],
        'assign_view_groups': <int>[],
        'assign_change_users': <int>[],
        'assign_change_groups': <int>[],
        'assign_custom_fields': <int>[],
      };
      final action = WorkflowAction.fromJson(json);
      expect(action.id, 1);
      expect(action.type, 1);
      expect(action.assignTags, [3, 5]);
      expect(action.assignCorrespondent, 2);
      expect(action.assignDocumentType, 4);
      expect(action.assignStoragePath, isNull);
    });

    test('round-trips through toJson/fromJson', () {
      final action = WorkflowAction(
        id: 2,
        type: 2,
        assignTitle: 'Test',
        assignTags: [1],
        assignCorrespondent: null,
        assignDocumentType: null,
        assignStoragePath: 3,
        assignOwner: null,
        assignViewUsers: [],
        assignViewGroups: [],
        assignChangeUsers: [],
        assignChangeGroups: [],
        assignCustomFields: [],
      );
      final restored = WorkflowAction.fromJson(action.toJson());
      expect(restored, action);
    });
  });

  group('Workflow', () {
    test('parses from JSON with nested triggers and actions', () {
      final json = {
        'id': 1,
        'name': 'Auto-tag invoices',
        'order': 0,
        'enabled': true,
        'triggers': [
          {
            'id': 1,
            'type': 1,
            'sources': [1, 2],
            'filter_filename': '*.pdf',
            'filter_path': null,
            'filter_mailrule': null,
            'matching_algorithm': 1,
            'match': 'invoice',
            'is_insensitive': true,
            'filter_has_tags': <int>[],
            'filter_has_correspondent': null,
            'filter_has_document_type': null,
          }
        ],
        'actions': [
          {
            'id': 1,
            'type': 1,
            'assign_title': null,
            'assign_tags': [3],
            'assign_correspondent': 2,
            'assign_document_type': null,
            'assign_storage_path': null,
            'assign_owner': null,
            'assign_view_users': <int>[],
            'assign_view_groups': <int>[],
            'assign_change_users': <int>[],
            'assign_change_groups': <int>[],
            'assign_custom_fields': <int>[],
          }
        ],
      };
      final workflow = Workflow.fromJson(json);
      expect(workflow.id, 1);
      expect(workflow.name, 'Auto-tag invoices');
      expect(workflow.enabled, true);
      expect(workflow.triggers.length, 1);
      expect(workflow.triggers.first.type, 1);
      expect(workflow.actions.length, 1);
      expect(workflow.actions.first.assignTags, [3]);
    });

    test('handles empty triggers and actions', () {
      final json = {
        'id': 2,
        'name': 'Empty workflow',
        'order': 1,
        'enabled': false,
        'triggers': <Map<String, dynamic>>[],
        'actions': <Map<String, dynamic>>[],
      };
      final workflow = Workflow.fromJson(json);
      expect(workflow.triggers, isEmpty);
      expect(workflow.actions, isEmpty);
      expect(workflow.enabled, false);
    });

    test('round-trips through toJson/fromJson', () {
      final workflow = Workflow(
        id: 3,
        name: 'Test workflow',
        order: 5,
        enabled: true,
        triggers: [
          WorkflowTrigger(
            id: 10,
            type: 3,
            sources: [],
            filterFilename: null,
            filterPath: null,
            filterMailrule: null,
            matchingAlgorithm: 0,
            match: '',
            isInsensitive: false,
            filterHasTags: [],
            filterHasCorrespondent: null,
            filterHasDocumentType: null,
          ),
        ],
        actions: [],
      );
      final restored = Workflow.fromJson(workflow.toJson());
      expect(restored, workflow);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test test/unit/models/workflow_test.dart -v
```

Expected: FAIL — `workflow.dart` doesn't exist.

- [ ] **Step 3: Create `lib/core/models/workflow.dart`**

Look at an existing freezed model in the project (e.g., `lib/core/models/tag.dart` or `lib/core/models/saved_view.dart`) to see the exact import pattern and freezed annotations used. Then create:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow.freezed.dart';
part 'workflow.g.dart';

@freezed
class WorkflowTrigger with _$WorkflowTrigger {
  const factory WorkflowTrigger({
    required int id,
    required int type,
    @Default([]) List<int> sources,
    String? filterFilename,
    String? filterPath,
    int? filterMailrule,
    @Default(0) int matchingAlgorithm,
    @Default('') String match,
    @Default(false) bool isInsensitive,
    @Default([]) List<int> filterHasTags,
    int? filterHasCorrespondent,
    int? filterHasDocumentType,
  }) = _WorkflowTrigger;

  factory WorkflowTrigger.fromJson(Map<String, dynamic> json) =>
      _$WorkflowTriggerFromJson(json);
}

@freezed
class WorkflowAction with _$WorkflowAction {
  const factory WorkflowAction({
    required int id,
    required int type,
    String? assignTitle,
    @Default([]) List<int> assignTags,
    int? assignCorrespondent,
    int? assignDocumentType,
    int? assignStoragePath,
    int? assignOwner,
    @Default([]) List<int> assignViewUsers,
    @Default([]) List<int> assignViewGroups,
    @Default([]) List<int> assignChangeUsers,
    @Default([]) List<int> assignChangeGroups,
    @Default([]) List<int> assignCustomFields,
  }) = _WorkflowAction;

  factory WorkflowAction.fromJson(Map<String, dynamic> json) =>
      _$WorkflowActionFromJson(json);
}

@freezed
class Workflow with _$Workflow {
  const factory Workflow({
    required int id,
    required String name,
    @Default(0) int order,
    @Default(true) bool enabled,
    @Default([]) List<WorkflowTrigger> triggers,
    @Default([]) List<WorkflowAction> actions,
  }) = _Workflow;

  factory Workflow.fromJson(Map<String, dynamic> json) =>
      _$WorkflowFromJson(json);
}
```

- [ ] **Step 4: Run code generation**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Run tests**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test test/unit/models/workflow_test.dart -v
```

Expected: 7 tests pass.

- [ ] **Step 6: Run full suite**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test && flutter analyze
```

- [ ] **Step 7: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/core/models/workflow.dart \
        lib/core/models/workflow.freezed.dart \
        lib/core/models/workflow.g.dart \
        test/unit/models/workflow_test.dart
git commit -m "feat: add Workflow, WorkflowTrigger, WorkflowAction freezed models"
```

---

## Task 2 — Workflow helper functions (pure label lookups)

**Files:**
- Create: `lib/features/workflows/workflow_helpers.dart`
- Create: `test/unit/workflows/workflow_helpers_test.dart`

These pure functions convert type/source ints to human-readable strings.

- [ ] **Step 1: Write failing tests**

Create `test/unit/workflows/workflow_helpers_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/workflows/workflow_helpers.dart';

void main() {
  group('triggerTypeLabel', () {
    test('returns label for known types', () {
      expect(triggerTypeLabel(1), 'Consumption');
      expect(triggerTypeLabel(2), 'Document Added');
      expect(triggerTypeLabel(3), 'Document Updated');
      expect(triggerTypeLabel(4), 'Removal');
      expect(triggerTypeLabel(5), 'Scheduled');
    });

    test('returns Unknown for invalid type', () {
      expect(triggerTypeLabel(99), 'Unknown');
    });
  });

  group('actionTypeLabel', () {
    test('returns label for known types', () {
      expect(actionTypeLabel(1), 'Assignment');
      expect(actionTypeLabel(2), 'Removal');
      expect(actionTypeLabel(3), 'Email');
    });

    test('returns Unknown for invalid type', () {
      expect(actionTypeLabel(0), 'Unknown');
    });
  });

  group('sourceLabel', () {
    test('returns label for known sources', () {
      expect(sourceLabel(1), 'Consume Folder');
      expect(sourceLabel(2), 'API Upload');
      expect(sourceLabel(3), 'Mail Fetch');
    });

    test('returns Unknown for invalid source', () {
      expect(sourceLabel(42), 'Unknown');
    });
  });

  group('matchingAlgorithmLabel', () {
    test('returns label for known algorithms', () {
      expect(matchingAlgorithmLabel(0), 'None');
      expect(matchingAlgorithmLabel(1), 'Any word');
      expect(matchingAlgorithmLabel(2), 'All words');
      expect(matchingAlgorithmLabel(3), 'Exact match');
      expect(matchingAlgorithmLabel(4), 'RegEx');
      expect(matchingAlgorithmLabel(5), 'Fuzzy');
      expect(matchingAlgorithmLabel(6), 'Auto');
    });

    test('returns Unknown for invalid algorithm', () {
      expect(matchingAlgorithmLabel(99), 'Unknown');
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test test/unit/workflows/workflow_helpers_test.dart -v
```

Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Create `lib/features/workflows/workflow_helpers.dart`**

```dart
/// Returns a human-readable label for a workflow trigger type int.
String triggerTypeLabel(int type) {
  return switch (type) {
    1 => 'Consumption',
    2 => 'Document Added',
    3 => 'Document Updated',
    4 => 'Removal',
    5 => 'Scheduled',
    _ => 'Unknown',
  };
}

/// Returns a human-readable label for a workflow action type int.
String actionTypeLabel(int type) {
  return switch (type) {
    1 => 'Assignment',
    2 => 'Removal',
    3 => 'Email',
    _ => 'Unknown',
  };
}

/// Returns a human-readable label for a workflow source int.
String sourceLabel(int source) {
  return switch (source) {
    1 => 'Consume Folder',
    2 => 'API Upload',
    3 => 'Mail Fetch',
    _ => 'Unknown',
  };
}

/// Returns a human-readable label for a matching algorithm int.
String matchingAlgorithmLabel(int algorithm) {
  return switch (algorithm) {
    0 => 'None',
    1 => 'Any word',
    2 => 'All words',
    3 => 'Exact match',
    4 => 'RegEx',
    5 => 'Fuzzy',
    6 => 'Auto',
    _ => 'Unknown',
  };
}
```

- [ ] **Step 4: Run tests**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test test/unit/workflows/workflow_helpers_test.dart -v
```

Expected: 8 tests pass.

- [ ] **Step 5: Run full suite**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test && flutter analyze
```

- [ ] **Step 6: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/features/workflows/workflow_helpers.dart \
        test/unit/workflows/workflow_helpers_test.dart
git commit -m "feat: add workflow helper functions for type/source label lookups"
```

---

## Task 3 — API methods + provider

**Files:**
- Modify: `lib/core/api/paperless_api.dart`
- Modify: `lib/core/api/api_providers.dart`

No unit tests for this task — API methods require a live server. Testing happens via integration in Task 4+5.

- [ ] **Step 1: Add API methods to `paperless_api.dart`**

Find the last method before the closing `}` of the class and add:

```dart
  // --- Workflows ---

  Future<List<Workflow>> getWorkflows() async {
    final response = await _dio.get('api/workflows/');
    final data = response.data;
    // The endpoint may return paginated or direct list
    final List results =
        data is Map ? (data['results'] as List? ?? []) : (data as List);
    return results
        .map((e) => Workflow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Workflow> toggleWorkflow(int id, {required bool enabled}) async {
    final response = await _dio.patch('api/workflows/$id/', data: {
      'enabled': enabled,
    });
    return Workflow.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteWorkflow(int id) async {
    await _dio.delete('api/workflows/$id/');
  }
```

Add the import for the Workflow model at the top:
```dart
import '../models/workflow.dart';
```

(Check if there's already a barrel export file that includes models — if so, use that import instead.)

- [ ] **Step 2: Add provider to `api_providers.dart`**

Read `api_providers.dart` to see the existing provider pattern. Add a `workflowsProvider` following the same pattern as `savedViewsProvider`:

```dart
@riverpod
Future<List<Workflow>> workflows(Ref ref) async {
  final api = ref.watch(paperlessApiProvider);
  return api.getWorkflows();
}
```

Add the workflow model import at the top.

- [ ] **Step 3: Run analysis and tests**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze && flutter test
```

- [ ] **Step 4: Run code generation** (if api_providers uses @riverpod)

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Run analysis and tests again**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze && flutter test
```

- [ ] **Step 6: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/core/api/paperless_api.dart \
        lib/core/api/api_providers.dart \
        lib/core/api/api_providers.g.dart
git commit -m "feat: add getWorkflows, toggleWorkflow, deleteWorkflow API methods and provider"
```

---

## Task 4 — Workflows list screen + detail screen

**Files:**
- Create: `lib/features/workflows/workflows_screen.dart`
- Create: `lib/features/workflows/workflow_detail_screen.dart`

The list screen shows all workflows with name, enabled switch, trigger/action summary. Tapping a workflow navigates to the detail screen. The detail screen shows trigger and action details in a readable format with a delete button.

- [ ] **Step 1: Create `lib/features/workflows/workflows_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/paperless_api.dart';
import '../../core/models/workflow.dart';
import 'workflow_helpers.dart';

class WorkflowsScreen extends ConsumerWidget {
  const WorkflowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowsAsync = ref.watch(workflowsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workflows')),
      body: workflowsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load workflows\n$e',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(workflowsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (workflows) {
          if (workflows.isEmpty) {
            return const Center(
              child: Text('No workflows configured'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(workflowsProvider),
            child: ListView.builder(
              itemCount: workflows.length,
              itemBuilder: (context, index) {
                final wf = workflows[index];
                return _WorkflowTile(workflow: wf);
              },
            ),
          );
        },
      ),
    );
  }
}

class _WorkflowTile extends ConsumerWidget {
  final Workflow workflow;

  const _WorkflowTile({required this.workflow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triggerSummary = workflow.triggers
        .map((t) => triggerTypeLabel(t.type))
        .join(', ');
    final actionSummary = workflow.actions
        .map((a) => actionTypeLabel(a.type))
        .join(', ');

    return ListTile(
      title: Text(workflow.name),
      subtitle: Text(
        '${workflow.triggers.length} trigger${workflow.triggers.length == 1 ? '' : 's'}'
        ' · ${workflow.actions.length} action${workflow.actions.length == 1 ? '' : 's'}',
      ),
      trailing: Switch(
        value: workflow.enabled,
        onChanged: (enabled) async {
          try {
            await ref
                .read(paperlessApiProvider)
                .toggleWorkflow(workflow.id, enabled: enabled);
            ref.invalidate(workflowsProvider);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to toggle: $e')),
              );
            }
          }
        },
      ),
      onTap: () => context.push('/workflows/${workflow.id}'),
    );
  }
}
```

- [ ] **Step 2: Create `lib/features/workflows/workflow_detail_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/paperless_api.dart';
import '../../core/models/workflow.dart';
import 'workflow_helpers.dart';

class WorkflowDetailScreen extends ConsumerWidget {
  final int workflowId;

  const WorkflowDetailScreen({super.key, required this.workflowId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowsAsync = ref.watch(workflowsProvider);

    return workflowsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Workflow')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Workflow')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (workflows) {
        final workflow = workflows.where((w) => w.id == workflowId).firstOrNull;
        if (workflow == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workflow')),
            body: const Center(child: Text('Workflow not found')),
          );
        }
        return _WorkflowDetailBody(workflow: workflow);
      },
    );
  }
}

class _WorkflowDetailBody extends ConsumerWidget {
  final Workflow workflow;

  const _WorkflowDetailBody({required this.workflow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final tags = ref.watch(tagsProvider).valueOrNull ?? {};
    final correspondents = ref.watch(correspondentsProvider).valueOrNull ?? {};
    final docTypes = ref.watch(documentTypesProvider).valueOrNull ?? {};
    final storagePaths = ref.watch(storagePathsProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(workflow.name),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status
          Card(
            child: ListTile(
              title: const Text('Status'),
              trailing: Chip(
                label: Text(workflow.enabled ? 'Enabled' : 'Disabled'),
                backgroundColor: workflow.enabled
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Triggers
          Text('Triggers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (workflow.triggers.isEmpty)
            const Card(child: ListTile(title: Text('No triggers')))
          else
            ...workflow.triggers.map((t) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(triggerTypeLabel(t.type),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: colorScheme.primary)),
                        if (t.sources.isNotEmpty)
                          _detailRow('Sources',
                              t.sources.map(sourceLabel).join(', ')),
                        if (t.match.isNotEmpty) ...[
                          _detailRow('Match', t.match),
                          _detailRow('Algorithm',
                              matchingAlgorithmLabel(t.matchingAlgorithm)),
                          _detailRow('Case insensitive',
                              t.isInsensitive ? 'Yes' : 'No'),
                        ],
                        if (t.filterFilename != null)
                          _detailRow('Filename filter', t.filterFilename!),
                        if (t.filterPath != null)
                          _detailRow('Path filter', t.filterPath!),
                        if (t.filterHasTags.isNotEmpty)
                          _detailRow(
                              'Tags',
                              t.filterHasTags
                                  .map((id) =>
                                      tags[id]?.name ?? 'Tag #$id')
                                  .join(', ')),
                        if (t.filterHasCorrespondent != null)
                          _detailRow(
                              'Correspondent',
                              correspondents[t.filterHasCorrespondent]
                                      ?.name ??
                                  'Correspondent #${t.filterHasCorrespondent}'),
                        if (t.filterHasDocumentType != null)
                          _detailRow(
                              'Document type',
                              docTypes[t.filterHasDocumentType]?.name ??
                                  'Type #${t.filterHasDocumentType}'),
                      ],
                    ),
                  ),
                )),

          const SizedBox(height: 16),

          // Actions
          Text('Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (workflow.actions.isEmpty)
            const Card(child: ListTile(title: Text('No actions')))
          else
            ...workflow.actions.map((a) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(actionTypeLabel(a.type),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: colorScheme.primary)),
                        if (a.assignTitle != null)
                          _detailRow('Title', a.assignTitle!),
                        if (a.assignTags.isNotEmpty)
                          _detailRow(
                              'Tags',
                              a.assignTags
                                  .map((id) =>
                                      tags[id]?.name ?? 'Tag #$id')
                                  .join(', ')),
                        if (a.assignCorrespondent != null)
                          _detailRow(
                              'Correspondent',
                              correspondents[a.assignCorrespondent]
                                      ?.name ??
                                  'Correspondent #${a.assignCorrespondent}'),
                        if (a.assignDocumentType != null)
                          _detailRow(
                              'Document type',
                              docTypes[a.assignDocumentType]?.name ??
                                  'Type #${a.assignDocumentType}'),
                        if (a.assignStoragePath != null)
                          _detailRow(
                              'Storage path',
                              storagePaths[a.assignStoragePath]?.name ??
                                  'Path #${a.assignStoragePath}'),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete workflow?'),
        content:
            Text('Delete "${workflow.name}"? This cannot be undone.'),
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
      await ref.read(paperlessApiProvider).deleteWorkflow(workflow.id);
      ref.invalidate(workflowsProvider);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${workflow.name}" deleted')),
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

**Note on lookups:** The detail screen uses `tags[id]?.name`, `correspondents[id]?.name`, etc. Check what type these providers return. If they return `Map<int, Tag>`, `Map<int, Correspondent>`, etc., the above code is correct. If they return `List<Tag>`, you'll need to adapt (e.g., `tags.firstWhere((t) => t.id == id, orElse: () => null)?.name`). Read `api_providers.dart` to check.

- [ ] **Step 3: Run analysis and tests**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze && flutter test
```

- [ ] **Step 4: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/features/workflows/workflows_screen.dart \
        lib/features/workflows/workflow_detail_screen.dart
git commit -m "feat: add WorkflowsScreen list with toggle and WorkflowDetailScreen"
```

---

## Task 5 — Navigation wiring

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Add routes to `lib/app.dart`**

Add import:
```dart
import 'features/workflows/workflows_screen.dart';
import 'features/workflows/workflow_detail_screen.dart';
```

Add routes (near the `/labels` route):
```dart
      GoRoute(
        path: '/workflows',
        builder: (_, __) => const WorkflowsScreen(),
      ),
      GoRoute(
        path: '/workflows/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const Scaffold(body: Center(child: Text('Invalid workflow ID')));
          return WorkflowDetailScreen(workflowId: id);
        },
      ),
```

- [ ] **Step 2: Add "Workflows" link to settings screen**

Read `lib/features/settings/settings_screen.dart` to find the "Manage Labels" `ListTile`. Add a similar tile after it:

```dart
            ListTile(
              leading: const Icon(Icons.route_outlined),
              title: const Text('Workflows'),
              subtitle: const Text('View and manage automation rules'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/workflows'),
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
git commit -m "feat: add workflows routes and settings link"
```

---

## Self-Review

**Spec coverage:**
- ✅ Workflow models with all API fields — Task 1
- ✅ Label lookup helpers for trigger/action/source types — Task 2
- ✅ API methods (list, toggle, delete) + provider — Task 3
- ✅ List screen with enabled toggle — Task 4
- ✅ Detail screen showing trigger/action details with resolved names — Task 4
- ✅ Delete with confirmation — Task 4
- ✅ Navigation from Settings — Task 5
- ✅ TDD: model tests (7) + helper tests (8) = 15 new tests

**Placeholder scan:** None.

**Type consistency:**
- `Workflow`/`WorkflowTrigger`/`WorkflowAction` defined in Task 1, used in Tasks 3+4 — consistent
- `workflowsProvider` defined in Task 3, watched in Task 4 — consistent
- Helper functions defined in Task 2, called in Task 4 — consistent
- `/workflows` and `/workflows/:id` routes defined in Task 5, pushed from Task 4 — consistent
