# 16 — Session Handoff (2026-07-23) — #9 shipped, F-Droid MR unblocked (again)

**Supersedes `15-handoff.md`.**

## Where we are
- **#9 shipped** (`4b62864`, follow-up review fixes `f29995d`): document detail's
  app bar went from 2 standalone icons + a 9-item flat `PopupMenuButton` to
  exactly one primary action (Share) + one overflow trigger opening a grouped
  modal bottom sheet (View / Edit / Export / Manage). Verified via
  `flutter analyze`/`flutter test` (194/194) and an on-device smoke test on
  the Pixel 10 Pro Fold. No new widget test — this screen has a 5+ provider
  dependency graph and zero existing test harness (that gap is #19).
- **v1.1.6 → v1.1.7 both released** (see handoff 15 for v1.1.6 detail).
  v1.1.7 rolled up #22 (upload retry terminal state), #16 (login blocks
  `http://`), #15 (removed the dishonest PDF password-protect feature).
  Both installed and verified on Pixel 9 Pro Fold and Pixel 10 Pro Fold.
- **F-Droid MR !34430 — unblocked twice this session, may need another round:**
  1. First round: found the GitLab mirror (`gitlab.com/selector4560/paperless-go`,
     the recipe's actual `Repo:` source) had **completely diverged history**
     from GitHub `main` — no common ancestor, from a prior force-push. Force-
     synced GitLab `main` to GitHub `main` (user confirmed the destructive
     overwrite). Also found two of three build entries had a genuinely
     broken `sed` command trying to hand-patch `pubspec.lock` (missing `/d`,
     no closing quote) — this was `linsui`'s original "lock file" complaint.
     Fixed by dropping `--enforce-lockfile` entirely and letting `pub get`
     regenerate the lock naturally. Pinned recipe to v1.1.7 (`69b7fd2`).
  2. Second round (this session): two more blockers surfaced —
     - `bhavyashah04122005` found `fdroid checkupdates` failing because
       `UpdateCheckMode: Tags` scans git tags, and the GitLab mirror only had
       `v1.1.5` tagged (we'd synced the branch, not tags). **Fixed** — pushed
       `v1.1.6`/`v1.1.7` tags to the mirror.
     - `linsui` asked for `--enforce-lockfile` back (wants versions
       pinned/verified, not just resolved-fresh). **Fixed properly this
       time**: rather than re-attempt sed-patching the lockfile at build
       time, committed `pubspec.lock.fdroid` to the app repo — a lockfile
       pre-resolved against the same stripped `pubspec.yaml` (drops
       `google_mlkit_text_recognition`, `cunning_document_scanner`, and
       their orphaned transitive deps: `google_mlkit_commons` +
       `permission_handler` family) but every other package pinned
       identically to the real `pubspec.lock` — verified the diff is
       exactly those 9 packages, nothing else. Recipe's prebuild now does
       `cp pubspec.lock.fdroid pubspec.lock` before `pub get
       --enforce-lockfile`. Pinned recipe to `1f36e58`.
  3. Posted reply, **awaiting response** from `linsui`/`bhavyashah04122005`.
     Check `glab mr view 34430 --repo fdroid/fdroiddata` next session —
     there may be a third round; this reviewer pair has been thorough and
     is testing the actual APK each time, which is good but means expect
     more specific findings, not a rubber-stamp merge.
- **Issue tracker:** #6, #7, #8, #18, #9, #22, #16, #15 all closed this
  session and last. Remaining backlog below.

## Key infra facts for next session
- Two remotes: `origin` = GitHub (canonical), `gitlab` = the F-Droid mirror
  at `selector4560/paperless-go`. **Keep these in sync** — `git push gitlab
  main` after every `origin` push that matters for F-Droid (the mirror does
  NOT auto-sync). Also push new version tags to `gitlab` (`git push gitlab
  vX.Y.Z`) — `UpdateCheckMode: Tags` needs them there, not just on GitHub.
- The actual F-Droid recipe under review lives in a **third** repo, separate
  from both: `gitlab.com/selector4560/fdroiddata`, branch `add-paperless-go`
  (cloned to scratch as `fdroiddata-fork` this session — that clone is
  ephemeral, gone next session; re-clone if editing the recipe again). MR:
  `fdroid/fdroiddata!34430`. Recipe file:
  `metadata/com.ventouxlabs.paperlessgo.nogoogle.yml`.
- `pubspec.lock.fdroid` (in the main app repo, both remotes) must be
  regenerated whenever `pubspec.yaml`'s dependencies change AND the F-Droid
  build still needs `--enforce-lockfile` to pass. Regeneration recipe: copy
  the repo to scratch, `sed -i -e '/google_mlkit/d' -e
  '/cunning_document_scanner/d' pubspec.yaml`, **do not delete the existing
  `pubspec.lock`** (deleting it and running `pub get` did a full fresh
  resolve and changed 182 dependencies — wrong), just run `flutter pub get`
  with the existing lock in place so only the now-orphaned packages drop
  out. Diff the result against the real `pubspec.lock` to confirm it's
  minimal before committing.
- Two GitHub Actions workflows: `release.yml` (tags only) and `ci.yml`
  (pull_request only) — **direct pushes to `main` never run CI**. Flagged as
  a process gap in handoff 15, still unaddressed, still worth a decision.

## Remaining open issues
- **#23** — plan real PDF encryption (security-reviewed effort; research
  found `pointycastle` — MIT, AGPL-compatible, has the RC4/AES/MD5/SHA-256
  primitives — but it's not a dependency yet and no implementation plan
  exists). Not started.
- **#13** — Submit to Google Play Console. Blocked on a throwaway demo
  server (real instance has real personal documents, can't use it for
  reviewers). User is standing one up on Oracle Cloud Free Tier
  (`VM.Standard.E2.1.Micro`, Ubuntu 24.04 Minimal, x86_64, 1GB RAM + 2GB
  swap). A `docker-compose.yml`/`Caddyfile`/`.env.example`/`README.md` was
  drafted in a prior session's ephemeral scratchpad and **may be lost** —
  check with the user whether the VM is up before regenerating it.
- **#14** — Drive F-Droid MR !34430 to merge. Active, see above — check for
  reviewer response next session.
- **#10** — Login screen restyle (small, UI-only).
- **#11** — Library adopts MetadataSheet for bulk/quick edits.
- **#19** — Golden/widget test coverage for highest-traffic widgets. Also
  the natural home for eventually building a document-detail-screen test
  harness (deferred twice now, for #15 and #9, due to the 5+ provider
  dependency graph and zero existing scaffolding).
- **#12, #20, #21** — repo/doc hygiene, agent-native verification infra.
  Low urgency, small (S).

## Process note
A `/devils-advocate` review of the #9 commit (`4b62864`) this session caught
two real small issues before they shipped further: a missing `default` case
on `_handleAction`'s action-string switch (now fails loudly via `assert` in
debug/test instead of silently no-op-ing on drift), and hardcoded
`EdgeInsets`/`SizedBox` values instead of this file's established `Spacing`
design tokens. Both fixed in `f29995d`. Worth running that review pattern
again on the next UI-touching change before pushing.
