# Bug: ref-read-in-build-method

## Observed behavior
Several widget `build` methods use `ref.read(paperlessApiProvider)` instead of `ref.watch`. This means the widget won't rebuild if the API provider changes (e.g., on server switch or re-authentication), potentially showing stale data or broken thumbnail URLs.

## Expected behavior
Use `ref.watch` in build methods for reactive state, `ref.read` only in callbacks.

## Steps to reproduce
1. Log in to server A
2. View document detail (thumbnail loads fine)
3. Switch to server B in settings without restarting
4. View a document — thumbnail URL still points to server A

## Severity
low

## Notes
- `lib/features/documents/document_detail_screen.dart:134` — `ref.read(paperlessApiProvider).thumbnailUrl(documentId)`
- `lib/features/documents/document_detail_screen.dart:135` — `ref.read(paperlessApiProvider).authToken`
- `lib/features/documents/document_detail_screen.dart:974` — `ref.read(paperlessApiProvider)` in share links section build
- Fix: change `ref.read` to `ref.watch` in these build method locations
