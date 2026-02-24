# Bug: document-update-no-error-handling

## Observed behavior
When updating a document field (title, correspondent, document type, tags) fails due to network error or permission denied, the error is silently swallowed. The user sees no feedback.

## Expected behavior
Failed updates should show a SnackBar with the error message and revert the UI state.

## Steps to reproduce
1. Open a document detail screen
2. Disconnect from network
3. Edit the title or change a dropdown value
4. Observe no error feedback — the field appears unchanged but no message

## Severity
medium

## Notes
- `lib/features/documents/document_detail_notifier.dart:18-22` — `updateField()` has no try/catch
- Line 20: `api.updateDocument(id, data)` throws on failure, propagates unhandled
- Same issue for `addNote` (line 50-53) and `deleteNote` (line 56-59)
- The calling UI code at `document_detail_screen.dart` uses `onSave: (v) => ref.read(...).updateField(...)` without awaiting or catching
- Fix: wrap API calls in try/catch, show error via state or return a result type
