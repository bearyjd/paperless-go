# Paperless Go — Issue Decomposition Plan (2026-07-07)

**Status: CREATED on GitHub 2026-07-07.**
Mapping: E1=#3 · E2=#4 · E3=#5 · S1.1=#6 · T1=#7 · T2a=#8 · T2b=#9 · T3=#10 ·
T4=#11 · T5=#12 · T6=#13 · T7=#14 · T8=#15 · T9=#16.

**Addendum (same day):** `.agent_native/agent_roadmap.md` (audit 2026-07-07) added an
agent-native verification-infrastructure epic **E4=#17** with #18 (HTTP-mock fixture
corpus), #19 (golden tests, after #7), #20 (CODEMAPS stale paths), #21 (debug/queue
scaffold), plus bug **#22** (upload queue has no max-retry) under E3=#5. Roadmap item 3
(fable script hazard) recorded as a comment on #12.
Repo: `bearyjd/paperless-go` (GitHub = canonical tracker; the `gitlab` remote is the
F-Droid mirror). Issue tracker enabled, currently **empty** — no duplication risk.
CI green (last runs: v1.1.5 Release, CI on PRs).

## Sources consulted

- `README.md`, `CLAUDE.md` (debug protocol, API gotchas, conventions)
- `AUDIT.md` — step-1 UI/UX redesign audit (baseline v1.1.5)
- `DESIGN-IS-2026-06-20/13-handoff.md` — **authoritative current state**: the redesign is
  implemented, analyzer-clean, but **uncommitted (~36 files in the working tree)**; a
  signed APK is on the test device; remaining work is enumerated (items 1–6)
- `DESIGN-IS-2026-06-20/12-handoff.md` (per 13: still current for release state — v1.1.5
  shipped both tracks, F-Droid MR !34430 waiting on reviewer, Play Console submission
  pending)
- TODO sweep: 1 hit — `lib/core/services/pdf_tools_service.dart:60`, verified by reading
  the code: **`protectPdf` ignores the password** (see T8)
- `gh run list`: all green

## Proposed hierarchy

| Tier | Count | Items |
|---|---|---|
| Epic | 3 | E1 redesign completion · E2 release/distribution follow-through · E3 correctness bugs |
| Story | 1 | S1.1 document-detail redesign (only multi-task slice; other tasks parent to epics directly — flagged, deliberate) |
| Task | 10 | T1–T9 (T2 split a/b) |

Labels to create: `epic`, `story`, `task`, `area:ui`, `area:distribution`, `size:S`, `size:M`, plus stock `bug`/`enhancement`.

---

## EPIC E1 — UI/UX redesign completion (DESIGN-IS workstream)

**Labels:** `epic`, `area:ui`, `enhancement`

Land and finish the approved 2026-06 redesign: one primary action per screen; Inbox as
a swipeable card stack (right = accept OCR suggestions); bottom nav Inbox/Library/Chat +
raised teal Scan button; metadata editing via a reusable modal bottom sheet
(`MetadataSheet`); scan flow ≤3 taps; search omnibox; stamp-chip pills. The bulk is
**implemented but uncommitted** (handoff 13); this epic tracks committing it and the
enumerated remaining surfaces (document detail, login, library MetadataSheet adoption,
repo hygiene).

### TASK T1 — Device-review and commit the uncommitted redesign tree

## Summary
Review the implemented redesign on-device (light + dark) and land the ~36-file uncommitted working tree as a series of logical conventional commits, removing the single-point-of-loss risk.

## Why (context a newcomer wouldn't have)
- The entire redesign pass (design tokens, theme, nav shell, Inbox card stack, scan flow, Library, Chat/Settings) exists **only in the working tree** on the dev machine — analyzer-clean but uncommitted (`DESIGN-IS-2026-06-20/13-handoff.md` TL;DR: "Do not lose this tree").
- Device review is gated on logging back into the Paperless-ngx server on the test device (a `pm clear` wiped credentials during testing).
- Parent: Epic E1.

## Scope (what to touch)
- No new code. Screenshot review (Inbox / Library / Scanner / Chat / Settings, `adb shell cmd uimode night yes|no`), then `git add`/commit series on a feature branch → PR.
- Out of scope: any fix the review surfaces bigger than a tweak — file it as a new issue under E1 instead of growing this one.

## Acceptance Criteria
- [ ] The redesign is merged to `main` as a reviewed PR of logical commits (foundation → per-feature), with `flutter analyze` and `flutter test` green and the working tree clean.

