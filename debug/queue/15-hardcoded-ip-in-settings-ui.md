# Bug: hardcoded-ip-in-settings-ui

## Observed behavior
The Paperless-AI URL settings field shows a hardcoded private IP address `192.168.1.21:8083` as both the hint text and example text, exposing the developer's internal network topology.

## Expected behavior
Use a generic example like `http://your-server:8083` or `http://paperless-ai.local:8083`.

## Steps to reproduce
1. Open Settings
2. Tap "Paperless-AI URL"
3. See `http://192.168.1.21:8083` as placeholder

## Severity
low

## Notes
- `lib/features/settings/settings_screen.dart:343` — description text with hardcoded IP
- `lib/features/settings/settings_screen.dart:353` — hintText with hardcoded IP
- Fix: replace with generic example addresses
