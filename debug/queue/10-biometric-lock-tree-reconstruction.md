# Bug: biometric-lock-tree-reconstruction

## Observed behavior
When unlocking from biometric lock screen, the entire widget tree is destroyed and rebuilt (switching from `MaterialApp` to `MaterialApp.router`). This can cause: brief white flash, loss of scroll positions, and potential `_dependents.isEmpty` assertion errors if providers are disposed mid-rebuild.

## Expected behavior
Lock/unlock transition should not destroy the entire widget tree. Use an overlay or a separate navigator instead.

## Steps to reproduce
1. Enable biometric lock in settings
2. Switch to another app briefly (triggers lock)
3. Return to app, authenticate with biometrics
4. Observe: flash/jank during transition, scroll positions reset, possible red error screen

## Severity
medium

## Notes
- `lib/app.dart:177-188` — returns `MaterialApp(home: LockScreen(...))` when locked
- `lib/app.dart:190-209` — returns `MaterialApp.router(routerConfig: router)` when unlocked
- These are completely different widget subtrees — Flutter tears down everything
- The `_dependents.isEmpty` assertion the user reported could be caused by this transition
- Fix: use a `Stack` with the lock screen as an overlay on top of `MaterialApp.router`, or use a nested `Navigator`
