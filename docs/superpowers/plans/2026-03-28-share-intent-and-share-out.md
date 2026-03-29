# Share Intent Fix & Share-Out from Document List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the "Page not found" crash when a PDF is shared to Paperless Go via Android VIEW intent, and add share-out actions to the document list (long-press menu and bulk selection bar).

**Architecture:** Issue 1 is a 2-line fix in the GoRouter `redirect` callback — intercept `content://` and `file://` URIs before GoRouter fails to match them, redirect to `/`, and let the existing `ShareIntentHandler` pick up the file via `getInitialMedia()`. Issues 2A and 2B add share actions to `documents_screen.dart` and `bulk_action_bar.dart`, reusing the `documentDownloadProvider` + `Share.shareXFiles` pattern already present in `DocumentDetailScreen`.

**Tech Stack:** Flutter, GoRouter, Riverpod, share_plus, receive_sharing_intent

---

## File Map

| File | Change |
|---|---|
| `lib/app.dart` | Add 3-line URI scheme check at top of GoRouter `redirect` |
| `lib/features/documents/documents_screen.dart` | Add imports; replace `onLongPress`; add `_showDocumentContextMenu`, `_shareDocument`, `_shareSelected`, `_confirmBulkShare`; pass `onShare` to BulkActionBar |
| `lib/features/documents/bulk_action_bar.dart` | Add required `onShare` param; add share `_ActionButton` in Row |

---

## Task 1: Fix GoRouter VIEW Intent Routing

**Root cause:** GoRouter sees `content://com.android.providers.downloads.documents/document/704` as the initial URI (from Android ACTION_VIEW intent data), fails to match any route, and shows "Page not found". Adding a scheme check in `redirect` catches this before the error builder fires.

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Open `lib/app.dart` and find the `redirect` callback (around line 75)**

The current callback starts:
```dart
redirect: (context, state) {
  final authState = ref.read(authStateProvider);
  // Don't redirect while auth state is still loading from storage
  if (authState.isLoading && !authState.hasError) return null;
```

- [ ] **Step 2: Add the URI scheme check as the very first 3 lines of the `redirect` body**

```dart
redirect: (context, state) {
  // Intercept Android VIEW intent URIs (content://, file://) before GoRouter
  // tries to treat them as deep link paths and shows "Page not found".
  // Redirect to '/' so the app shell renders and ShareIntentHandler picks up
  // the file via getInitialMedia() in its addPostFrameCallback.
  final scheme = state.uri.scheme;
  if (scheme == 'content' || scheme == 'file') return '/';

  final authState = ref.read(authStateProvider);
  // Don't redirect while auth state is still loading from storage
  if (authState.isLoading && !authState.hasError) return null;
```

- [ ] **Step 3: Run static analysis**

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
```

Expected: no new issues.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "fix: intercept Android VIEW intent URIs in GoRouter redirect

content:// and file:// URIs from ACTION_VIEW intents were being
treated as deep link paths, causing 'Page not found'. Redirecting
to '/' lets ShareIntentHandler pick them up via getInitialMedia()."
```

- [ ] **Step 5: Manual verification**

Build and install, then share a PDF from the Files app or Gmail attachment to Paperless Go. The app should open and navigate to the upload screen with the PDF pre-filled. Previously showed "Page not found".

---

## Task 2: Long-press Context Menu with Share Option

**Files:**
- Modify: `lib/features/documents/documents_screen.dart`

- [ ] **Step 1: Add two imports at the top of `documents_screen.dart`**

After the existing imports, add:
```dart
import 'package:share_plus/share_plus.dart';
import 'document_detail_notifier.dart';
```

- [ ] **Step 2: Add `_shareDocument` helper method to `_DocumentsScreenState`**

Add this after the existing `_clearSelection` method:

```dart
Future<void> _shareDocument(BuildContext context, WidgetRef ref, int docId, String title) async {
  try {
    final path = await ref.read(documentDownloadProvider(docId, title).future);
    await Share.shareXFiles([XFile(path)]);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }
}
```

- [ ] **Step 3: Add `_showDocumentContextMenu` method to `_DocumentsScreenState`**

Add this after `_shareDocument`:

```dart
Future<void> _showDocumentContextMenu(
  BuildContext context,
  WidgetRef ref,
  Document doc,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share'),
            onTap: () => Navigator.pop(context, 'share'),
          ),
          ListTile(
            leading: const Icon(Icons.check_box_outline_blank),
            title: const Text('Select'),
            onTap: () => Navigator.pop(context, 'select'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (action == 'share') {
    await _shareDocument(context, ref, doc.id, doc.title);
  } else if (action == 'select') {
    _toggleSelection(doc.id);
  }
}
```

- [ ] **Step 4: Replace the `onLongPress` callback in the `DocumentCard` builder**

Find (around line 317):
```dart
onLongPress: () => _toggleSelection(doc.id),
```

Replace with:
```dart
onLongPress: () => _showDocumentContextMenu(context, ref, doc),
```

Note: `ref` is available in `build(BuildContext context, WidgetRef ref)` — it's a `ConsumerStatefulWidget`.

- [ ] **Step 5: Run static analysis**

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
```

Expected: no issues. If you see "The method '_showDocumentContextMenu' isn't defined", check that both new methods are inside the `_DocumentsScreenState` class body.

- [ ] **Step 6: Commit**

```bash
git add lib/features/documents/documents_screen.dart
git commit -m "feat: add long-press context menu with Share action on document cards

