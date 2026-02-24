# Bug: temp-pdf-files-never-cleaned

## Observed behavior
Scanned document PDFs created in the temp directory are never deleted after upload completes. Over time, these accumulate and waste device storage.

## Expected behavior
Temporary PDF files should be deleted after successful upload.

## Steps to reproduce
1. Scan and upload multiple documents over time
2. Check device temp directory — accumulated `scan_*.pdf` files

## Severity
low

## Notes
- `lib/features/scanner/upload_notifier.dart:234` — creates `scan_${timestamp}.pdf` in temp dir
- No cleanup after upload completes or fails
- Fix: delete the temp file in the upload completion handler (both success and failure paths)
