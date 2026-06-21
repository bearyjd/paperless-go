# 08 — Session Handoff (2026-06-21) — Google Play push

**Self-contained cold-pickup doc. Supersedes `06-handoff.md` and `07-handoff.md`**
(read only this one). Everything below is committed and pushed to `origin` at
handoff time; `flutter analyze` is clean and **185 tests pass**.

## TL;DR — where we are

- The Rams **refine plan (Phases 1–6) is DONE** and on `origin/main`.
- The **rotate→stale-thumbnail bug is fixed** (cache-bust on `modified`), unit-tested + device-verified.
- **`google_fonts` removed**; Inter is bundled as a local variable font (no runtime CDN fetch), device-verified.
- **Play Store prep is staged**: version bumped to **1.1.4+9**, a **signed AAB is built**, and listing / data-safety / privacy-policy / release-notes / app-access drafts are written.
- **NEXT GOAL: publish to Google Play under a Ventoux _organization_ account.**

## Git / build state

- `main` is in sync with `origin/main` (GitHub `bearyjd/paperless-go`).
- `gitlab/main` (F-Droid) is on a diverged history — **never push `main` there**; cherry-pick.
- App version: **`1.1.4+9`** (`pubspec.yaml`). versionCode 9.
- Signed AAB (ready to upload): **`build/app/outputs/bundle/release/app-release.aab`**
  (rebuild with the command below if stale). Signed with the release/upload key
  `CN=Paperless Go, O=Grepon` (keystore `~/keys/paperless-go/paperless-go-release.jks`,
  config in `android/app/build.gradle.kts` via `android/key.properties`).
- Build commands:
  - AAB (Play): `flutter build appbundle --release --obfuscate --split-debug-info=./debug-info/`
  - APK (F-Droid/sideload): `flutter build apk --release --obfuscate --split-debug-info=./debug-info/`

---

## ★ PRIORITY: Google Play submission runbook

**Why an org account:** the closed-testing requirement (~12 testers / 14 days
before production) hits **personal** accounts created after Nov 2023.
**Organization accounts are exempt** — register Ventoux as an **Organization** to
skip it. (Confirm exact wording in the Console; policies shift. Read as of early 2026.)

### Steps
1. **Ventoux org developer account** — D-U-N-S number (free, allow days–weeks),
   $25 fee, org legal name/address/website. Register as **Organization** (NOT
   personal). Complete identity/verification.
2. **Package name** `com.ventoux.paperlessgo` — confirm it's free / not burned on
   another account (else need a new `applicationId`).
3. **Upload the AAB** (already built; rebuild if you change code). Bump the version
   in `pubspec.yaml` before any re-upload (each upload needs a higher versionCode).
4. **Play App Signing** — enroll; the release keystore is the **upload** key.
   Note: the Play build is signed by Google's key → different signature than the
   F-Droid/sideload APK (users can't cross-update without uninstalling).
5. **"Set up your app" checklist** — use the drafts in `play-store/` (below).
6. **App access** — paste the reviewer blurb from `play-store/app-access-instructions.md`
   and provide a demo Paperless-ngx server + creds (top rejection cause).
7. **Production release** — upload AAB + "What's new" (from `play-store/release-notes.md`),
   submit. First review on a new account: days to ~2 weeks.

### Play artifacts (all drafted, in `play-store/`)
| File | What it is | Still needs you |
|------|-----------|-----------------|
| `play-store/listing.md` | Title, short/full description, categorization, asset checklist | Contact email, website, **graphic assets** (512 icon, 1024×500 feature graphic, screenshots — scrub real docs) |
| `play-store/privacy-policy.md` | Publishable privacy policy | Fill contact email/URL, then **host it** and use the URL |
| `play-store/data-safety.md` | Data-safety form answers (dep-scan-backed: no analytics/ads/crash SDKs; on-device ML; no CDN font fetch) | Just transcribe into the Console form |
| `play-store/release-notes.md` | "What's new" (≤500 chars) | Paste into the release |
| `play-store/app-access-instructions.md` | Reviewer access blurb | **Stand up a demo server**, fill URL + creds |

**Inline (the two short ones, for convenience):**

_Play "What's new":_
```
• Accessibility: screen-reader labels on icon buttons, a non-swipe menu for inbox actions, and proper heading semantics.
• Simpler scanning and a cleaner document menu (rotate now has a CW/180/CCW chooser).
• Dashboard: the Documents card now opens your library.
• Fixed: a document's thumbnail not updating after you rotate it.
• Privacy: fonts are now bundled in the app — no external font downloads.
```

_App access — provide a demo Paperless-ngx server URL + reviewer username/password;
full blurb in `play-store/app-access-instructions.md`._

---

## F-Droid track (secondary)
- Changelog for build 9 written: `metadata/en-US/changelogs/91.txt`, `92.txt`,
  `93.txt` (per-ABI naming = versionCode 9 ×10 + ABI 1/2/3, matching `81/82/83`).
- Pending: cherry-pick this session's commits onto a branch off `gitlab/main`
  (do NOT bring the GitHub-only `ci.yml`), bump metadata, push a git tag. Release
  APK needs the `--obfuscate --split-debug-info` flags above.

## What shipped this session (all on origin)
- Phase 3 a11y `7330a10`; Phase 4 dedup `cd99df0`/`cf76c1a`/`e0cde8b`; Phase 5
  consolidate `7682ef9`; review follow-up `acb8885`; rotate/thumbnail cache-bust
  `bcd465c`; Inter bundled / google_fonts dropped `ed0ad3d`-era (`refactor: bundle Inter…`);
  version bump + Play docs `f908d94`; plus privacy-policy / data-safety / release-notes /
  app-access / changelog drafts and this handoff.

## Gotchas (read before editing)
- **DO NOT run `dart format`** — repo isn't format-clean; surgical edits only. CI = analyze + test.
- `claude-mem` PostToolUse hook prints `Malformed JSON at stdin EOF` on multi-line edits — harmless.
- Grep tool unavailable + Bash `grep/find/cat/head/tail/sed/awk` blocked by a hook — use Read + `python3`.
- Pagination race guard `identical(state.valueOrNull, loadingState)` lives in `*_notifier.dart` — don't move it.
- New shared widgets: `lib/shared/widgets/{paginated_list_view,tag_picker_sheet,metadata_dropdown}.dart`;
  thumbnail cache-bust: `lib/core/api/thumbnail_cache_bust.dart`; theme/font: `lib/core/theme.dart` + `assets/fonts/`.

## On-device verification (Pixel 9 Pro Fold `comet`, Pixel 10 Pro Fold `rango`)
- Devices run a **release-signed** app (local keystore) → `flutter build apk --release`
  then `adb -s <id> install -r build/app/outputs/flutter-apk/app-release.apk` updates
  in place and **keeps the login**. Debug builds differ in signature (need uninstall).
- Screenshots on the Folds: `adb -s <id> shell screencap -p /sdcard/x.png` then `adb pull`
  (piping `exec-out screencap` is corrupted by a "Multiple displays" warning).
- **Read-only** against the live server: have the **user** trigger writes (rotate/remove/etc.).
- adb tap-targeting on the Fold is flaky — locate widgets via PIL pixel scans of the screenshot.
- **Lesson:** verify image/UI-refresh fixes ON-DEVICE before committing — the first
  thumbnail fix (cache eviction) passed analyze+tests but failed on device; the
  cache-bust was the real fix.
