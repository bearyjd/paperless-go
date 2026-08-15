# 17 — Session Handoff (2026-08-15) — share-intent root-caused & fixed, demo server live, NDK toolchain repaired

**Supersedes `16-handoff.md`.** Three weeks passed with no handoff written (16
was 2026-07-23) — the gap below is a compressed summary from `git log`, not a
session-by-session account. Everything from "This session" onward is
first-hand.

## What shipped between handoff 16 and this session (compressed)

- **#10, #11, #12, #19, #20, #21** all closed — login restyle (AppTokens, not
  ColorScheme), Library adopted `MetadataSheet` for bulk/quick edits, repo
  hygiene (AUDIT.md moved into this dir, stale fable-script docs fixed),
  golden coverage added for document_card/tag_chip/stamp_chip/
  filter_bottom_sheet/documents-list, stale CODEMAPS/INDEX.md testing-section
  claims fixed, `debug/queue/` actually populated with a schema-valid example.
- **#23** — closed as a planning deliverable only (`2cd9e65`): real ISO 32000
  PDF encryption was scoped and security-reviewed, `pointycastle` identified
  as the library, but **no implementation exists yet**. If a user asks for
  "password protect a PDF" again, the feature is still not real — check this
  doc before assuming #23 means it shipped.
- **CI gap from handoff 15/16 fixed** (`0be07b0`): direct pushes to `main`
  now run analyze+test, not just PRs.
- **F-Droid MR !34430 merged.** `com.ventouxlabs.paperlessgo.nogoogle` is in
  F-Droid. Closed via #14. Nothing left to drive here.
- `pubspec.lock.fdroid` regenerated against Flutter 3.41.3 (was drifted to
  3.44.2) — `230b54e`. Same regen recipe as handoff 16 documented: don't
  delete the existing lock, `pub get` in place, diff before committing.
- v1.1.8 released; added a "Verify Connection" button to Paperless-AI
  settings (`a70f505`).

## This session — share-intent bug, root-caused and actually fixed this time

User's instinct going in: *"i feel like that share issue never was fully
fixed"* — about `810f061`/`cade169` from a prior session, which replaced
`receive_sharing_intent` with a native `SharePlugin.kt` (ContentResolver-based,
fixes SAF DocumentsProvider URIs the old package's legacy lookup couldn't
read). That instinct was correct. Root cause, found via a `/devils-advocate`
review of the diff: `SharePlugin.resolveIntent()`'s action dispatch only ever
matched `ACTION_SEND`/`ACTION_SEND_MULTIPLE`. `AndroidManifest.xml` also
registers an `ACTION_VIEW` filter — the app appears in a file manager's
**"Open with"** menu — and that action fell straight through to
`emptyList()`. The file was silently discarded; the user landed on `/inbox`
with nothing happening, no error, no log a user would ever see. This is the
**third** time this exact file shipped a share fix that missed a case
(`10411c1`, `810f061`, and this session's own first pass before the review
caught it).

Two fixes landed, both with proper TDD RED→GREEN checkpoint commits:

1. **`f97b373`** (test `2f1db8d`) — `SharePlugin.kt`'s action→source dispatch
   extracted into a pure `selectSource()`/`ShareSource` pair (no Android
   runtime dependency), covered by `SharePluginUriSelectionTest` (8 cases).
   Added the `ACTION_VIEW` branch, restricted to `content`/`file` schemes so
   the `paperlessgo://` widget deep link (also `ACTION_VIEW`) isn't misread
   as a file.
