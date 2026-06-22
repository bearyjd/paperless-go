# 11 — Session Handoff (2026-06-21) — v1.1.4 out on both; F-Droid MR updated

**Self-contained cold-pickup doc. Supersedes `10-handoff.md`** (read only this one).

## TL;DR — where we are
- **v1.1.4 released on both remotes** and the **F-Droid fdroiddata MR is updated** to the
  new package. Two intentionally-distinct packages (coexist on one device):
  - **Play / Google** (`origin`/GitHub): `com.ventouxlabs.paperlessgo` — GitHub Release
    published (signed APK + AAB).
  - **F-Droid / degoogled** (`gitlab`): `com.ventouxlabs.paperlessgo.nogoogle` —
    `gitlab/main` = `28e9991`, tag `v1.1.4`; fdroiddata MR !34430 now points at it.
  - `namespace` is `com.ventoux.paperlessgo` on both (internal). Original
    `com.ventoux.paperlessgo` is **burned on Play** (don't reuse).
- **Reviewer demo live & device-verified:** `https://paperless-demo.ventouxlabs.com`.
- **NEXT (both external, not code):** (1) Play Console submission; (2) F-Droid maintainers
  review/merge MR !34430.

## Release state
- `origin/main` = `04ffa99` (handoff 10 committed). Tag **`v1.1.4`** → GitHub Release
  **published** with `app-release.apk` + `app-release.aab`. Package `com.ventouxlabs.paperlessgo`.
- `gitlab/main` = `28e9991`, tag **`v1.1.4`**. Package `com.ventouxlabs.paperlessgo.nogoogle`.
- Working tree clean. Version `1.1.4+9`. Privacy policy hosted on `gh-pages`.

## ★ F-Droid / fdroiddata MR (updated this session)
- **MR:** `fdroid/fdroiddata` **!34430** — "New app: Paperless Go (com.ventouxlabs.paperlessgo.nogoogle)".
  Source fork **`selector4560/fdroiddata`**, branch **`add-paperless-go`**. `glab` is authed
  as `selector4560` (can push to that fork).
- **Done (commit `c7cf6930` on the fork branch):** recipe renamed
  `metadata/com.ventoux.paperlessgo.yml` → `metadata/com.ventouxlabs.paperlessgo.nogoogle.yml`;
  `Repo`+`SourceCode` → GitLab, `IssueTracker` → github; builds **1.1.4** (versionCode
  `91/92/93`) from GitLab commit `28e9991`; degoogle prebuild (strip ML Kit/cunning + swap
  stubs) kept; `CurrentVersion 1.1.4` / `93`. MR title + body updated to the new package.
- **Left to F-Droid:** maintainers review + merge; watch the MR's fdroiddata CI build (clones
  GitLab @ `28e9991`, runs prebuild, builds the `.nogoogle` APK). Optional: leave an MR comment
  noting the rename + GitLab repoint for reviewers. **Still not merged.**

## ★ Play Console (still your turn — app not created yet under new package)
1. Create app → upload AAB (from the GitHub Release, or `build/app/outputs/bundle/release/app-release.aab`).
2. Listing + 5 screenshots from `play-store/` & `play-store/upload/`; privacy URL
   `https://bearyjd.github.io/paperless-go/privacy-policy.html`; data-safety; IARC; App access.
3. Tracker: `play-store/SUBMISSION_CHECKLIST.md`. App-access blurb + creds below.

## Reviewer demo (live)
- Host `.23` (`ssh 192.168.1.23`, hostname `dev`), stack `~/paperless-go-demo/`, named
  Cloudflare tunnel → `http://webserver:8000`, token in `.23:.env` (chmod 600, not in git).
- `https://paperless-demo.ventouxlabs.com` · `reviewer` / `930dd7d155ef3c1c807e7cfa` · 3 docs
  enriched with correspondents/types/tags · device-verified on Pixel 10 Pro Fold (`rango`).
- App-access blurb (paste into Console, NOT git):
```
Paperless Go is a client for the self-hosted Paperless-ngx server. It has no backend of
its own and requires a server to sign in. Demo server for review:
  Server URL: https://paperless-demo.ventouxlabs.com
  Username:   reviewer
  Password:   930dd7d155ef3c1c807e7cfa
Launch the app, enter the Server URL, sign in, then browse/search and try Scan/Upload.
```
- Tear down after review: on `.23` `docker compose down -v` + delete the tunnel + public hostname.

## Promo video
- Remotion project `~/paperless-go-promo/` (outside repo) → `out/promo.mp4` (1920×1080, ~21.7s):
  doc list → scan → AI chat → **document detail** → "Free & open source". Re-render:
  `npx remotion render Promo out/promo.mp4 --codec=h264 --crf=18`. Play promo field = a YouTube URL.

## Working-style note
- **Delegate mechanical work to subagents** (Opus coordinates/decides; Sonnet/Haiku do recon,
  generation, adb/screenshots, git/API mechanics). Memory `feedback_delegate_mechanical_to_subagents`.

## Gotchas
- **DO NOT `dart format`** — repo isn't format-clean; surgical edits only. CI = analyze + test.
- **glab:** token is in keyring/oauth, NOT the config file (don't scrape it); `glab api --input`
  does **not** set a JSON content-type for PUT → 415, use `-F field=@file` for PUT/POST-with-fields
  (POST commits via `--input <file>` are fine). Recorded in `project_remotes_github_gitlab`.
- Login offers `http://` but shipped build blocks cleartext (Android 9+) → LAN http silently
  fails. UX bug, non-blocking. Memory `project_cleartext_http_login_bug`.
- App caches offline → to see server-side metadata changes on device, **force-stop + relaunch**.
- Pixel Folds (`comet`=9, `rango`=10): screencap to a device file then pull; tap targeting flaky
  → locate via PIL on the screenshot.
- `claude-mem` hook prints harmless `Malformed JSON at stdin EOF` on multi-line edits.

## What shipped this session (beyond 10)
- fdroiddata MR !34430 updated to `com.ventouxlabs.paperlessgo.nogoogle` (recipe renamed +
  repointed to GitLab + 1.1.4 builds; MR title/body updated) — commit `c7cf6930` on the fork.
- Memory: `project_remotes_github_gitlab` updated with MR coordinates + glab gotchas.
- Global learned skill added earlier this session: `git-tree-overlay-sync-unrelated-histories`.
