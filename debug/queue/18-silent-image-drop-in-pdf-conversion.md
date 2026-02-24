# Bug: silent-image-drop-in-pdf-conversion

## Observed behavior
When converting scanned images to PDF, images that fail to decode are silently skipped. If 1 of 5 scanned pages fails, the resulting PDF has only 4 pages with no user notification.

## Expected behavior
Warn the user if any pages failed to convert, or abort and show an error.

## Steps to reproduce
1. Scan multiple pages, one of which is corrupted or in an unsupported format
2. Upload — the corrupted page is silently dropped from the PDF
3. User doesn't know a page is missing

## Severity
low

## Notes
- `lib/features/scanner/upload_notifier.dart:241` — `if (decoded != null)` silently skips failed images
- Fix: track failed images and either warn user or abort with an error message