2. **`e84f1a5`** (test `c569bb7`, closes **#24**) — a second gap the same
   review surfaced: `ShareIntentHandler._handleSharedFiles` pushed
   unconditionally regardless of auth state, landing the scan screen on top
   of `/login` for a logged-out share. Now takes an `isAuthenticated`
   callback and queues the resolved `ShareRoute` instead of pushing when
   logged out; `app.dart`'s `_PaperlessGoAppState` watches `authStateProvider`
   (same `ref.listen` pattern `_AuthChangeNotifier` already uses for router
   refresh) and calls `flushPendingShare()` on the unauthenticated→
   authenticated edge.

RED was verified as a genuine compile-time failure both times (stashed the
fix, confirmed the test file alone fails to compile against pre-fix code,
restored the fix, reran). GREEN verified twice over: once with a hand-rolled
`kotlinc` + cached-jar classpath (Gradle was broken at the time — see below),
and again for real once Gradle was fixed. `flutter analyze` clean repo-wide
both times.

**Also filed but not fixed:** nothing left open from this investigation — #24
is closed. If another share-intent bug surfaces, check `SharePlugin.kt`'s
`selectSource()` first; the test file's own docstring names the three prior
misses so a fourth one should be caught by the same pattern (extend the
`when`, extend the test).

## Android NDK toolchain — was broken, now fixed

`android/app/build/../ndk/28.2.13676358` was corrupted (missing
`source.properties`) — any `:app` Gradle task failed at *configuration* time
with `[CXX1101] NDK ... did not have a source.properties file`, before any
task even ran. `sdkmanager` re-download stalled at 440MB (socket blocked on
read, confirmed via `/proc/<pid>/fd`). Fixed by downloading the zip directly
from `dl.google.com/android/repository/android-ndk-r28c-linux.zip` (722MB,
verified against the expected `source.properties` revision) and extracting
it into place by hand. `:app:testDebugUnitTest` now runs clean —
`BUILD SUCCESSFUL`, confirmed `SharePluginUriSelectionTest` 8/8 through the
real toolchain, not just the manual `kotlinc` workaround.

If this NDK directory ever goes missing/corrupt again on this machine:
skip `sdkmanager` (it's the thing that stalled), curl the zip directly from
`dl.google.com/android/repository/android-ndk-<version>-linux.zip`, unzip,
`mv` the extracted `android-ndk-<version>/` dir to
`~/Android/Sdk/ndk/<version-number>/` (the numeric version, not `r28c`).

## Play Console demo server — stood up, hardened, documented

The demo Paperless-ngx instance for App Store review (`play-store/
app-access-instructions.md`) is live on the `.23` Docker host
(`~/paperless-go-demo`), tunneled at `https://paperless-demo.ventouxlabs.com`.
This session added:

- **Daily flush + reseed**: cron runs `~/paperless-go-demo/reset.sh` at 04:00
  UTC — `docker compose down -v` → `up -d` → wait for healthy →
  `python3 seed/make_samples.py` (3 sample docs). Reviewer creds (`reviewer`
  / see `.env` on the host) are stable across resets since they're set via
  env vars, not stored data. Logs to `~/paperless-go-demo/logs/reset.log`.
- **2G hard storage cap**: `data`/`media`/`redisdata` volumes bind-mounted
  into `/var/lib/paperless-go-demo-quota`, a loop-mounted ext4 filesystem
  (entry in `/etc/fstab` on the host) — uploads past 2G hard-fail at the
  filesystem level instead of eating host disk.
- Docs updated (`play-store/SUBMISSION_CHECKLIST.md`,
  `app-access-instructions.md`) with the real server URL/username and a
  pointer to `.env` for the password — **the actual password is deliberately
  not committed**, repo is public.

## Remaining open issues (down to two)

- **#13** — Submit to Google Play Console. All engineering/asset work is
  done — build, listing copy, privacy policy, data safety answers, and now
  the demo server (see above). What's left is entirely manual Console work
  only the user can do: Ventoux org-account identity verification, Play App
  Signing enrollment, pasting the listing/creds into Console, hitting
  submit. Nothing to code here.
- **#4** — Epic: Release & distribution follow-through. Parent of #13.
  F-Droid thread (the other original leg) is done — MR merged, closed via
  #14. Close #4 once #13 lands.

No open PRs on GitHub. GitLab mirror (`selector4560/paperless-go`) has no
open issues/MRs of its own — it's purely the F-Droid recipe source, kept in
sync via `git push gitlab main` (**still true**: push there after any
`origin` push that matters for F-Droid, and push new version tags there too
— `UpdateCheckMode: Tags` needs them on the mirror specifically).

## Process note

The `/devils-advocate` skill (5-round adversarial review) caught both real
bugs in this session's first share-intent pass before they shipped — worth
running on any change to `SharePlugin.kt`/`ShareIntentHandler` specifically,
given the file's three-strikes history. General pattern that worked well
this session: extract the actual decision logic into a pure, dependency-free
function (`selectSource`, the `isAuthenticated` callback) specifically so a
regression test doesn't need Android/Riverpod test infrastructure to exist —
this repo still has none for native Kotlin beyond what was added this
session (`SharePluginUriSelectionTest`, the first Kotlin unit test in the
repo).
