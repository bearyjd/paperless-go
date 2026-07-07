# 13 — Session Handoff (2026-07-07) — UI/UX redesign pass, uncommitted, device test in progress

**Self-contained cold-pickup doc for the redesign workstream. Supersedes `12-handoff.md`
for redesign work; release/F-Droid state in 12 is still current** (v1.1.5 shipped both
tracks; MR !34430 waiting on linsui; Play Console submission still user's turn).

## TL;DR — where we are
- A **full UI/UX redesign pass is implemented and analyzer-clean but 100% UNCOMMITTED**
  (~36 modified/new files in the working tree). Do not lose this tree.
- A **signed release APK of the redesign is built and installed on rango**
  (Pixel 10 Pro Fold). Fresh launch verified: new login styling renders correctly
  (paper background, Space Grotesk, teal FilledButton).
- **`adb shell pm clear` wiped the device login** during testing — user must log back
  into their Paperless-ngx server on the device before the main screens can be
  screenshotted/reviewed.
- **NEXT:** user logs in on device → screenshot Inbox / Library / Scanner / Chat /
  Settings in light + dark (`adb shell cmd uimode night yes|no`) → review → then commit
  the redesign as a series of logical commits.

## The redesign (approved brief, all implemented)
Goals: one primary action per screen; Inbox as swipeable card stack (right=accept OCR
suggestions, left=edit sheet, tap=detail); bottom nav = Inbox / Library / Chat + raised
circular teal Scan button (no FAB); metadata editing via modal bottom sheet with chips;
scan flow ≤3 taps; search omnibox; filters as stamp pills only when active; saved views
as stamp-chip carousel. Dashboard **retired** — `/` redirects to `/inbox`.

### Foundation (orchestrator-authored, stable — agents were told not to touch)
- `lib/core/design_tokens.dart` — palette + `AppTokens` ThemeExtension
  (paper/card/line/ink/inkSoft/accentFill/**onAccent**/accentEmphasis/accentSoft/stamp).
  `onAccent` exists because dark `ColorScheme.onPrimary` pairs with the brightened teal,
  not the deep fill — use `tokens.onAccent` for anything on `accentFill`.
- `lib/core/theme.dart` — full light/dark ColorScheme mapping, Space Grotesk w600 for
  display/headline/title, Inter body, all component themes, `extensions: [tokens]`.
- `pubspec.yaml` + `assets/fonts/SpaceGrotesk-Variable.ttf` (+ OFL) — bundled, NO
  `google_fonts` (hard F-Droid requirement).
- `lib/app.dart` — Dashboard removed, `/` → `/inbox`, `/inbox` inside ShellRoute, FAB
  gone, custom `_ShellNavBar` (3 items + raised 56dp scan circle).
- `lib/shared/widgets/stamp_chip.dart` — dashed-border pill, −1° tilt, optional server
  color `tint`, `rotated:false` variant.

### Feature screens (3 parallel agents, integrated + reviewed)
- **Inbox** (`inbox_screen.dart` rewrite + `inbox_suggestions_provider.dart` +
  notifier `acceptSuggestions()`/`undoAccept()`) — card stack, swipe physics, OCR
  suggestion StampChips, edit sheet, undo snackbar, on-card buttons as a11y fallback.
- **Scan flow** — camera-first `scanner_screen.dart`; review "Continue" auto-processes
  with `selectedPresetProvider` (plain StateProvider, no codegen) and jumps straight to
  upload; radically simplified `upload_screen.dart`; new reusable
  `lib/shared/widgets/metadata_sheet.dart` (`MetadataSheet`/`MetadataSheetResult`,
  `topSlot` hook for host extras).
- **Library** — `documents_screen.dart` header + omnibox pill + saved-view StampChip
  carousel; `active_filters_bar.dart` dismissible pills; filter sheet + bulk bar + cards
  + skeletons + tag_chip restyled. Selection UI lives in the header (accepted deviation).
- **Chat + Settings** — paper bubbles, pill input, circular send (uses `tokens.onAccent`);
  Settings in 6 bordered-card sections with inline SegmentedButton theme picker.

## Remaining work (in order)
1. **Device review** (blocked on user re-login) — then commit series.
2. **Document detail screen** — biggest untouched surface (11-item menu); should adopt
   `MetadataSheet`. `lib/features/documents/document_detail_screen.dart`.
3. **Login screen** — restyle-only (already looks decent from theme inheritance).
4. **Library → MetadataSheet adoption** — library agent deliberately didn't reference it
   (parallel-work conflict avoidance); safe to adopt now.
5. `AUDIT.md` (repo root) is the step-1 audit doc — decide keep/move/delete at commit time.
6. `run-paperless-fable.sh` untracked, pre-existing — decide keep/delete.

## Device-test gotchas (new this session)
- **Package IDs on rango:** the release build installs to `com.ventouxlabs.paperlessgo`
  (activity `com.ventoux.paperlessgo.MainActivity` — namespace ≠ applicationId).
  A second package `com.ventoux.paperlessgo` (the old burned ID) is ALSO installed —
  launching by monkey/launcher may resurface a *stale task* of the old-looking UI.
  After install: `adb shell am force-stop com.ventouxlabs.paperlessgo` then
  `am start -n com.ventouxlabs.paperlessgo/com.ventoux.paperlessgo.MainActivity`.
  (First screenshots showed the old Dashboard because Android restored the saved task.)
- **Fold displays:** `screencap` needs `-d 4619827677550801153` (inner display id on
  rango); default display gives a black cover-screen image.
- Screencap renders Material icon glyphs as tofu boxes — artifact only, fine on device.
- `pm clear` = wiped credentials; unavoidable to escape restored nav state, but warn user.

## Carried-forward gotchas (still true)
- **DO NOT `dart format`** — repo isn't format-clean; surgical edits only. CI = analyze + test.
- `build_runner` runs by orchestrator only; regen `.g.dart` after provider changes.
- F-Droid recipe lives on the fdroiddata fork (GitLab API, no local clone); glab notes
  POST needs `-F body=@file`.
- Login offers `http://` but release blocks cleartext — known UX bug, non-blocking.

## Working-style note
- Opus/Fable coordinates and decides; delegate mechanical work (adb, screenshots, bulk
  restyles) to cheaper subagents. The 3-agent parallel fan-out worked well — constraints
  files told agents which foundation files were frozen.
