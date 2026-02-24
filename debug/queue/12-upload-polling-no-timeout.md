# Bug: upload-polling-no-timeout

## Observed behavior
After uploading a document, the app polls the task status every 2 seconds indefinitely. If the server task gets stuck, the polling never stops and the upload appears permanently in "processing" state.

## Expected behavior
Polling should timeout after a reasonable period (e.g., 5 minutes) and show an error with retry option.

## Steps to reproduce
1. Upload a document
2. If the server processing hangs or the task UUID is lost, polling continues forever
3. App shows permanent "Processing..." state

## Severity
medium

## Notes
- `lib/features/scanner/upload_notifier.dart` — `_startPolling` method polls every 2 seconds with no max attempts
- No timeout or max retry count
- Fix: add a counter or timer, stop after N attempts and show timeout error
