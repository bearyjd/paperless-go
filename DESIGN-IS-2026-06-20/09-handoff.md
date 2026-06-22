> ⚠️ **Superseded by [`10-handoff.md`](10-handoff.md)** — read that one. (v1.1.4 is now
> released on both GitHub *and* GitLab/F-Droid; F-Droid package is `com.ventouxlabs.paperlessgo.nogoogle`.)

# 09 — Session Handoff (2026-06-21) — Play submission ready (new package + live demo)

**Self-contained cold-pickup doc. Supersedes `08-handoff.md`** (read only this one).

## TL;DR — where we are
- **Package name changed.** `com.ventoux.paperlessgo` is **permanently burned on Play**
  (it already has an internal-testing upload, which reserves the name forever). The
  app's `applicationId` is now **`com.ventouxlabs.paperlessgo`** (commit `c84d0c5`,
  **local only — not pushed yet**). Signed AAB rebuilt and **on-device verified** on
  the Pixel 10 Pro Fold.
- **Reviewer demo server is LIVE & verified**: stable Cloudflare named tunnel at
  **https://paperless-demo.ventouxlabs.com**, running on `.23`. TLS + reviewer login +
  3 docs confirmed both via API and through the real app on-device.
- **All Play artifacts staged**: listing, privacy (hosted), data-safety, app-access
  blurb, icon, feature graphic, **5 screenshots**.
- **Promo video built** (Remotion): `~/paperless-go-promo/out/promo.mp4`.
- **NEXT: Console data entry** — create the app under the new package, upload the AAB,
  paste the staged copy, run data-safety + content rating, submit.

## Git / build state
- `main` HEAD = **`c84d0c5`**, **ahead of `origin/main` (`7d3e879`) by 1 — NOT pushed.**
  Push when ready: `git push origin main`.
- Uncommitted: **`play-store/upload/`** (icon, feature graphic, 5 screenshots) — left
  untracked deliberately; `git add play-store/upload` if you want them versioned.
- `gh-pages` branch (pushed) hosts the privacy policy via GitHub Pages.
- Version **`1.1.4+9`**. Signed AAB (now `com.ventouxlabs.paperlessgo`):
  `build/app/outputs/bundle/release/app-release.aab`.
- Build: AAB `flutter build appbundle --release --obfuscate --split-debug-info=./debug-info/`
  (APK: same with `apk`). Keystore `~/keys/paperless-go/paperless-go-release.jks`.

## ★ Package name — read before re-building
- **applicationId = `com.ventouxlabs.paperlessgo`** (Play identity). The burned
  `com.ventoux.paperlessgo` can never be reused on any account.
- **namespace STAYS `com.ventoux.paperlessgo`** (internal code package: Kotlin dirs,
  `MainActivity`, `PaperlessWidget`, the `com.ventoux.paperlessgo/pdf_renderer`
  MethodChannel). Decoupled on purpose — only `android/app/build.gradle.kts:39`
  changed. Verified working at runtime on-device (foreground activity =
  `com.ventouxlabs.paperlessgo/com.ventoux.paperlessgo.MainActivity`).
- **F-Droid (gitlab) keeps `com.ventoux.paperlessgo`** — separate store/build,
  intentional divergence. Do NOT touch F-Droid metadata or README badges.
- This new name gets permanently burned on its first upload — don't waste it on a
  throwaway under a different identity.

## ★ Reviewer demo server (satisfies Play "App access")
- **Host: `.23` (192.168.1.23, hostname `dev`)** — always-on Docker host;
  `ssh 192.168.1.23` (key auth). Stack at `~/paperless-go-demo/` on that box.
- Stack: sqlite Paperless-ngx + redis + cloudflared (one `docker compose`). Local
  port 8010. 3 sample docs, **enriched** with correspondents/types/tags so it reads as
  a real archive.
- **Public URL: https://paperless-demo.ventouxlabs.com** — Cloudflare **named** tunnel
  (id `c46f3b11-…`), survives restarts. Dashboard public-hostname → service
  **`http://webserver:8000`** (cloudflared runs in the compose network).
  `ventouxlabs.com` is an active Cloudflare zone. Tunnel token in `.env` on .23
  (`TUNNEL_TOKEN`, chmod 600, NOT in git).
- **Reviewer login: `reviewer` / `930dd7d155ef3c1c807e7cfa`** (in `.env`).
- Why the tunnel: the app does **strict TLS** (no self-signed bypass) and the shipped
  build **blocks cleartext** — reviewers need publicly-trusted HTTPS, which this gives.
