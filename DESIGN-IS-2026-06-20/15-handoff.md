# 15 — Session Handoff (2026-07-21) — v1.1.6 → v1.1.7 shipped, 3 bugs fixed, F-Droid MR active again

**Supersedes `14-handoff.md`.**

## Where we are
- **v1.1.6 released** (`ec298ce`): the full redesign from handoff 14 (shell, inbox
  card stack, scan flow, library, chat/settings, detail-screen MetadataSheet
  editing) shipped as a tagged GitHub Release with APK+AAB, plus F-Droid
  (`metadata/en-US/changelogs/111-113.txt`) and fastlane (`.../11.txt`)
  changelogs.
- **v1.1.7 released** (`69b7fd2`, tag `v1.1.7`): rolls up three bug fixes (below).
  Installed and version-verified on **both** test devices — Pixel 10 Pro Fold
  (`rango`, `57211FDCG0023C`) and Pixel 9 Pro Fold (`comet`, `4A111FDKD0000C`,
  new this session). F-Droid/fastlane changelogs added
  (`121-123.txt` / `12.txt`).
- **Issue tracker cleaned up:** closed #6, #7, #8, #18 as already resolved by
  prior commits (redesign + detail-screen MetadataSheet + HTTP-mock test
  corpus all landed before this session but issues were never closed).

## Bugs fixed this session
1. **#22 — upload retries had no terminal state** (`5737870`). The 5-retry cap
   already existed but nothing recorded permanent failure, so failed uploads
   sat silently indistinguishable from healthy pending ones. Added `isFailed`
   column (drift schema v6→v7), `incrementRetryCount` now takes `maxRetries`
   and marks it, drain loop skips via the persisted flag. 3 new tests.
2. **#16 — login accepted `http://` then failed confusingly** (`1dad460`). No
   `network_security_config.xml` exists anywhere in the project, so Android's
   default policy blocks cleartext in *every* build variant, not just release
   (the issue's premise that debug permits it was wrong). Form validator and
   the `Test Connection` button now hard-block `http://` upfront with an
   explanation instead of a passive warning. 2 new widget tests.
3. **#15 — "Password protect PDF" never encrypted anything** (`e3c9ba8`).
   `protectPdf` took a password, re-rendered pages, wrote an **unencrypted**
   PDF. Removed the feature entirely rather than patch it: the bundled `pdf`
   package only exposes an abstract `PdfEncryption` extension point with no
   built-in handler; a correct fix means hand-writing an ISO 32000 standard
   security handler (RC4/AES key derivation, O/U entries, per-object
   encryption) from scratch, which needs dedicated security review, not a
   quick fix — a subtly-wrong implementation is worse than none. Filed
   **#23** to plan that properly (found `pointycastle`, MIT/AGPL-compatible,
   has the needed primitives but isn't a dependency yet).

## F-Droid MR !34430 — active again
- Reviewer `bhavyashah04122005` independently tested the built APK (worked
  around the `demo.paperless-ngx.com` 403-via-Cloudflare block by standing up
  their own local Docker Paperless-ngx) and left a full passing compliance
  checklist + clean VirusTotal scan.
- They flagged a real discrepancy: the F-Droid `.nogoogle` build strips both
  `google_mlkit_text_recognition` **and** `cunning_document_scanner` (two
  independent proprietary deps, not one depending on the other — got this
  wrong in my first draft, fixed before pushing), so "Scan Document" falls
  back to the gallery picker with no camera capture, but the store
  description still said plain "camera scan". **Fixed** (`b14ad8a`) — Note
  line in both `metadata/en-US/full_description.txt` and
  `fastlane/.../full_description.txt` now says so explicitly. Reviewer
  suggested a FOSS OpenCV path (`edge_detection` or `opencv_dart` packages)
  as an alternative to just fixing the copy — **not attempted**, flagged as a
  future option, not filed as an issue yet.
- `linsui` asked "please generate a lockfile for F-Droid" — ambiguous.
  `pubspec.lock` is already committed; Flutter's version is already pinned
  exactly in the recipe's `prebuild` step (extracts from
  `.github/workflows/release.yml`, `git checkout -f $flutterVersion` on the
  `flutter@stable` srclib) despite the srclib line saying "stable". Replied
  on the MR asking what specifically is needed rather than guessing.
  **Awaiting response** — check `glab mr view 34430 --repo fdroid/fdroiddata`
  next session.

