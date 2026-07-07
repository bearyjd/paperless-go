# 12 — Session Handoff (2026-07-06) — v1.1.5 released; F-Droid font blocker answered

**Self-contained cold-pickup doc. Supersedes `11-handoff.md`** (read only this one).

## TL;DR — where we are
- **linsui's font blocker on MR !34430 is resolved and answered.** They had commented
  (2026-06-21): "It downloads fonts from google on start. Please embed them in the apk."
  The fix (`ed0ad3d` — Inter bundled as a variable font asset, `google_fonts` runtime
  fetch removed) already existed but shipped inside a build still labeled 1.1.4, so we
  cut **v1.1.5** to make it unambiguous, updated the MR, and replied.
- **v1.1.5 released on both remotes:**
  - **Play / Google** (`origin`/GitHub, `com.ventouxlabs.paperlessgo`): `main` = `5cef662`,
    tag `v1.1.5`. Release workflow run `28833009305` **succeeded** — GitHub Release
    v1.1.5 is published with `app-release.apk` + `app-release.aab`.
  - **F-Droid / degoogled** (`gitlab` = `selector4560/paperless-go`,
    `com.ventouxlabs.paperlessgo.nogoogle`): `gitlab/main` = `eceb0b9`, tag `v1.1.5`.
- **NEXT (both external, not code):** (1) F-Droid maintainers test/merge !34430 — ball is
  in their court now; (2) Play Console submission — **use the 1.1.5 AAB**, not 1.1.4.

## What shipped this session (beyond 11)
- `5cef662` on `main`: pubspec → `1.1.5+10`, CHANGELOG 1.1.5 entry, fastlane
  `changelogs/10.txt` ("Inter font bundled, nothing downloaded from Google at runtime").
- GitLab sync: cherry-picked `5cef662` onto `28e9991` → `eceb0b9`, pushed as `gitlab/main`
  + tag `v1.1.5` (tag pushed by SHA refspec since local `v1.1.5` points at the GitHub
  commit). Verified tree delta main↔gitlab is only the expected 5 degoogled files
  (build.gradle.kts applicationId, metadata yml name, handoff docs).
- fdroiddata fork (`selector4560/fdroiddata`, branch `add-paperless-go`): commit
  `c3f78f8c` — all 3 builds → `1.1.5`, versionCodes **101/102/103**, pinned to
  `eceb0b945e03d7fe8092d15e92d3cc8167f57b84`; `CurrentVersion: 1.1.5` / `103`.
  MR !34430 picked it up automatically.
- MR reply posted (note `3530118568`) telling linsui fonts are embedded and the MR now
  points at 1.1.5. Label was still `waiting-on-response` at session end — linsui should
  clear it on triage. linsui had also said (06-20) the MR is "mostly ready", will merge
  after testing, but their test queue is long.

## Release state
- Version `1.1.5+10`. Version-code scheme: `versionCode * 10 + abi` (arm=1, arm64=2,
  x86_64=3) → 101/102/103. Recorded in `android/app/build.gradle.kts`.
- `origin/main` = `5cef662`, `gitlab/main` = `eceb0b9`, both tagged `v1.1.5`.
- Working tree clean except untracked `run-paperless-fable.sh` (pre-existing, not part
  of any release — decide keep/delete/commit).
- Font fix content note: `28e9991` (the old 1.1.4 gitlab commit) *already contained* the
  bundled font — commit ancestry lies here because the gitlab branch is an
  unrelated-history overlay sync; always compare **trees**, not ancestry.

## ★ Play Console (still your turn — app not created yet under new package)
1. Create app → upload the **1.1.5 AAB** (from the GitHub Release once workflow
   finishes, or `build/app/outputs/bundle/release/app-release.aab`).
2. Listing + 5 screenshots from `play-store/` & `play-store/upload/`; privacy URL
   `https://bearyjd.github.io/paperless-go/privacy-policy.html`; data-safety; IARC;
   App access. Tracker: `play-store/SUBMISSION_CHECKLIST.md`.
3. Reviewer demo still live for App access: `https://paperless-demo.ventouxlabs.com` ·
   `reviewer` / `930dd7d155ef3c1c807e7cfa` (blurb in handoff 11 §Reviewer demo; tear
   down after review: on `.23` `docker compose down -v` + delete tunnel).

## Gotchas (carried forward + new)
- **DO NOT `dart format`** — repo isn't format-clean; surgical edits only. CI = analyze + test.
- **glab API:** `--input` does NOT set a JSON content-type on notes POST → 415
  (hit again this session). Use `-F body=@file`. POST /repository/commits via
  `--input <json>` *does* work.
- Recipe edits are done via GitLab API against the fork — **no local fdroiddata clone
  exists** on this machine.
- In-repo `metadata/com.ventouxlabs.paperlessgo.nogoogle.yml` (on the gitlab branch) is
  **stale** (still shows 1.1.2) — the authoritative recipe lives on the fdroiddata fork.
- Fastlane changelogs are keyed by *base* versionCode (`10.txt`, not 101/102/103).
  Files 8.txt/9.txt were never created (pre-existing gap).
- Login offers `http://` but shipped build blocks cleartext → LAN http silently fails.
  UX bug, non-blocking.
- Pixel Folds (`comet`=9, `rango`=10): screencap to device file then pull; tap targeting
  flaky → locate via PIL on the screenshot.

## Working-style note
- **Delegate mechanical work to subagents** (Opus coordinates/decides; cheaper models do
  recon, generation, adb/screenshots, git/API mechanics).
