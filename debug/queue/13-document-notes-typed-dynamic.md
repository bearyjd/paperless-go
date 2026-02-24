# Bug: document-notes-typed-dynamic

## Observed behavior
The `notes` field on the `Document` model is `List<dynamic>` instead of `List<Note>`. This means notes data from the document detail API response cannot be used with type safety — accessing note properties requires manual casting.

## Expected behavior
`notes` should be typed as `List<Note>` using the existing `Note` model.

## Steps to reproduce
1. Fetch a document with notes via the API
2. Try to access `document.notes.first.note` — compile error or runtime cast needed

## Severity
low

## Notes
- `lib/core/models/document.dart:25` — `@Default([]) List<dynamic> notes`
- `lib/core/models/note.dart` — `Note` model exists with proper `fromJson`
- The notes are currently fetched separately via `getNotes(documentId)` in `document_detail_notifier.dart`, so this field is unused in practice
- Fix: change to `@Default([]) List<Note> notes` or remove the field if always fetched separately