## Implementation notes
- Handoff 13 "Device-test gotchas" is required reading: launch the *new* package explicitly (`am start -n com.ventouxlabs.paperlessgo/com.ventoux.paperlessgo.MainActivity` after `force-stop`) — the old package id is also installed and Android resurrects a stale task showing the old UI; fold-device screenshots need `screencap -d <inner display id>`.
- **DO NOT run `dart format`** repo-wide — the tree isn't format-clean and CI is analyze+test only.

## Testing / Definition of Done
- `flutter analyze && flutter test` green on the merge commit; screenshots of the five surfaces in light+dark attached to the PR.

## Size
M

## Depends on
none (user must re-login on the device first)

## Labels
task, area:ui, size:M, enhancement

---

### STORY S1.1 — Document detail adopts the redesign

**Labels:** `story`, `area:ui`, `enhancement` · Parent: E1

The document detail screen is the biggest untouched surface: 2–3 app-bar actions plus an
11-item overflow menu and ~8 inline-editable sections (AUDIT.md screen inventory). After
this story it uses the shared `MetadataSheet` for metadata editing and presents one
primary action, matching the rest of the redesigned app.

#### TASK T2a — Document detail: metadata editing via MetadataSheet

## Summary
Replace the document detail screen's inline-editable metadata sections (title, correspondent/type/path dropdowns, dates, ASN, tags, custom fields) with the shared `MetadataSheet` modal bottom sheet introduced by the redesign.

## Why (context a newcomer wouldn't have)
- The redesign's metadata-editing pattern is a reusable bottom sheet (`lib/shared/widgets/metadata_sheet.dart`, with `MetadataSheetResult` and a `topSlot` hook) already used by the upload flow; handoff 13 explicitly names document detail as the surface that "should adopt `MetadataSheet`".
- Parent: S1.1 → E1. See `AUDIT.md` §1 (detail is the "heaviest screen") and §4 goal 4.

## Scope (what to touch)
- `lib/features/documents/document_detail_screen.dart` (+ small wiring in its providers if needed).
- Out of scope: the overflow-menu/primary-action restructure (T2b); notes, AI trail, share links, content sections stay as they are.

## Acceptance Criteria
- [ ] Editing any metadata field on document detail happens through `MetadataSheet` and saves to the server correctly (verified against a live Paperless-ngx instance), with the inline edit sections removed.

## Implementation notes
- This repo: Riverpod (`@riverpod` + build_runner codegen — regenerate `.g.dart` after provider changes), Dio, conventional commits; error handling `on DioException catch` only.
- Paperless-ngx API gotchas in `CLAUDE.md` apply (custom-field select options are `{id, label}` objects; `created` is date-only).
- **No `dart format`**; keep the F-Droid build free of new Google/Play dependencies.

## Testing / Definition of Done
- Widget test: sheet opens with current values, returns a `MetadataSheetResult` that patches the document; `flutter test` green.

## Size
M

## Depends on
T1 (MetadataSheet must be committed first)

## Labels
task, area:ui, size:M, enhancement

#### TASK T2b — Document detail: one primary action, tamed overflow menu

## Summary
Restructure the document detail app bar so the screen has one clear primary action, regrouping the current 11-item overflow menu (download, share, annotate, compress, protect, rotate, split, OCR, delete, …) into intentional groups.

## Why (context a newcomer wouldn't have)
- "One primary action per screen" is redesign goal #1 (`AUDIT.md` §4.1) and document detail is its worst offender. The redesign brief's feature-cut rule applies: demote, group, or move actions — don't delete capability.
- Parent: S1.1 → E1.

