# 10 — Session Handoff (2026-06-21) — v1.1.4 released on both tracks

**Self-contained cold-pickup doc. Supersedes `09-handoff.md`** (read only this one).

## TL;DR — where we are
- **v1.1.4 is RELEASED on both remotes.**
  - **GitHub / Play build** (`com.ventouxlabs.paperlessgo`): tag `v1.1.4` → `d8f3241`,
    `release.yml` CI built the **signed APK + AAB** and **published the GitHub Release**.
  - **GitLab / F-Droid build** (`com.ventouxlabs.paperlessgo.nogoogle`): `gitlab/main` =
    `28e9991`, tag `v1.1.4`, recipe renamed + repointed to GitLab.
- **Two intentionally-distinct packages now** (they coexist on one device):
  Play `com.ventouxlabs.paperlessgo`, F-Droid `com.ventouxlabs.paperlessgo.nogoogle`.
  `namespace` stays `com.ventoux.paperlessgo` on both. Original `com.ventoux.paperlessgo`
  is **burned on Play** (don't reuse).
- **Reviewer demo is live & device-verified** at `https://paperless-demo.ventouxlabs.com`.
- **NEXT (both stores, your turn):** Play Console submission + the F-Droid fdroiddata MR.

## Git / release state
- `origin/main` = `d8f3241` (pushed). Tag **`v1.1.4`** → `eb09cb4`; **GitHub Release
  published** with `app-release.apk` + `app-release.aab`.
- `gitlab/main` = `28e9991` (pushed). Tag **`v1.1.4`** on GitLab → `28e9991`.
- Working tree clean. Version `1.1.4+9`.
- `gh-pages` (GitHub) hosts the privacy policy.

## Package strategy (final)
| Track | Repo | applicationId | namespace |
|---|---|---|---|
| Play / Google | `origin` (GitHub) | `com.ventouxlabs.paperlessgo` | `com.ventoux.paperlessgo` |
| F-Droid (degoogled) | `gitlab` | `com.ventouxlabs.paperlessgo.nogoogle` | `com.ventoux.paperlessgo` |

- Only `applicationId` + the renamed recipe differ between the two source trees; ML Kit /
  `cunning_document_scanner` stay in source and are stripped + stubbed at **F-Droid build
  time** by the recipe prebuild.
- **F-Droid builds FROM GitLab.** The in-repo recipe copies historically said `Repo: github`
  (stale); the updated recipe `metadata/com.ventouxlabs.paperlessgo.nogoogle.yml` sets
  `Repo:` → GitLab. **Confirm the live fdroiddata recipe matches.**
- Histories are **unrelated** (no merge-base). The GitLab sync was done via a tree-overlay
  commit (tree = `origin/main` + edits, parent = `gitlab/main`, fast-forward push) — see the
  global learned skill `git-tree-overlay-sync-unrelated-histories` and memory
  `project_remotes_github_gitlab`.

## What's left — both your turn
**Play Console** (app not created yet under the new package):
1. Create app → upload the AAB (from the GitHub Release, or `build/app/outputs/bundle/release/app-release.aab`).
2. Listing/graphics from `play-store/` + `play-store/upload/` (5 screenshots incl. document-detail).
3. Privacy URL `https://bearyjd.github.io/paperless-go/privacy-policy.html`; data-safety; IARC; App access blurb.
4. Full tracker: `play-store/SUBMISSION_CHECKLIST.md`. (App-access blurb + reviewer creds below.)

**F-Droid / fdroiddata MR** (not merged yet → clean to set up):
1. Rename the live recipe to `com.ventouxlabs.paperlessgo.nogoogle.yml`, confirm `Repo:` → GitLab,
   add/clean a 1.1.4 build template (recipe still lists 1.1.2 entries; `AutoUpdateMode: Version`
   + `UpdateCheckMode: Tags` will extrapolate from the `v1.1.4` GitLab tag).
2. Submit/update the MR under the new package id.

**Demo server:** tear down after review — on `.23` `docker compose down -v` + delete the
Cloudflare public hostname + tunnel.

## Reviewer demo (live)
- Host **`.23`** (`ssh 192.168.1.23`, hostname `dev`), stack at `~/paperless-go-demo/`.
  Named Cloudflare tunnel → `http://webserver:8000`. Token in `.23:.env` (chmod 600, not in git).
- URL `https://paperless-demo.ventouxlabs.com` · login `reviewer` / `930dd7d155ef3c1c807e7cfa`.
- 3 sample docs, **enriched** with correspondents/types/tags (ACME/Invoice, Riverside/Utility,
  Northwind/Letter). Device-verified on the Pixel 10 Pro Fold (`rango`): login over the tunnel
  (strict TLS) + dashboard + docs all work.
- App-access blurb (paste into Console, NOT git):
```
Paperless Go is a client for the self-hosted Paperless-ngx server. It has no backend of
its own and requires a server to sign in. Demo server for review:
  Server URL: https://paperless-demo.ventouxlabs.com
  Username:   reviewer
  Password:   930dd7d155ef3c1c807e7cfa
Launch the app, enter the Server URL, sign in, then browse/search and try Scan/Upload.
```

## Promo video
- Remotion project `~/paperless-go-promo/` (outside repo). Output `out/promo.mp4`
  (1920×1080, ~21.7s). Scenes: doc list → scan → AI chat → **document detail** ("your
  server") → "Free & open source". Re-render: `npx remotion render Promo out/promo.mp4 --codec=h264 --crf=18`.
- Play promo field = a **YouTube URL** (optional); upload to YouTube, paste the link.

## Working-style note (new)
- **Delegate mechanical work to subagents.** Opus coordinates/decides; Sonnet/Haiku do
  recon, file/asset generation, adb + screenshot inspection (Sonnet is vision-capable),
  and git mechanics. Memory: `feedback_delegate_mechanical_to_subagents`. (This session ran
  too much inline in Opus.)

## Gotchas (still apply)
- **DO NOT `dart format`** — repo isn't format-clean; surgical edits only. CI = analyze + test.
- Login offers `http://` but the shipped build blocks cleartext (Android 9+) → LAN http
  servers silently fail. UX bug, non-blocking. Memory `project_cleartext_http_login_bug`.
- App caches offline → to see server-side metadata changes on device, **force-stop +
  relaunch** (a list pull-to-refresh wasn't enough).
- Pixel Folds (`comet`=9 `4A111FDKD0000C`, `rango`=10 `57211FDCG0023C`): screencap **to a
  device file then pull**; tap targeting flaky → locate via PIL on the screenshot.
- `claude-mem` hook prints harmless `Malformed JSON at stdin EOF` on multi-line edits.

## What shipped this session (beyond 09)
- GitHub `v1.1.4` tag/release (signed APK+AAB published).
- GitLab `main` `28e9991` + tag `v1.1.4` (degoogled `.nogoogle`, recipe renamed, Repo→GitLab).
- Demo docs enriched; on-device verification on Pixel 10.
- Promo scene 4 swapped login → document detail; Play screenshot set grown to 5.
- Memory: updated `project_remotes_github_gitlab`; added `feedback_delegate_mechanical_to_subagents`.
- Global learned skill: `~/.claude/skills/learned/git-tree-overlay-sync-unrelated-histories.md`.
