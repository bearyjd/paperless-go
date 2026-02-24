# Bug: upload-no-progress-reporting

## Observed behavior
During document upload, the UI shows a generic "Uploading..." state but no progress percentage. For large files (multi-page scans, high-res PDFs), the user has no idea how long the upload will take.

## Expected behavior
Show upload progress percentage (e.g., "Uploading... 45%").

## Steps to reproduce
1. Scan or select a large document (5+ MB)
2. Upload it
3. Observe only a spinner with no progress indication

## Severity
medium

## Notes
- `lib/features/scanner/upload_notifier.dart` — `UploadState` has a `progress` field (line ~23) but it's never updated
- Dio supports `onSendProgress` callback in `Options` but it's not used
- `lib/core/api/paperless_api.dart:286-293` — `uploadDocument` doesn't accept or use progress callback
- Fix: add `onSendProgress` to the Dio upload call, pass progress updates to the notifier state
