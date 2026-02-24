# Bug: chat-auth-not-recovering

## Observed behavior
After an authentication error in AI chat (expired JWT, wrong credentials, network timeout during login), subsequent messages continue to fail because the `_loggedIn` flag stays `true` and `_ensureLoggedIn()` skips re-authentication.

## Expected behavior
On auth failure, the next message attempt should re-authenticate automatically.

## Steps to reproduce
1. Open AI chat and send a message (login succeeds)
2. Wait for JWT to expire or change credentials on server
3. Send another message — fails with auth error
4. Send another message — still fails (never re-authenticates)
5. Only workaround: tap "Clear chat" which resets `_loggedIn`

## Severity
high

## Notes
- `lib/features/ai_chat/chat_notifier.dart:74` — `_loggedIn` flag
- Line 83-84: `_ensureLoggedIn()` returns immediately if `_loggedIn` is true
- Lines 142-147, 175-186: catch blocks set `error` but don't reset `_loggedIn`
- Line 189-200: `clearHistory()` resets `_loggedIn = false` but user must do this manually
- Fix: in catch blocks, check if error is auth-related and reset `_loggedIn = false`
- Or: always reset `_loggedIn = false` in any catch block so next attempt re-authenticates
