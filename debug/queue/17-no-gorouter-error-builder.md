# Bug: no-gorouter-error-builder

## Observed behavior
Navigating to an undefined route (e.g., via deep link) shows Flutter's default red error screen instead of a user-friendly error page.

## Expected behavior
Show a "Page not found" screen with a button to go home.

## Steps to reproduce
1. Open app via deep link with invalid path (e.g., `paperlessgo://nonexistent`)
2. See red error screen

## Severity
low

## Notes
- `lib/app.dart:43-130` — GoRouter config has no `errorBuilder` or `errorPageBuilder`
- Fix: add `errorBuilder: (_, state) => Scaffold(body: Center(child: Text('Page not found')))` with a home button
