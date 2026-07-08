# Agent-Native Roadmap — Paperless Go

Audit date: 2026-07-07. Goal: let an AI coding agent take a raw bug report or
feature request and autonomously reproduce, implement, test, and verify it
with minimal human input. Items are ranked by **Human-Attention-Saved per
Unit of Effort** — cheap fixes that remove a landmine or unlock
self-verification rank above expensive ones.

This audit found the debugging *process* (`CLAUDE.md`'s 5-pass pipeline,
`.claude/agents/{diagnostician,analyst,fixer,verifier}.md`) is unusually
well codified for a project this size. The gaps are almost entirely on the
**verification and reproduction infrastructure** side: the docs describe
mocks, fixtures, and an integration-test directory that do not exist, so an
agent following the documented protocol will hit a dead end at the first
"update the mock" or "run the integration test" step.

---

## Top 5 — immediately actionable

### 1. Fix stale/aspirational project-structure docs (do this first) — ✅ DONE
**Effort: ~30 min. Saved: prevents every future agent session from being misdirected.**

**Status (2026-07-07):** `CLAUDE.md`'s "Project Structure Reference" section
now reflects the actual tree (see its "Verified against the actual tree on
2026-07-07" note) and its "YOLO Mode Configuration" section carries an
explicit warning pointing at item 3 below.

`CLAUDE.md`'s "Project Structure Reference" section and
`docs/CODEMAPS/INDEX.md`'s "Testing Structure" section describe files and
directories that do not exist in this repo:
- `lib/core/api/api_constants.dart`, `lib/core/api/api_exceptions.dart` — actual files are
  `lib/core/api/paperless_api.dart`, `lib/core/api/dio_client.dart`, `lib/core/api/api_error_mapper.dart`.
- `lib/core/models/task.dart`, `paginated_response.dart` — do not exist; pagination is handled inline via `ApiResponse` (`lib/core/models/api_response.dart`).
- `lib/core/providers/`, `lib/widgets/`, `lib/utils/` — do not exist. Providers live next to their feature (`*_provider.dart`, `*_notifier.dart`); shared widgets are under `lib/shared/widgets/`.
- `test/unit/providers/`, `test/integration/` — do not exist. Real layout is `test/unit/<feature>/`, `test/widget/<feature>/`, plus `test/features/scanner/...` for filter-pipeline tests. There is **no** `test/integration/`.

An agent trusting these docs will `Read` nonexistent files, search the wrong
directories, and waste turns. Fix: update both docs to match reality
(**additive edits only** to `CLAUDE.md` per the standing instruction — do
not delete existing content, correct the stale subsection in place).

**Acceptance criteria:** every path named in `CLAUDE.md` and
`docs/CODEMAPS/INDEX.md` resolves with `test -e`.

### 2. Add an HTTP-mock + fixture corpus for `PaperlessApi` — ✅ DONE
**Effort: ~1 day for scaffolding + first 5 fixtures. Saved: unlocks autonomous reproduction/regression-testing for the largest bug category (API contract mismatches) with zero live server.**

**Status (2026-07-07):** `http_mock_adapter: ^0.6.1` added as a dev
dependency (resolved offline from the local pub cache). Added
`test/fixtures/api/{documents_page1,custom_fields_select,tasks_poll_success,tasks_poll_pending}.json`
covering the known gotchas (date-only `created`, `select` custom-field
`{id,label}` shape, note `user` object, empty `/api/tasks/` list = PENDING).
Added `test/unit/api/paperless_api_test.dart` (9 tests, using
`DioAdapter` with `UrlRequestMatcher` so tests assert on response parsing
rather than exact query-string reproduction) — the file `CLAUDE.md`'s
"Build & Test Commands" section already referenced. `flutter test` (193/193)
and `flutter analyze` (clean) both pass.

`lib/core/api/paperless_api.dart` (528 lines) and `lib/core/api/dio_client.dart`
(193 lines) — the entire HTTP surface — have **zero test coverage**, and
`pubspec.yaml` has no mocking dependency (`mockito`, `http_mock_adapter`,
`nock`, etc.) at all. Every downstream test (`documents_notifier`,
`inbox_notifier`, `edit_queue`, etc.) exercises business logic with
hand-built objects, never a real HTTP response shape.

This directly undercuts the documented debug protocol: `CLAUDE.md` Pass 2
says "verify response parsing matches the actual response schema" and Pass 5
says "add a test that mocks the exact response that caused the failure" —
but there is no mocking harness to write that test into, and the `fixer`
agent's instructions ("update the corresponding mock in `test/`") reference
mocks that don't exist anywhere in the tree.

**Action:**
1. Add `http_mock_adapter` (or `dio`'s built-in `DioAdapter`/`mockito`) as a dev dependency.
2. Create `test/fixtures/api/` with recorded JSON bodies for the known-gotcha endpoints already named in `CLAUDE.md`: paginated `/api/documents/`, a document with the new `created` (date-only) field, a custom field of type `select` (`{id,label}` shape), a note with `user` as object, and a `/api/tasks/` poll response.
3. Add `test/unit/api/paperless_api_test.dart` exercising `PaperlessApi` against the mock adapter with those fixtures — this is the file `CLAUDE.md`'s own "Build & Test Commands" section already references (`flutter test test/unit/api/paperless_api_test.dart`) but which does not exist.

**Acceptance criteria:** a bug report describing a malformed/changed API
response can be reproduced by dropping a new fixture file and asserting the
parse/crash, without touching a live Paperless-ngx instance.

### 3. Neutralize `run-paperless-fable.sh` — it targets the wrong codebase — ✅ DONE
**Effort: ~15 min. Saved: removes an active safety hazard that could silently corrupt the repo if ever executed.**

**Status (2026-07-07):** Rewrote the script's embedded prompt for the
actual Flutter/Dart stack (`flutter test`/`flutter analyze`, the
diagnostician→analyst→fixer→verifier pipeline in `.claude/agents/`, reading
`CLAUDE.md`), dropped `--dangerously-skip-permissions` entirely (sessions
now run under the project's normal permission flow), and replaced the
unbounded `until ... sleep 600` retry loop with a bounded
`max-attempts` (default 3) counted loop that exits non-zero instead of
retrying forever. `bash -n` passes; dry-run with an empty `debug/queue/`
correctly exits 1 with a clear error instead of looping.

This script is a `--dangerously-skip-permissions` autonomous loop that
re-invokes Claude every time it exits non-zero (`sleep 600` between
retries, unbounded). Its embedded prompt describes auditing **"the Go
codebase across all packages"**, checking `Body.Close()` idioms, running
`go test ./...`, and creating `PR_DESCRIPTION.md`/`ROADMAP.md`/
`ENG_AUDIT_AND_BUILD_LOG.md` — none of which apply to this Flutter/Dart
project. Since `go test ./...` will always fail here (no Go toolchain
target), the script's `until` loop will retry forever, and each iteration
grants the agent permission-free write/commit/push access while operating
on a prompt that doesn't match the repo it's sitting in.

**Action:** either delete the script, or rewrite its embedded prompt to
match this repo's actual stack (Flutter/Dart, `flutter test`, the
diagnostician→analyst→fixer→verifier pipeline already in `.claude/agents/`)
and drop `--dangerously-skip-permissions` in favor of the project's normal
permission flow. Flagging for a human decision either way — do not run it
as-is.

### 4. Stand up `debug/queue/` and one worked example — ✅ DONE
**Effort: ~20 min. Saved: makes the documented overnight-YOLO pipeline actually runnable, and gives future bug reports a consistent intake format.**

**Status (2026-07-07):** Created `debug/queue/` with a worked example
(`01-example-thumbnail-auth-failure.md`, following the `# Bug: <title>` /
`Observed behavior` / `Expected behavior` / `Steps to reproduce` /
`Severity` / `Notes` template) and `debug/logs/.gitkeep`. Added
`scripts/debug-overnight.sh`, which iterates `debug/queue/*.md` and calls
`run-paperless-fable.sh <bug-file> <max-attempts>` per bug — same bounded
retry, no `--dangerously-skip-permissions` deviation as item 3. `bash -n`
passes.

`CLAUDE.md`'s "Bug Queue" section and `run-paperless-fable.sh`'s sibling
concept both assume `debug/queue/*.md` exists; only `debug/reports/` is
present. Create `debug/queue/.gitkeep` plus one example bug file following
the template already specified in `CLAUDE.md` (`# Bug: <title>` /
`Observed behavior` / `Expected behavior` / `Steps to reproduce` /
`Severity`), so an agent picking up a fresh raw bug report has a concrete
target format and can self-validate it wrote the intake file correctly.

**Acceptance criteria:** `debug/queue/` exists and contains a schema-valid
example; the diagnostician agent's existing instructions apply unmodified.

### 5. Add golden/widget coverage for the highest-traffic screens
**Effort: ~1 day for 5-6 goldens. Saved: gives an agent a pixel-level self-verification signal for UI changes without a device/emulator — directly relevant since `AUDIT.md` already scopes a UI redesign that will touch every screen.**

Only 3 widget tests exist (`empty_state`, `metadata_dropdown`,
`paginated_list_view`) against ~40 screens/widgets in `lib/features/` and
`lib/shared/widgets/`. There are **no golden tests anywhere** in the repo,
so an agent cannot detect an unintended visual regression (spacing,
color-token misuse, overflow) without a human looking at a screenshot. Given
`AUDIT.md`'s in-flight redesign work (theme/token replacement across every
screen), this is the single highest-leverage place to add golden coverage
right now, before the redesign lands.

**Action:** add `flutter_test`'s built-in `matchesGoldenFile` for: `document_card`,
`tag_chip` (covers the server-color contrast logic called out in `AUDIT.md` §3 — currently **untested**, `test/unit` has no `tag_chip_test.dart`), `stamp_chip`, `filter_bottom_sheet`, and the documents-list empty/loading/error states.

**Acceptance criteria:** `flutter test --update-goldens` produces baseline
images checked into `test/widget/goldens/`; a subsequent unrelated code
change does not alter any golden; a deliberate color-token change does.

---

## Other findings (lower priority / already well-covered elsewhere)

- **Human-judgment chokepoints already codified well:** the 5-pass debug
  protocol, the known Paperless-ngx API gotchas list (date-only `created`,
  custom-field `select` shape, `user` object vs ID, workflows vs consumption
  templates), and `test/unit/style_guard_test.dart` (a genuinely good
  pattern — codifies "no raw `Colors.red`", "no `.toString()` error leaks"
  as enforced tests, not just prose) are strong existing agent-native
  assets. Extend this pattern rather than replace it — e.g. a style-guard
  rule for "no manual `fromJson` when `json_serializable` is available" or
  "no new `StateNotifierProvider` when `@riverpod` is the house style,"
  both already stated as rules in `fixer.md` but not enforced by a test.
- **Structural boundary observation:** `lib/core/api/paperless_api.dart` at
  528 lines is a single God-class covering documents, tags, correspondents,
  document types, storage paths, saved views, custom fields, tasks, and
  bulk-edit. It's under the 800-line ceiling from the user's own coding
  standards but is the natural next split point (one file per resource) —
  worth doing *after* item 2 lands, so the split has test coverage as a
  safety net rather than being done blind.
- **`upload_queue_service.dart` has no max-retry limit** (`debug/reports/full-codebase-audit.md`
  Finding 4.3) — a previously-run audit agent already found this; it's a
  real bug, not a docs/infra gap, and is a good candidate for the *first*
  bug an agent should pick up once item 2's fixture harness exists, since
  it's reproducible purely with a mocked failing upload endpoint.
- **No `integration_test/` or `test/integration/` directory** despite both
  `CLAUDE.md` and `docs/CODEMAPS/INDEX.md` describing one. Multi-step flows
  (login → scan → upload, share-intent → upload) currently have no
  automated reproduction path at all short of a physical device/emulator
  run. Lower priority than items 1-5 because it requires device/emulator
  infra this audit was told not to invoke (`flutter build`/`flutter run`),
  but flagged for a follow-up roadmap once CI has emulator capacity.
