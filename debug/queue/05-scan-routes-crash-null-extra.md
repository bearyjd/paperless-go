# Bug: scan-routes-crash-null-extra

## Observed behavior
Navigating to `/scan/review` or `/scan/upload` via deep link or without passing `state.extra` crashes with a `TypeError` (null cast).

## Expected behavior
Should show an error page or redirect to home instead of crashing.

## Steps to reproduce
1. Open the app via deep link: `paperlessgo://scan/review`
2. App crashes with `TypeError: type 'Null' is not a subtype of type 'List<dynamic>'`

## Severity
high

## Notes
- `lib/app.dart:83-84` — `(state.extra as List<dynamic>).cast<String>()` crashes when `state.extra` is null
- `lib/app.dart:89-90` — `state.extra as Map<String, dynamic>` same issue
- Other routes like `/documents/:id` properly handle invalid params with `int.tryParse` fallback
- Fix: add null check on `state.extra` and return error scaffold or redirect
