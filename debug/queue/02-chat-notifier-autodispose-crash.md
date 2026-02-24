# Bug: chat-notifier-autodispose-crash

## Observed behavior
Navigating away from the chat screen while an SSE streaming response is in progress causes an unhandled `StateError: Cannot update the state of a provider that has been disposed`. This can surface as a red error screen.

## Expected behavior
Navigating away should cancel the streaming request cleanly without errors.

## Steps to reproduce
1. Open document chat or RAG chat
2. Send a message that triggers a long streaming response
3. While the response is still streaming, press back or switch tabs
4. Observe crash/error in debug console

## Severity
critical

## Notes
- `lib/features/ai_chat/chat_notifier.dart:72-73` — `@riverpod` generates autoDispose provider
- Line 168: `await for (final accumulated in stream)` continues after disposal
- Line 171: `state = state.copyWith(messages: messages)` sets state on disposed notifier
- `lib/features/ai_chat/chat_service.dart:242` — no `CancelToken` for HTTP request
- Fix options:
  1. Add `@Riverpod(keepAlive: true)` to prevent auto-disposal
  2. Store a `StreamSubscription` and cancel it in a `ref.onDispose` callback
  3. Pass a `CancelToken` to Dio and cancel it on dispose
- Related: chat history is also lost when switching between general `/chat` and `/documents/:id/chat` due to autoDispose
