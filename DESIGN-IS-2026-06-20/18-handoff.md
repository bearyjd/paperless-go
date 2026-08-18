# 18 — Session Handoff (2026-08-18) — share intent fixed on-device, upload queue hardened, PR #25 open

Branch `fix/share-intent-and-upload-queue`, PR **#25**, 13 commits, CI green as of `a7168f1`.
Nothing merged to `main`. The live v1.1.8 release contains **none** of this.

---

## State

| | |
|---|---|
| Branch | `fix/share-intent-and-upload-queue` → PR #25 |
| Head | `846932e` |
| Tests | 259 Dart, 24 Kotlin, `flutter analyze` clean |
| Builds | debug + profile + release all verified |
| Device | Verified on Pixel 9 Pro Fold (`4A111FDKD0000C`) |

**Use the pinned SDK**: `/home/user/Documents/vibe-code/sdk/flutter/bin/flutter` (3.41.3, matches CI).
The one on `PATH` is 3.47 and mixing them poisons the build cache — widget tests then fail with
`ink_sparkle.frag ... Expected 1, got 2`, which is an SDK artifact, not a real regression.
Recover with `flutter clean && flutter pub get` using the pinned SDK.

---

## What shipped this session

### Share intent — root-caused on device, not by inspection

The share flow was broken in four independent ways. Each was reproduced with logcat before fixing:

1. **Stale intent** — `onNewIntent` never called `setIntent()`, so a later `getInitialShare()`
   resolved the previous intent (`getInitialShare returned: []`).
2. **Dropped delivery** — `eventSink?.success(...)` no-ops on a null sink, so a file that copied
   successfully vanished when the intent beat Dart's listener (`resolved 1 file(s), eventSink=false`).
   Now buffered and replayed on `onListen`.
3. **Re-delivery after process death** — killing the process and relaunching from Recents resolved
   and re-copied the share. Neither the intent extra nor `FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY`
   survives process death. Now keyed on a delivered marker persisted through `onSaveInstanceState`.
4. **"Page not found" flash** — `app.dart` returned `null` from the redirect while auth restored,
   so a `content://` URI fell through to `errorBuilder` for a few frames. Latent and
   timing-dependent, which is why it looked like it "went away".

Verified end to end on device: SAF DocumentsProvider URI copies (`copied=true`), lands on
**Upload File** with the right filename, cold and warm paths, and a killed-then-restored task logs
`getInitialShare: intent already delivered, skipping` and lands on Inbox.

### Upload queue — durability

