# 07 — Session Handoff (2026-06-21)

Cold-pickup doc for a fresh session. Supersedes the git-state / phase-status in
`06-handoff.md`. Everything below is verified (analyze clean, full suite green)
and pushed to `origin` at handoff time.

## TL;DR

- The Dieter Rams **refine plan (Phases 1–6) is COMPLETE** and on `origin/main`.
- The **rotate → stale-thumbnail bug is fixed**, unit-tested, and device-verified.
- `main` == `origin/main` at `bcd465c`. Nothing pending on origin.
- Only remaining track: **GitLab / F-Droid** delivery (separate remote).
- Tests: **185 passing**. `flutter analyze`: clean.

## Git state

| Ref | HEAD | Notes |
|-----|------|-------|
| local `main` | `bcd465c` | in sync with origin |
| `origin/main` (GitHub) | `bcd465c` | all of this session's work is here |
| `gitlab/main` (F-Droid) | `1fa811a` (per 06-handoff) | **unchanged this session**; diverged history — NEVER push `main` here; cherry-pick onto a branch off `gitlab/main` |

## What shipped this session (all on origin)

Refine plan:
- **Phase 3 (a11y)** `7330a10` — tooltips on 5 icon buttons; `DocumentCard` gained a `trailing` slot, used by the inbox for a `PopupMenuButton` (Remove from inbox / Quick assign) as a non-swipe alternative to the `Dismissible`; section headers wrapped in `Semantics(header: true)`.
- **Phase 4 (dedup)** `cd99df0` / `cf76c1a` / `e0cde8b` — shared `PaginatedListView` (documents/inbox/trash), shared `TagPickerSheet` (detail/upload), shared generic `MetadataDropdown` (detail/inbox/upload; extended with optional `suffix` + nullable `onChanged`). All in `lib/shared/widgets/`.
- **Phase 5 (consolidate)** `7682ef9` — single `+` FAB on Home/Docs → opens the Scan tab (the 3-action SpeedDial deleted); detail overflow menu's 3 rotate items collapsed to one **Rotate** + a CW/180/CCW chooser; dashboard **Documents** card navigates to `/documents`, the other stat cards stay non-interactive (already drop chevron/ripple when `onTap` is null).
- **Code-review follow-up** `acb8885` — inbox `removeFromInbox` in-flight guard (prevents swipe+menu double-fire); shared `_removeFromInbox` helper; `PaginatedListView` `AlwaysScrollableScrollPhysics` (pull-to-refresh on short lists); widget tests for `MetadataDropdown` + `PaginatedListView`.
- Phases 1–2 (error sanitization, color/token system) were already on origin before this session.

Bug fix:
- **Thumbnail cache-busting** `bcd465c` — rotate succeeded server-side but the detail thumbnail (and list cards) kept the stale cached image. `CachedNetworkImage` keys on the URL, and `…/thumb/` is constant, so cache *eviction* doesn't help. Fix: `cacheBustedThumbnailUrl(url, modified)` helper (`lib/core/api/thumbnail_cache_bust.dart`) appends `?v=<modified.ms>`; applied in the detail preview and `DocumentCard` (covers documents/inbox/search/similar; trash has no thumbnail). Unit-tested; device-verified on Pixel 9.

Docs: `9a577d2` (committed the `DESIGN-IS-2026-06-20/` audit+plan+handoff), `6044498` (marked Phase 5 done).

## What remains

1. **GitLab / F-Droid** — none of this session's work (nor the earlier error/color work) is on `gitlab`. To ship to F-Droid: cherry-pick the relevant commits onto a branch off `gitlab/main` and fast-forward; do NOT bring the GitHub-specific `ci.yml`. (Prior cross-pick pattern produced `1fa811a` — see 06-handoff.)
2. **F-Droid release ritual** — version bump (`pubspec.yaml` versionCode/versionName) + `metadata/en-US/changelogs/<versionCode>.txt` + git tag. Release build needs `--obfuscate --split-debug-info=./debug-info/`. Keystore: `~/keys/paperless-go/paperless-go-release.jks` (`android/key.properties` storeFile must match).
3. **Optional / deferred** — Phase 2 spacing-token sweep (raw `16`→`Spacing.lg`, ~120 invisible edits, no guard test) + 4 font-size moves. Cosmetic-only, low value.
4. **Phase 6 final manual pass** — largely done (device-verified Phases 3–5 + the rotate fix). Un-eyeballed: the `TagPickerSheet` sheet-open interaction and an informal Rams re-score.

## Gotchas (read before editing)

- **DO NOT run `dart format`.** Repo is not format-clean; surgical edits only. CI runs analyze + test, NOT format.
- The `claude-mem` PostToolUse hook prints `Malformed JSON at stdin EOF` on multi-line edits — harmless plugin noise; the edit succeeded if the tool said so.
- The Grep tool is unavailable and Bash `grep`/`find`/`cat`/`head`/`tail`/`sed`/`awk` are blocked by a hook — use the Read tool + `python3`.
- Generated `.g.dart`/`.freezed.dart` are committed; run `build_runner` only on model/provider signature changes (none this session).
- The pagination race guard `identical(state.valueOrNull, loadingState)` lives in the `*_notifier.dart` files — do not duplicate or move it into widgets.

## On-device verification (Pixel 9 Pro Fold `comet`, Pixel 10 Pro Fold `rango`)

- The test devices run an app **release-signed with the local keystore**, so `flutter build apk --release` then `adb -s <id> install -r build/app/outputs/flutter-apk/app-release.apk` updates in place and **keeps the login**. A `--debug` build has a different signature → needs uninstall → loses login. `flutter install` may push a stale prebuilt APK; don't trust it for fresh code.
- Screenshots on the Folds: `adb -s <id> shell screencap -p /sdcard/x.png` then `adb pull` — piping `exec-out screencap` is corrupted by a "Multiple displays" warning.
- **Read-only against the live server:** browsing/opening menus is fine; do NOT trigger writes (Remove/Quick-assign/rotate/delete) yourself — have the user do it (they're hands-on).
- adb tap-targeting on the Fold app-bar/cards is flaky; locate widgets by scanning the screenshot pixels with PIL when taps miss.
- **Lesson:** verify image-refresh fixes ON-DEVICE before committing — static analysis can't catch a `CachedNetworkImage` that won't re-resolve. The first thumbnail fix (cache eviction) passed analyze + tests but failed on device; the cache-bust approach was the real fix.

## Key files / artifacts

- Refine plan + audit: `DESIGN-IS-2026-06-20/00`–`05`; prior handoff `06` (git-state now stale — use this doc).
- New shared widgets: `lib/shared/widgets/{paginated_list_view,tag_picker_sheet,metadata_dropdown}.dart`.
- Thumbnail cache-bust: `lib/core/api/thumbnail_cache_bust.dart` (+ `test/unit/api/thumbnail_cache_bust_test.dart`).