## Play Console demo server (blocked on user infra, not code)
- Both Play Console (per `play-store/app-access-instructions.md`, drafted
  prior session) and the F-Droid reviewer need a **throwaway** Paperless-ngx
  demo — never the real instance (it has real personal documents in the
  Inbox).
- User is standing one up on **Oracle Cloud Free Tier**, shape
  `VM.Standard.E2.1.Micro` (x86_64, 1GB RAM — tight, needs a 2GB swap file).
  A `docker-compose.yml` + `Caddyfile` + `.env.example` + setup `README.md`
  (Redis + Paperless-ngx SQLite + Caddy auto-HTTPS via a free `nip.io`
  hostname) was drafted but **only exists in this session's ephemeral
  scratchpad** — `/tmp/claude-1000/.../scratchpad/fdroid-demo-server/` — and
  will be lost when the session ends. **If the VM isn't up yet, regenerate
  this from the conversation or have the user confirm it's already copied
  over to the VM.**
- Once live: verify login from a phone, then draft (with user sign-off
  before posting) the MR reply with server URL + reviewer credentials — same
  server can serve both the F-Droid and Play Console reviews.

## Device/test gotchas (this session)
- **Tailscale must be manually reactivated after a phone reboot.** Cost a
  long debugging detour: app showed "Failed to load inbox — server took too
  long to respond" after v1.1.6 install; app itself was fine (no crash, UI
  rendered), direct `curl` to the LAN Paperless-ngx host
  (`192.168.1.21:8082`) was instant — the app's configured server address
  routes through Tailscale, which was down post-reboot. Lesson: if the app
  is healthy but every request times out, check Tailscale/VPN state before
  assuming a code bug.
- **Foldable screenshots:** `adb shell screencap -p -d <display-id>` — the
  visible/active panel isn't always HWC display 0. Use
  `dumpsys SurfaceFlinger --display-id` to list both panel IDs and try both
  if the capture comes back solid black.
- **`adb shell input tap` can silently no-op** on these fold devices (no
  `getevent` activity, no state change) without any error — don't trust a
  tap succeeded just because the command exited 0; screenshot-verify.
- **Devices drop from `adb devices` mid-session** (both phones vanished
  entirely, not just one stale serial) — `adb kill-server && adb start-server`
  doesn't always bring them back; sometimes it's a real physical
  reconnect needed. Don't assume a wedged adb state; recheck.
- Two-device fleet now: Pixel 10 Pro Fold (`rango`, `57211FDCG0023C`) and
  Pixel 9 Pro Fold (`comet`, `4A111FDKD0000C`). Same package
  `com.ventouxlabs.paperlessgo` / activity `com.ventoux.paperlessgo.MainActivity`.
- `.github/workflows/ci.yml` only triggers on `pull_request`, never on
  direct pushes to `main` — every fix this session went straight to `main`
  with only local `flutter analyze` + `flutter test` as the gate, no CI run.
  Not fixed; flagging as a process gap someone should decide on.

## Remaining backlog (issue tracker, unchanged priority order not implied)
- **#23** — plan real PDF encryption (security-reviewed, not started)
- **#13** — Submit to Google Play Console (blocked on demo server, above)
- **#14** — Drive F-Droid MR !34430 to merge (active, awaiting `linsui` reply)
- **#9** — Document detail: one primary action, tamed overflow menu
- **#10** — Login screen restyle
- **#11** — Library adopts MetadataSheet for bulk/quick edits
- **#19** — Golden/widget test coverage for highest-traffic widgets
- **#12, #20, #21** — repo hygiene / agent-native verification infra, low
  urgency