- Queueing now covers the failures that actually happen: `NotAuthenticatedException` (no server
  configured) and `DioExceptionType.unknown` wrapping `SocketException` (hostname doesn't resolve).
- `PendingUploadStore` copies queued files out of evictable cache into app-private documents storage.
- Drains on login and startup, not only on a connectivity edge.
- Queued rows are bound to their originating server (`pending_uploads.serverUrl`, schema 7→8).
- Unreachable-server failures no longer consume the retry budget.

**Verified end to end against the demo server**: airplane mode on → share → "queued" with the file
in `app_flutter/pending_uploads/` → radio on → `POST /api/documents/post_document/` 200, row gone,
file released.

### Tooling

Debug builds are labelled **"Paperless Go (debug)"**. Both builds previously appeared in the share
sheet as an identical "Paperless Go", which made share testing ambiguous and cost a full round.
Note this also moves it in the app drawer.

---

## FIXED after this handoff was written

### Retention never runs when signed out — fixed

The drain returned at the `paperlessApiProvider` guard before ever reaching `getPendingUploads()`,
so a signed-out or misconfigured launch skipped the retention sweep entirely and held queued
documents forever. A hole in `846932e`, found by `/codex consult`.

The sweep is now a separate pass over the same fetch, ahead of resolving the API, with a per-row
fault boundary — which is the structural fix Codex recommended under item 1 below, not a guard
bolted on. Two tests cover it (expired row released with no server configured; a row whose
bookkeeping write throws does not strand the rows behind it), both verified RED first.

Reviewed afterwards by two independent agents; four further findings, all fixed:

- **Outcome recorded after the bytes were released.** A failed write or a kill between the two left
  the file gone and the row still reading as pending — neither present nor recorded. Marking first
  converges instead.
- **The fault-boundary test proved less than its name.** `getPendingUploads()` has no `ORDER BY`,
  and failing the *last* row swept is vacuous: a boundary-less sweep dies after the final row and
  strands nothing. Demonstrated by reversing the order with the boundary removed — green. Now fails
  whichever row the sweep reaches first, latched across passes, asserting on database state.
- **The signed-out fixture asserted against a state the app cannot produce** (authenticated auth
  state + throwing API; in the app the second follows from the first). Corrected to unauthenticated,
  and re-verified RED against `6dfd27c` so the regression coverage is known to be real.
- **The retention timer was not a bound at all** — see item 2 below.

Worth recording: the two reviewers overlapped on nothing, and the finding that changed the design
came from the adversarial one, not the checklist one.

---

## OPEN — start here

### 1. The drain wants restructuring, not another guard

Seven commits landed on `upload_queue_service.dart` in one day, and today's regression came from two
of *my own* fixes interacting. Correctness now depends on the ORDER of sequential guard clauses in
one loop.

Codex's recommended design (session `01a0157f-46a8-7582-b292-c63d645e70ae`, resume with `/codex`):

- ~~**Separate the retention sweep from the upload pass.**~~ Done — see FIXED above.
- **Sealed decision types** in the upload pass (`deferTerminal`, `deferWrongServer`,
  `failMissingFile`, `attemptUpload`) so a new outcome breaks exhaustive switches loudly.
- **Per-row fault boundaries** — in the *upload* pass, a malformed `tagsJson`, a failed retry write,
  or a failed row removal can still escape and abandon every later row. Worse, `getPendingUploads()`
  materializes every row eagerly, outside any boundary, so a row that fails to deserialize takes
  down the sweep too. (The retention sweep has a boundary; the upload pass does not.)
- No Drift schema change needed.

Filed as **#26**. Adjacent, same root cause as the retention clock finding, filed as **#27**:
`edit_queue_service.dart:16` orders pending edits by `queuedAt`, so a backwards clock jump applies
queued edits out of order.

### 2. Queue has no UI at all — and retention now pays for that

Failed rows, `lastError`, wrong-profile rows and legacy rows are all invisible.

**Decided:** retention no longer deletes. Expiry after 30 days records the outcome and keeps the
bytes. An adversarial review found the timer was `DateTime.now()`, which is not monotonic — a clock
jump expires rows that are days old, and a `queuedAt` stamped while the clock ran ahead never
expires at all. A plausibility heuristic can't fix the forward direction (a 45-day jump is
indistinguishable from 45 days elapsed against a 30-day window), so it would only narrow the hole.

The cost: app-documents storage is not evictable, so abandoned files now accumulate until the user
clears app data. **This is the wrong way round long-term.** Shipping queue visibility — a failed row,
its `lastError`, retry and delete — is what makes releasing the file defensible again, and until
then storage grows. That is the strongest reason to build the UI next.

### 3. Second `/codex review` never completed

Exit 124 (stalled past 5.5 min) on the full ~20-file diff. Re-run scoped smaller, e.g.
`--commit 846932e`.

---

## Things I got wrong, recorded so they aren't repeated

- **Self-review found nothing Codex found.** My devil's-advocate pass produced 9 findings, Codex
  produced 6, overlap **zero**. Codex caught a broken `flutter build --profile` I had shipped and a
  cross-account data leak my own fix made reachable. Get the outside pass.
- **Both reviews were wrong about duplicates.** We asserted the at-least-once window would create
  duplicate documents. Probed a real paperless-ngx 2.20: consumption is checksum-deduplicated
  (`Not consuming <file>: It is a duplicate of <doc> (#N)`). Client-side checksum suppression would
  have reimplemented a server feature. Probe before building.
- **A test document was uploaded to the live instance** (`paperless.grepon.cc`) during testing,
  against the CLAUDE.md rule. I believed the server was unreachable because the app's inbox showed a
  stale "Could not reach the server". Verify reachability directly, not via a UI error.
- **UI automation on the phone twice wandered into other apps** (WhatsApp, Google Voice composers).
  Nothing was sent. Don't drive the share sheet blind; hand that step to the user.

---

## Cleanup / notes

- Demo server `https://paperless-demo.ventouxlabs.com` is still live (reviewer / see `10-handoff.md:64`).
  `09-handoff.md` says to tear it down after Play review — still standing, decide.
- Demo test docs created during probing were deleted (`DELETE /api/documents/4/` → 204).
- `debug/` test files removed from the phone.
- Plan written but not implemented: `.claude/PRPs/plans/settings-import-export.plan.md`
  (import/export server settings, passphrase-encrypted, needs `cryptography` dep).
