# Dashboard — Statistics Overview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a home dashboard screen that shows library-level statistics (document count, inbox count, tags, correspondents, document types, storage paths) from the Paperless-ngx `api/statistics/` endpoint.

**Architecture:** `DashboardScreen` replaces `InboxScreen` as the home tab (`/`). `InboxScreen` moves to `/inbox` (pushed from the Inbox stat card tap). A plain `DashboardStatistics` Dart class parses the statistics JSON. A Riverpod `@riverpod` `AsyncNotifier` wraps the existing `getStatistics()` API method and exposes `refresh()`. The screen shows a pull-to-refresh 2-column grid of stat cards with tappable Inbox card.

**Tech Stack:** Flutter, Riverpod (`riverpod_annotation`), Material 3, GoRouter, `dart run build_runner build`

---

## Current state

- `PaperlessApi.getStatistics()` already exists at `lib/core/api/paperless_api.dart` — calls `api/statistics/`, returns `Future<Map<String, dynamic>>`
- No `lib/features/dashboard/` directory yet
- `InboxScreen` is currently at `/` inside the `ShellRoute` in `lib/app.dart`
- Bottom nav: 4 tabs — Inbox (`/`), Docs (`/documents`), Scan (`/scan`), Chat (`/chat`)

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/features/dashboard/dashboard_statistics.dart` | Create | `DashboardStatistics` data class + `DashboardStatisticsNotifier` provider |
| `lib/features/dashboard/dashboard_statistics.g.dart` | Generated | Riverpod code gen (build_runner output) |
| `lib/features/dashboard/dashboard_screen.dart` | Create | `DashboardScreen` UI: AppBar, pull-to-refresh, 2-column stat card grid |
| `lib/app.dart` | Modify | `/` → `DashboardScreen`; `/inbox` → `InboxScreen`; nav icon/label update |
| `test/unit/dashboard/dashboard_statistics_test.dart` | Create | Unit tests for `DashboardStatistics.fromJson` |

---

## Paperless-ngx `api/statistics/` response shape

```json
{
  "documents_total": 142,
  "documents_inbox": 5,
  "inbox_tag": 1,
  "inbox_tag_name": "inbox",
  "document_file_type_counts": [
    {"mime_type": "application/pdf", "mime_type_count": 130}
  ],
  "character_count": 1234567,
  "tag_count": 25,
  "correspondent_count": 18,
  "document_type_count": 8,
  "storage_path_count": 3,
  "current_asn": 0
}
```

All fields are integers. Unknown fields (e.g. `inbox_tag`, `document_file_type_counts`) are ignored. All fields default to `0` if absent for forward-compat with older server versions.

---

## Task 1 — `DashboardStatistics` model + provider

**Files:**
- Create: `lib/features/dashboard/dashboard_statistics.dart`
- Create: `test/unit/dashboard/dashboard_statistics_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/unit/dashboard/dashboard_statistics_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/dashboard/dashboard_statistics.dart';

