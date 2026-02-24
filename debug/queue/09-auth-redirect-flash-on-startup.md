# Bug: auth-redirect-flash-on-startup

## Observed behavior
On app startup, the login screen briefly flashes before the saved credentials are loaded from secure storage and the user is redirected to the inbox.

## Expected behavior
Show a splash/loading screen during credential loading instead of flashing the login screen.

## Steps to reproduce
1. Log in to the app and close it
2. Reopen the app
3. Observe brief flash of login screen before inbox appears

## Severity
medium

## Notes
- `lib/app.dart:47` — `ref.read(authStateProvider).valueOrNull` returns `null` during `AsyncLoading`
- Line 48: `isAuthenticated` defaults to `false` when auth state is still loading
- Line 51: redirects to `/login` because it thinks user is unauthenticated
- Fix: check if auth state is `AsyncLoading` and return `null` (no redirect) to show a loading state until credentials resolve
- Could also add an initial splash route that waits for auth state to settle