- **Tear down after review**: on .23 `docker compose down -v` + delete the public
  hostname and tunnel in Cloudflare.

## Google Play submission — what's left (all Console data entry)
Publishing as Ventoux **Organization**. App is brand-new — create it; first AAB
upload registers `com.ventouxlabs.paperlessgo`. The old `com.ventoux.paperlessgo`
draft in Console is a dead end (delete or ignore).
1. **Create app** → upload `app-release.aab`.
2. **Main store listing** → paste from `play-store/listing.md`. Graphics from
   `play-store/upload/`.
3. **Privacy policy URL**: **https://bearyjd.github.io/paperless-go/privacy-policy.html**
4. **Data safety** → transcribe `play-store/data-safety.md` (no data collected by the
   developer; encrypted in transit — the shipped build is HTTPS-only).
5. **Content rating** (IARC) → expect **Everyone**.
6. **App access** → "All or some functionality is restricted" + paste the blurb below.
7. **Submit.** Full tracker: `play-store/SUBMISSION_CHECKLIST.md`.

App-access blurb (paste into Console — NOT into git):
```
Paperless Go is a client for the self-hosted Paperless-ngx server. It has no
backend of its own and requires a server to sign in. Demo server for review:

  Server URL: https://paperless-demo.ventouxlabs.com
  Username:   reviewer
  Password:   930dd7d155ef3c1c807e7cfa

To review: launch the app, enter the Server URL on the login screen, sign in,
then browse and search documents and try Scan/Upload. The account is preloaded
with sample documents.
```

## Play graphic assets (`play-store/upload/`, uncommitted)
- `icon-512.png` — 512², 32-bit opaque, flattened on brand green `#17A262`.
- `feature-graphic-1024x500.png` — 1024×500, no alpha.
- Screenshots (all 1300×2400, device-framed + captioned, ≤2:1, no alpha):
  `screenshot-1-document_list`, `-2-scan_upload`, `-3-ai_chat`, `-4-login`,
  `-5-document_detail`.
- Console shows screenshots in **upload order**; reorder there if you want the detail
  before the login shot. Re-frame helper: `scripts/frame-screenshots.py`.

## Promo video
- Remotion project: **`~/paperless-go-promo/`** (OUTSIDE the repo). Render:
  `cd ~/paperless-go-promo && npx remotion render Promo out/promo.mp4 --codec=h264 --crf=18`.
- Output `out/promo.mp4` (1920×1080, ~21.7s): intro → 4 feature scenes (document list,
  scan, AI chat, **document detail / "your server"**) → "Free & open source" outro.
  Source frames in `public/shots/` (raw screenshots, incl. `document_detail.png`).
- Play "promo video" is a **YouTube URL** field (optional) — upload to YouTube and
  paste the link; there's nothing to upload to Play directly.

## Known issues / gotchas
- **Login offers `http://` but the shipped build blocks cleartext** (Android 9+,
  targetSdk ≥ 28, no `usesCleartextTraffic`) → `http://` LAN servers silently fail.
  UX bug, **non-blocking** for Play. Memory: `project_cleartext_http_login_bug`.
- **DO NOT run `dart format`** — repo isn't format-clean; surgical edits only. CI =
  analyze + test.
- `claude-mem` PostToolUse hook prints a harmless `Malformed JSON at stdin EOF` on
  multi-line edits.
- On-device (Pixel Folds `comet`=Pixel 9, `rango`=Pixel 10, IDs `4A111FDKD0000C` /
  `57211FDCG0023C`): screencap **to a device file then pull** (piped exec-out is
  corrupted by the multi-display warning); release-signed `adb install -r` keeps login;
  tap targeting is flaky → locate widgets via PIL on the screenshot. The new package is
  a **fresh install** (different id from any existing `com.ventoux.paperlessgo`). The
  app caches offline — to see server-side metadata changes, force-stop + relaunch (cold
  start re-fetches; a list pull-to-refresh alone wasn't enough).

## What shipped this session
- `7d3e879` (pushed): finalize Play listing/privacy/data-safety, host privacy policy on
  `gh-pages`, add `play-store/SUBMISSION_CHECKLIST.md`; consolidated root docs as
  superseded.
- `c84d0c5` (**local only, not pushed**): applicationId → `com.ventouxlabs.paperlessgo`.
- Uncommitted: `play-store/upload/` graphics (icon, feature graphic, 5 screenshots).
- Off-repo: reviewer demo deployed on `.23` + live named tunnel; Remotion promo video
  in `~/paperless-go-promo/`; demo docs enriched with correspondents/types/tags.