Long-pressing a document card now shows a bottom sheet with Share
and Select options. Share downloads the document and opens the
native Android share sheet, matching the detail screen behavior."
```

---

## Task 3: Share Button in Bulk Action Bar

**Files:**
- Modify: `lib/features/documents/bulk_action_bar.dart`
- Modify: `lib/features/documents/documents_screen.dart`

- [ ] **Step 1: Add `onShare` parameter to `BulkActionBar`**

In `lib/features/documents/bulk_action_bar.dart`, find the class definition and add the new required field:

```dart
class BulkActionBar extends ConsumerWidget {
  final Set<int> selectedIds;
  final VoidCallback onClearSelection;
  final VoidCallback onRefresh;
  final VoidCallback onShare;           // ADD THIS LINE

  const BulkActionBar({
    super.key,
    required this.selectedIds,
    required this.onClearSelection,
    required this.onRefresh,
    required this.onShare,              // ADD THIS LINE
  });
```

- [ ] **Step 2: Add the share icon button to the `Row` in `BulkActionBar.build`**

Find the delete `_ActionButton` in the Row:
```dart
_ActionButton(
  icon: Icons.delete_outline,
  tooltip: 'Delete',
  onPressed: () => _showBulkDeleteDialog(context, ref),
  color: colorScheme.error,
),
```

Add the share button immediately before it:
```dart
_ActionButton(
  icon: Icons.share_outlined,
  tooltip: 'Share',
  onPressed: onShare,
),
_ActionButton(
  icon: Icons.delete_outline,
  tooltip: 'Delete',
  onPressed: () => _showBulkDeleteDialog(context, ref),
  color: colorScheme.error,
),
```

- [ ] **Step 3: Add `_confirmBulkShare` method to `_DocumentsScreenState` in `documents_screen.dart`**

Add after `_shareDocument`:

```dart
Future<bool?> _confirmBulkShare(BuildContext context, int count) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Share documents?'),
      content: Text(
        'Sharing $count documents requires downloading them all. Continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Share'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Add `_shareSelected` method to `_DocumentsScreenState` in `documents_screen.dart`**

Add after `_confirmBulkShare`:

```dart
Future<void> _shareSelected(BuildContext context, WidgetRef ref) async {
  final docs = ref.read(documentsNotifierProvider).valueOrNull?.documents ?? [];
  final selectedDocs = docs.where((d) => _selectedIds.contains(d.id)).toList();
  if (selectedDocs.isEmpty) return;

  if (selectedDocs.length > 5) {
    final confirmed = await _confirmBulkShare(context, selectedDocs.length);
    if (confirmed != true || !context.mounted) return;
  }

  final paths = <String>[];
  final failures = <String>[];

  for (final doc in selectedDocs) {
    try {
      final path = await ref.read(
        documentDownloadProvider(doc.id, doc.title).future,
      );
      paths.add(path);
    } catch (_) {
      failures.add(doc.title);
    }
  }

  if (paths.isNotEmpty) {
    await Share.shareXFiles(paths.map((p) => XFile(p)).toList());
  }

  if (failures.isNotEmpty && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to download: ${failures.join(', ')}'),
      ),
    );
  }
}
```

- [ ] **Step 5: Pass `onShare` to `BulkActionBar` in the widget tree**

Find the `BulkActionBar(...)` constructor call in `documents_screen.dart` (around line 360):

```dart
child: BulkActionBar(
  selectedIds: _selectedIds,
  onClearSelection: _clearSelection,
  onRefresh: () =>
      ref.read(documentsNotifierProvider.notifier).refresh(),
),
```

Replace with:
```dart
child: BulkActionBar(
  selectedIds: _selectedIds,
  onClearSelection: _clearSelection,
  onRefresh: () =>
      ref.read(documentsNotifierProvider.notifier).refresh(),
  onShare: () => _shareSelected(context, ref),
),
```

- [ ] **Step 6: Run static analysis**

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
```

Expected: no issues. Common error to watch for: "The named parameter 'onShare' is required" — means you missed the `onShare` parameter in Step 5, or `BulkActionBar` is instantiated elsewhere (check inbox screen if it also uses `BulkActionBar`).

- [ ] **Step 7: Check if `BulkActionBar` is used anywhere else**

```bash
grep -r "BulkActionBar(" lib/ --include="*.dart"
```

If any other files instantiate `BulkActionBar`, add `onShare: () {}` (no-op) to those call sites, or wire up a proper share handler.

- [ ] **Step 8: Commit**

```bash
git add lib/features/documents/bulk_action_bar.dart \
        lib/features/documents/documents_screen.dart
git commit -m "feat: add Share button to bulk document selection bar

Selecting documents and tapping Share downloads all selected files
and opens the native share sheet. Confirms before downloading >5
documents. Partial failures show a SnackBar while still sharing
successfully downloaded files."
```

---

## Final Verification

- [ ] Run full analysis:
  ```bash
  export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
  ```

- [ ] Build debug APK:
  ```bash
  export PATH="$HOME/flutter/bin:$PATH" && flutter build apk --debug 2>&1
  ```

- [ ] Manual test checklist:
  - Share a PDF from Files app → Paperless Go → upload screen opens ✓
  - Share a PDF from Gmail attachment → Paperless Go → upload screen opens ✓
  - Long-press a document card → bottom sheet shows Share + Select ✓
  - Long-press → Share → native share sheet opens with PDF ✓
  - Long-press → Select → card enters selection mode ✓
  - Select 2 documents → tap Share in bar → share sheet with both files ✓
  - Select 6 documents → tap Share → confirmation dialog appears ✓