## Scope (what to touch)
- `lib/features/documents/document_detail_screen.dart` (app bar + menu structure only).
- Out of scope: metadata sections (T2a); the PDF tools themselves (E3/T8 covers `protectPdf`'s behavior).

## Acceptance Criteria
- [ ] Document detail renders exactly one primary action, every current menu capability remains reachable, and the grouping matches a short rationale comment/PR description (which action is primary and why).

## Implementation notes
- Follow the redesigned screens' idiom (header actions + sheets, stamp chips) rather than inventing a new pattern; look at the redesigned `documents_screen.dart` header first.

## Testing / Definition of Done
- Widget test asserting all former menu actions are still reachable (finder per action); manual smoke on device.

## Size
M

## Depends on
T2a (same file — land sequentially to avoid conflict)

## Labels
task, area:ui, size:M, enhancement

---

### TASK T3 — Login screen restyle

## Summary
Bring the login screen fully onto the redesign system (tokens, Space Grotesk headings, stamp idiom where apt) — a restyle-only pass, no behavior change.

## Why
- Handoff 13 item 3: login "already looks decent from theme inheritance" — this is the finishing pass. Parent: E1.

## Scope
- `lib/features/auth/` login screen file(s) only. Out of scope: the `http://` cleartext mismatch — that's T9 (#E3), a behavior fix.

## Acceptance Criteria
- [ ] Login renders with zero hardcoded colors (tokens/`Theme.of` only) in light and dark, verified by screenshot pair.

## Implementation notes
- Use `tokens.onAccent` for anything rendered on `accentFill` (dark `onPrimary` pairs with the brightened teal — handoff 13 foundation notes).

## Size
S

## Depends on
T1

## Labels
task, area:ui, size:S, enhancement

### TASK T4 — Library adopts MetadataSheet for bulk/quick edits

## Summary
Point the Library screen's metadata-editing paths (bulk bar, quick edits) at the shared `MetadataSheet` instead of its own pickers where they overlap.

## Why
- The library agent deliberately did not reference `MetadataSheet` during the parallel fan-out (conflict avoidance); handoff 13 item 4 marks adoption as now-safe. Parent: E1.

## Scope
- `lib/features/documents/documents_screen.dart` + related sheet call sites. Out of scope: filter sheet (stays — it's filtering, not metadata editing).

## Acceptance Criteria
- [ ] Library's document metadata edits route through `MetadataSheet` with no duplicated picker widgets left behind for those paths.

## Size
S

## Depends on
T1

## Labels
task, area:ui, size:S, enhancement

### TASK T5 — Repo hygiene: AUDIT.md and run-paperless-fable.sh disposition

## Summary
Decide and execute the fate of the two loose files handoff 13 flags: move `AUDIT.md` into the design workstream folder (recommended: `DESIGN-IS-2026-06-20/`) or delete it, and keep-or-delete the untracked `run-paperless-fable.sh`.

## Why
- Handoff 13 items 5–6 defer these to "commit time"; they shouldn't ride along silently in the redesign PR. Parent: E1.

## Acceptance Criteria
- [ ] Neither file sits unexplained at repo root: each is moved, deleted, or committed with a rationale in the commit message.

## Size
S

## Depends on
T1 (do alongside the commit series)

## Labels
task, size:S, enhancement

---

## EPIC E2 — Release & distribution follow-through

**Labels:** `epic`, `area:distribution`

v1.1.5 shipped on GitHub Releases and the F-Droid pipeline; two external threads remain
open (handoff 12, still current per handoff 13).

### TASK T6 — Submit to Google Play Console

## Summary
Complete the Play Console listing and submit the Play build (`applicationId com.ventouxlabs.paperlessgo`) for review, using the prepared assets in `play-store/`.

## Why
- Upload assets and the Play application id landed in commits `d8f3241`/`c84d0c5`; handoff 12 marks the console submission as "user's turn". `PLAY_STORE_LISTING.md` and `PRIVACY_POLICY.md` already exist at repo root. Parent: E2.

## Scope
- Play Console (external) + record submission steps/date in a short note (suggest appending to `PLAY_STORE_LISTING.md`).

## Acceptance Criteria
- [ ] The app reaches "In review" (or beyond) in the Play Console, and the repo notes the submitted versionCode and date.

## Implementation notes
- Privacy policy must be reachable at a public URL for the console field — `PRIVACY_POLICY.md` needs a hosted location (GitHub blob URL is acceptable to Play).
- Data-safety answers: the README/privacy stance is "no data collected, everything stays between device and user's server" — answer for the *Play* build (includes ML Kit; on-device only).

## Size
M

## Depends on
none

## Labels
task, area:distribution, size:M, enhancement

### TASK T7 — Drive F-Droid MR !34430 to merge

## Summary
Shepherd the fdroiddata merge request (waiting on reviewer `linsui` since the v1.1.5 font fix) to merged: respond to review, rebase/update the recipe if v1.1.6+ ships first.

## Why
- The MR was blocked on runtime Google-CDN font fetching; v1.1.5 bundled Inter specifically to unblock it (CHANGELOG 1.1.5, handoffs 11–12). The ball can bounce back at any time. Parent: E2.

## Scope
- fdroiddata fork on GitLab (no local clone — use the GitLab API; handoff gotcha: `glab` note POST needs `-F body=@file`). Recipe uses the `.nogoogle` flavor and ABI-split versionCodes.

## Acceptance Criteria
- [ ] MR !34430 is merged (app builds on F-Droid's servers), or the current blocking reviewer question is answered with the MR in a reviewable state.

## Size
S (external-wait; effort is bursty)

## Depends on
none — but if the redesign (T1) ships as v1.2.0 first, update the MR to the new tag

## Labels
task, area:distribution, size:S, enhancement

---

## EPIC E3 — Correctness bugs

**Labels:** `epic`, `bug`

Two verified user-facing defects, both predating the redesign.

### TASK T8 — "Password protect PDF" does not encrypt — password is silently ignored

## Summary
`PdfToolsService.protectPdf` accepts a password, re-renders the PDF pages… and writes an **unencrypted** PDF named `protected_*.pdf` — the password is never used. Make the feature honest: implement real encryption or remove/clearly disable the option.

## Why (context a newcomer wouldn't have)
- Verified in `lib/core/services/pdf_tools_service.dart:58-76`: the `password` parameter is unused; the doc comment says "TODO: Add actual encryption when pdf package supports it". A user who "password protects" a tax document and shares it has zero protection while believing otherwise — this is a security-expectation failure, the worst kind of silent.
- The action is offered from the document detail overflow menu (added in v1.1.0, CHANGELOG "Add compress, share, and password protect actions").
- Parent: E3.

## Scope (what to touch)
- `lib/core/services/pdf_tools_service.dart`, the detail-screen menu entry, and the UI copy around it.
- Out of scope: T2b's menu restructure (coordinate ordering if concurrent).

## Acceptance Criteria
- [ ] Either (a) the output PDF actually requires the password to open (verified by an automated test that fails to read it without the password), or (b) the "Password protect" action is removed/disabled with the release notes and UI stating why. No path leaves the current lie in place.

## Implementation notes
- **AGPL-3.0 constraint:** the popular Syncfusion PDF package is proprietary — incompatible; check `pdf`/`printing` current capabilities first, then pure-Dart options (e.g. RC4/AES via a maintained OFL/BSD lib) or a platform-channel to Android's `PdfDocument` alternatives. If nothing acceptable exists, option (b) is the correct outcome — say so plainly.
- Repo rule (CLAUDE.md): fix one thing per commit; add the regression test with the fix.

## Testing / Definition of Done
- For (a): unit test opens output with wrong/no password → fails, with password → succeeds. For (b): widget test asserts the action is absent/disabled + CHANGELOG entry under Fixed.

## Size
M

## Depends on
none

## Labels
task, bug, size:M

### TASK T9 — Login offers `http://` but release builds block cleartext traffic

## Summary
The login screen lets users pick `http://`, but release builds block cleartext HTTP, so those logins fail confusingly. Align the UI with the build policy.

## Why
- Known UX bug carried in handoff 13 ("Login offers `http://` but release blocks cleartext — known UX bug, non-blocking"). Self-hosters commonly run Paperless-ngx behind plain HTTP on a LAN, so the failure will be hit by real users with an opaque connection error.
- Parent: E3.

## Scope (what to touch)
- Decision then fix: either (a) permit user-opt-in cleartext for private-range hosts via Android `network_security_config.xml` + an explicit in-UI warning, or (b) drop the `http://` option in release and show a clear "HTTPS required" explanation with a link to docs. Recommendation: (a) — it matches the self-hosted audience; scope the config to user-added domains, never a blanket `cleartextTrafficPermitted=true`.
- Files: login screen, `android/app/src/main/res/xml/` (new config), manifest reference.

## Acceptance Criteria
- [ ] On a release build, entering an `http://` server either works (after the explicit opt-in warning, option a) or is impossible with a clear explanation (option b) — no silent "Connection failed" path remains.

## Implementation notes
- Test on the release build specifically — debug builds permit cleartext, which is how this slipped through.

## Testing / Definition of Done
- Manual: release APK against a plain-HTTP test server; automated: widget test on the URL-scheme validation logic.

## Size
S

## Depends on
none

## Labels
task, bug, size:S

---

## Deliberately NOT filed

- **Redesign sub-items already implemented** (Inbox card stack, scan-flow collapse, omnibox, nav shell): they're done in the working tree; filing them would create issues born closed. T1 lands them.
- **AUDIT.md open questions A–G**: all answered during the workstream (Dashboard retired, Space Grotesk bundled, stamp/tint compromise) — recorded in handoff 13; no decision task needed, unlike relais.
- **CLAUDE.md's YOLO/overnight debug scaffolding** (`debug/queue/`, runner script): infrastructure docs, not work items.

## Creation order

Labels → epics (E1, E2, E3) → story S1.1 → tasks T1–T9 → parent checklists.