void main() {
  group('DashboardStatistics.fromJson', () {
    test('parses all integer fields', () {
      final stats = DashboardStatistics.fromJson({
        'documents_total': 142,
        'documents_inbox': 5,
        'tag_count': 25,
        'correspondent_count': 18,
        'document_type_count': 8,
        'storage_path_count': 3,
        'character_count': 1234567,
      });
      expect(stats.documentsTotal, 142);
      expect(stats.documentsInbox, 5);
      expect(stats.tagCount, 25);
      expect(stats.correspondentCount, 18);
      expect(stats.documentTypeCount, 8);
      expect(stats.storagePathCount, 3);
      expect(stats.characterCount, 1234567);
    });

    test('defaults all fields to 0 when JSON is empty', () {
      final stats = DashboardStatistics.fromJson({});
      expect(stats.documentsTotal, 0);
      expect(stats.documentsInbox, 0);
      expect(stats.tagCount, 0);
      expect(stats.correspondentCount, 0);
      expect(stats.documentTypeCount, 0);
      expect(stats.storagePathCount, 0);
      expect(stats.characterCount, 0);
    });

    test('handles num (double) values from JSON decoder', () {
      // Paperless-ngx sometimes returns floats for integer fields
      final stats = DashboardStatistics.fromJson({
        'documents_total': 142.0,
        'tag_count': 25.0,
        'correspondent_count': 18.0,
      });
      expect(stats.documentsTotal, 142);
      expect(stats.tagCount, 25);
      expect(stats.correspondentCount, 18);
    });

    test('ignores unknown fields without throwing', () {
      final stats = DashboardStatistics.fromJson({
        'documents_total': 10,
        'inbox_tag': 1,
        'inbox_tag_name': 'inbox',
        'document_file_type_counts': [
          {'mime_type': 'application/pdf', 'mime_type_count': 10}
        ],
        'current_asn': 0,
      });
      expect(stats.documentsTotal, 10);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test test/unit/dashboard/dashboard_statistics_test.dart -v
```

Expected: FAIL — `Target file "test/unit/dashboard/dashboard_statistics_test.dart" not found` or compile error because `dashboard_statistics.dart` doesn't exist.

- [ ] **Step 3: Create `lib/features/dashboard/dashboard_statistics.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_providers.dart';

part 'dashboard_statistics.g.dart';

/// Parsed result of the Paperless-ngx `GET api/statistics/` endpoint.
class DashboardStatistics {
  final int documentsTotal;
  final int documentsInbox;
  final int tagCount;
  final int correspondentCount;
  final int documentTypeCount;
  final int storagePathCount;
  final int characterCount;

  const DashboardStatistics({
    required this.documentsTotal,
    required this.documentsInbox,
    required this.tagCount,
    required this.correspondentCount,
    required this.documentTypeCount,
    required this.storagePathCount,
    required this.characterCount,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    return DashboardStatistics(
      documentsTotal: (json['documents_total'] as num?)?.toInt() ?? 0,
      documentsInbox: (json['documents_inbox'] as num?)?.toInt() ?? 0,
      tagCount: (json['tag_count'] as num?)?.toInt() ?? 0,
      correspondentCount: (json['correspondent_count'] as num?)?.toInt() ?? 0,
      documentTypeCount: (json['document_type_count'] as num?)?.toInt() ?? 0,
      storagePathCount: (json['storage_path_count'] as num?)?.toInt() ?? 0,
      characterCount: (json['character_count'] as num?)?.toInt() ?? 0,
    );
  }
}

@riverpod
class DashboardStatisticsNotifier extends _$DashboardStatisticsNotifier {
  @override
  Future<DashboardStatistics> build() async {
    final json = await ref.read(paperlessApiProvider).getStatistics();
    return DashboardStatistics.fromJson(json);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
```

**Note on imports:** `paperlessApiProvider` is in `lib/core/api/api_providers.dart`. If `flutter analyze` shows it as unresolved, search for the actual file that exports `paperlessApiProvider`:
```bash
grep -r "paperlessApiProvider" lib/core/ --include="*.dart" -l
```
and adjust the import accordingly.

- [ ] **Step 4: Run code generation**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `lib/features/dashboard/dashboard_statistics.g.dart` with `dashboardStatisticsNotifierProvider`.

- [ ] **Step 5: Run tests**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test test/unit/dashboard/dashboard_statistics_test.dart -v
```

Expected: 4 tests pass.

- [ ] **Step 6: Run full suite**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test && flutter analyze
```

Expected: all tests pass, no analysis issues.

- [ ] **Step 7: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/features/dashboard/dashboard_statistics.dart \
        lib/features/dashboard/dashboard_statistics.g.dart \
        test/unit/dashboard/dashboard_statistics_test.dart
git commit -m "feat: add DashboardStatistics model and Riverpod provider"
```

---

## Task 2 — `DashboardScreen` UI

**Files:**
- Create: `lib/features/dashboard/dashboard_screen.dart`

This task has no new tests — `DashboardScreen` is pure widget code. The provider is already tested in Task 1. Widget-level tests would require a mock API; skip for YAGNI.

- [ ] **Step 1: Create `lib/features/dashboard/dashboard_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dashboard_statistics.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatisticsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            tooltip: 'Search',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load statistics'),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () =>
                    ref.invalidate(dashboardStatisticsNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref
              .read(dashboardStatisticsNotifierProvider.notifier)
              .refresh(),
          child: _DashboardBody(stats: stats),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardStatistics stats;

  const _DashboardBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _StatCard(
              icon: Icons.description_outlined,
              label: 'Documents',
              value: stats.documentsTotal.toString(),
            ),
            _StatCard(
              icon: Icons.inbox_outlined,
              label: 'Inbox',
              value: stats.documentsInbox.toString(),
              onTap: (ctx) => ctx.push('/inbox'),
            ),
            _StatCard(
              icon: Icons.label_outline,
              label: 'Tags',
              value: stats.tagCount.toString(),
            ),
            _StatCard(
              icon: Icons.person_outline,
              label: 'Correspondents',
              value: stats.correspondentCount.toString(),
            ),
            _StatCard(
              icon: Icons.folder_outlined,
              label: 'Document Types',
              value: stats.documentTypeCount.toString(),
            ),
            _StatCard(
              icon: Icons.storage_outlined,
              label: 'Storage Paths',
              value: stats.storagePathCount.toString(),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final void Function(BuildContext)? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAction = onTap != null;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: hasAction ? () => onTap!(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: colorScheme.primary, size: 20),
                  if (hasAction) ...[
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant, size: 16),
                  ],
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analysis**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze
```

Expected: no issues.

- [ ] **Step 3: Run full test suite**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test
```

Expected: all tests pass (test count unchanged — no new tests in this task).

- [ ] **Step 4: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/features/dashboard/dashboard_screen.dart
git commit -m "feat: add DashboardScreen with pull-to-refresh stat card grid"
```

---

## Task 3 — Wire navigation

**Files:**
- Modify: `lib/app.dart`

Three changes:
1. Add `DashboardScreen` import
2. Replace `InboxScreen` at `/` (inside `ShellRoute`) with `DashboardScreen`
3. Add `/inbox` as a **top-level route** (outside `ShellRoute`) so it pushes with a back button
4. Update `NavigationDestination` index 0 from Inbox to Home icon/label

**Why `/inbox` outside ShellRoute:** Placing it outside means it pushes on top of the shell (back arrow visible, bottom nav hidden). This is the standard nav pattern for a detail/list screen reached from a dashboard card.

- [ ] **Step 1: Add import to `lib/app.dart`**

After the existing `import 'features/inbox/inbox_screen.dart';` line, add:

```dart
import 'features/dashboard/dashboard_screen.dart';
```

- [ ] **Step 2: Add `/inbox` top-level route**

In `lib/app.dart`, find:
```dart
      GoRoute(
        path: '/trash',
        builder: (_, __) => const TrashScreen(),
      ),
```

Add after it (before the `ShellRoute`):
```dart
      GoRoute(
        path: '/inbox',
        builder: (_, __) => const InboxScreen(),
      ),
```

- [ ] **Step 3: Replace `InboxScreen` with `DashboardScreen` in `ShellRoute`**

Find inside `ShellRoute.routes`:
```dart
          GoRoute(path: '/', builder: (_, __) => const InboxScreen()),
```

Replace with:
```dart
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
```

- [ ] **Step 4: Update bottom nav destination for index 0**

In `_AppShell.build`, find:
```dart
          NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
```

Replace with:
```dart
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
```

- [ ] **Step 5: Run analysis and full test suite**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze && flutter test
```

Expected: all tests pass, no analysis issues.

- [ ] **Step 6: Commit**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go
git add lib/app.dart
git commit -m "feat: wire DashboardScreen as home tab, move InboxScreen to /inbox"
```

---

## Self-Review

**Spec coverage:**
- ✅ Dashboard screen showing library statistics — Tasks 2 + 3
- ✅ Statistics from `api/statistics/` (existing `getStatistics()` method) — Task 1
- ✅ Inbox count displayed, tappable → navigates to `InboxScreen` — Tasks 2 + 3
- ✅ Pull-to-refresh — Task 2
- ✅ Error state with retry button — Task 2
- ✅ `DashboardStatistics` model unit tests (4 tests) — Task 1
- ✅ `InboxScreen` still accessible at `/inbox` — Task 3

**Placeholder scan:** None found.

**Type consistency:**
- `DashboardStatistics` defined in Task 1, used in Task 2 — field names consistent throughout (`documentsTotal`, `documentsInbox`, `tagCount`, `correspondentCount`, `documentTypeCount`, `storagePathCount`)
- `dashboardStatisticsNotifierProvider` generated in Task 1, watched/invalidated in Task 2 — consistent
- `/inbox` route added in Task 3, linked from `_StatCard.onTap` in Task 2 via `ctx.push('/inbox')` — consistent
