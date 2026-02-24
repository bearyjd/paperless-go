# Bug: documents-loadmore-silent-failure

## Observed behavior
When infinite scroll pagination fails (loading the next page of documents), the error is silently caught and discarded. The user sees no error message and the loading indicator just disappears.

## Expected behavior
Show a retry button or SnackBar when loading more documents fails.

## Steps to reproduce
1. Open documents screen with many documents
2. Scroll down to trigger pagination
3. If network fails during load, the spinner disappears with no feedback
4. User must manually pull-to-refresh to try again

## Severity
medium

## Notes
- `lib/features/documents/documents_notifier.dart:151-153` — `catch (_) { state = AsyncData(current.copyWith(isLoadingMore: false)); }`
- The error is completely discarded — no logging, no user feedback
- Fix: add an `error` field to `DocumentsState` or show a SnackBar via a side-effect mechanism
