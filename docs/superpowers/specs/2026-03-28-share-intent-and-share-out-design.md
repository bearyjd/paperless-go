# Design: Share Intent Fix & Share-Out from Document List

**Date:** 2026-03-28
**Status:** Approved

---

## Problem Summary

1. **Share-in bug:** Sharing a PDF to Paperless Go via Android "Open with" (VIEW intent) shows "Page not found" with `content://com.android.providers.downloads.documents/document/704` as the error path. GoRouter intercepts the `content://` URI as a deep link path, fails to match any route, and renders the error page. The `ShareIntentHandler` never gets to handle the file.

2. **Share-out gap:** Sharing a document out is only available from the document detail screen popup menu. Users cannot share directly from the documents list via long-press or from the bulk selection bar.

---

## Issue 1 — Fix Share-in (VIEW Intent)

### Root Cause

GoRouter's `initialLocation: '/'` is overridden by the incoming intent URI. When Android dispatches a `ACTION_VIEW` intent for a PDF, Flutter passes the intent data URI (`content://...`) to GoRouter as the initial route. GoRouter tries to match it as a path, finds nothing, and calls `errorBuilder`.

The `ShareIntentHandler` is deferred to `addPostFrameCallback` and never runs because the error page is rendered instead of the normal app shell.

### Fix

**File: `lib/app.dart` — GoRouter `redirect` callback**

Add a check at the top of the existing `redirect` function, before the auth check:

```dart
redirect: (context, state) {
  // Intercept Android VIEW intent URIs (content:// or file://) before
  // GoRouter treats them as deep link paths and 404s.
  final scheme = state.uri.scheme;
  if (scheme == 'content' || scheme == 'file') {
    return '/';
  }
  // ... existing auth redirect logic unchanged
}
```

Redirecting to `'/'` lets the normal app shell render. The `ShareIntentHandler.initialize()` fires in `addPostFrameCallback`, calls `getInitialMedia()`, receives the file (the `receive_sharing_intent` plugin stores it natively and it hasn't been `reset()` yet), and pushes to `/scan/upload` with `{filePath, filename}`.

### No other changes needed

- `ShareIntentHandler` already handles single-file → `/scan/upload` and multi-file → `/scan/review`
- `receive_sharing_intent` v1.8.1 handles `ACTION_VIEW` by copying `content://` files to a temp path and returning the resolved path
- The upload screen already accepts `{filePath, filename}` and handles arbitrary file types (PDF, images, Office docs)

---

## Issue 2A — Share-out via Long-press Context Menu

### Current behaviour

Long-press on a document card in the list calls `_toggleSelection(doc.id)` directly, entering selection mode.

### New behaviour

Long-press shows a `showModalBottomSheet` with two options:
- **Select** — existing behaviour (enters multi-select mode)
- **Share** — downloads the document and opens the native Android share sheet

### Changes

**File: `lib/features/documents/documents_screen.dart`**

Replace the card's `onLongPress: () => _toggleSelection(doc.id)` with a call to a new private method `_showDocumentContextMenu(context, ref, doc)` that shows a bottom sheet:

```
BottomSheet options:
  [share icon]  Share
  [check icon]  Select
```

The Share action reuses `documentDownloadProvider(doc.id, doc.title).future` + `Share.shareXFiles([XFile(path)])` — identical to the existing `DocumentDetailScreen._handleAction('share', ...)`.

Show a `CircularProgressIndicator` in a dialog while downloading. On error, show a SnackBar.

**File: `lib/shared/widgets/document_card.dart`** — no changes needed. The `onLongPress` callback is already passed from the screen.

---

## Issue 2B — Share-out via Bulk Action Bar

### Current behaviour

`BulkActionBar` shows: close, count, tags, correspondent, doc type, delete, more-menu.

### New behaviour

Add a share icon button between delete and the `PopupMenuButton`.

When tapped:
- If 1 document selected: download and share immediately (no confirmation)
- If 2–5 documents selected: show a loading dialog ("Downloading N documents…"), download all sequentially, then call `Share.shareXFiles([...])` with all files
- If >5 documents selected: show a confirmation snackbar first ("Sharing N documents requires downloading them. Continue?") with an action button

### Changes

**File: `lib/features/documents/bulk_action_bar.dart`**

Add `onShare` to the constructor:

```dart
final Future<void> Function() onShare;
```

Add `_ActionButton(icon: Icons.share_outlined, tooltip: 'Share', onPressed: onShare)` between the delete button and `PopupMenuButton`.

**File: `lib/features/documents/documents_screen.dart`**

Pass `onShare: () => _shareSelected(context, ref)` to `BulkActionBar`.

Implement `_shareSelected` in `_DocumentsScreenState`:
1. Read selected IDs from `_selectedIds`
2. Read the loaded documents to get titles (available from `documentsNotifierProvider`)
3. If >5 docs: show confirmation snackbar before proceeding
4. Download each doc via `documentDownloadProvider(id, title).future`
5. Collect all paths, call `Share.shareXFiles(paths.map((p) => XFile(p)).toList())`
6. On any download error: show SnackBar with the specific failure; still share successfully downloaded files

---

## Files Changed

| File | Change |
|---|---|
| `lib/app.dart` | Add 3-line `content://`/`file://` scheme check in `redirect` |
| `lib/features/documents/documents_screen.dart` | Replace `onLongPress` with context menu; add `_shareSelected`; pass `onShare` to BulkActionBar |
| `lib/features/documents/bulk_action_bar.dart` | Add `onShare` callback + share `_ActionButton` |

No new files. No new dependencies. No model changes.

---

## Error Handling

- Share-in: if `getInitialMedia()` returns empty after redirect to `/`, the app opens normally with no upload screen — graceful no-op.
- Share-out (single): download failure shows SnackBar "Failed to download: \<error\>"
- Share-out (bulk): partial failure shares what succeeded, shows SnackBar for failures

---

## Out of Scope

- iOS support (no Info.plist changes)
- Share-out of multiple PDFs shared as a batch (multi-file share-in still routes to `/scan/review` for scanned images — separate issue)
- Generating Paperless-ngx public share links
