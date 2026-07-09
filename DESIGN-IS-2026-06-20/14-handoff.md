# 14 — Session Handoff (2026-07-08) — redesign shipped to main; detail screen done

**Supersedes `13-handoff.md`.** Release/F-Droid state unchanged from handoff 12
(v1.1.5 both tracks; MR !34430 waiting on linsui; Play Console still user's turn).

## Where we are
- **Full UI redesign is committed and pushed** to `origin/main` as a 12-commit
  series ending `ddac5ad` (theme/tokens, StampChip, shell, inbox card stack,
  scan flow + MetadataSheet, library, chat+settings, verify-creds, chores,
  docs, scripts, tests). A prior single-snapshot history by another session was
  rewritten locally before push (all was unpushed; final tree verified identical).
- **Document detail redesign committed** (`596436c`, local): correspondent/
  type/date/tags → one summary card + "Edit details" opening the shared
  MetadataSheet; one batched PATCH of changed fields only. Storage path, ASN,
  scan-date shortcut stay inline. `_TagsSection` removed.
  **NOT yet pushed** at time of writing.
- Device-verified on rango in light+dark: shell nav, inbox stack, library,
  scanner, chat, settings, detail. Gate green throughout (analyze clean,
  193 tests).

## Fixed along the way
- Stale-build trap: a killed debug build corrupted intermediates → release APK
  compiled OLD dart with NEW assets (tofu icons, old UI). Fix: `flutter clean`
  rebuild. Lesson: if the device UI contradicts source, `strings libapp.so`
  for new-only vs old-only UI strings.
- Inbox "Details" button wrapped ("Detai/ls") — Edit/Details no longer Expanded.
- AI chat "not logged in": paperless-ai requires auth for RAG too; settings copy
  fixed and credentials dialog is now **Verify & save** (live login, inline
  error, saves only on success). User's chat works; remaining "error occured
  while generating an answer" is paperless-ai server-side (LLM/RAG backend).

## Remaining backlog
1. Login screen restyle (restyle-only; inherits theme already).
2. Library edit flow → adopt MetadataSheet.
3. Optional: trim the 11-item detail overflow menu (design decision pending).
4. Saved-view stamp carousel didn't show on device — confirm user has saved
   views with show-on-dashboard/sidebar flags; may be fine.

## Device/test gotchas (rango, Pixel 10 Pro Fold)
- Package `com.ventouxlabs.paperlessgo`, activity
  `com.ventoux.paperlessgo.MainActivity` (namespace ≠ appId). Old
  `com.ventoux.paperlessgo` package UNINSTALLED — stale-task confusion gone.
- After install: `am force-stop` then `am start`, else Android restores stale task.
- screencap needs `-d 4619827677550801153` (1080×2364 panel); check both IDs if
  black. `uiautomator dump` is the ground truth when screenshots mislead.
- adb can drop to "insufficient permissions" after device re-enumeration —
  `adb kill-server && adb start-server`.
- Nav tap targets (1080-wide): Inbox 135, Library 405, Scan 675@y2258, Chat 945,
  all y≈2270. Library settings gear ≈ (989, 267).
- DO NOT `dart format`; build_runner orchestrator-only; CI = analyze + test.
