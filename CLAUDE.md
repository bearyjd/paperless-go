# Paperless Go — CLAUDE.md

## Project Overview

Paperless Go is a Flutter mobile client for Paperless-ngx, a self-hosted document management system. It replaces the abandoned community app with a modern architecture, proper API integration, and a clean UI.

**Backend:** Paperless-ngx REST API (user-configured server URL)
**AI Pipeline:** Paperless-AI → LiteLLM → Claude models
**State Management:** Riverpod
**HTTP Client:** dio (or http)
**Auth:** Token-based (`Authorization: Token <api_token>`)
**API Docs:** See your Paperless-ngx instance at `/api/schema/view/`

---

## Debugging Protocol

This project uses a multi-pass orchestrated debugging approach. When a bug is reported or a test fails, follow this pipeline **in order**. Do not skip passes. Do not combine passes. Each pass has a distinct purpose and feeds the next.

### Pass 1 — Reproduce & Capture

**Goal:** Confirm the bug exists and capture every artifact.

- Run the failing test or reproduce the user-reported flow
- Capture the **full stack trace** (Dart, platform channel, and native if applicable)
- Capture the **HTTP request/response** — method, URL, headers, status code, response body
- Capture the **Riverpod provider state** at the time of failure
- Log the **device/emulator info** (`flutter doctor -v` output if relevant)
- If the error is intermittent, run it 5x and note the success/failure ratio
- **Output:** A structured bug report in `debug/reports/<bug-name>.md`

```
debug/reports/<bug-name>.md:
  - Description: <what happened vs what was expected>
  - Stack trace: <full trace>
  - HTTP context: <request + response>
  - Provider state: <relevant state snapshot>
  - Reproduction rate: <X/5>
  - Severity: critical | high | medium | low
```

### Pass 2 — API Contract Verification

**Goal:** Determine if the bug is a client-side or server-side issue.

- Compare the HTTP request against the Paperless-ngx API spec
  - Endpoints: `/api/documents/`, `/api/tags/`, `/api/correspondents/`, `/api/document_types/`, `/api/storage_paths/`, `/api/tasks/`, `/api/search/auto_complete/`
  - Auth header: `Authorization: Token <token>`
  - API versioning: `Accept: application/json; version=5`
  - Pagination: `?page=N&page_size=N` — response has `count`, `next`, `previous`, `results`
  - Full text search: `/api/documents/?query=<search_term>`
  - Document actions: `/api/documents/<pk>/download/`, `/api/documents/<pk>/preview/`, `/api/documents/<pk>/thumb/`
  - Upload: `POST /api/documents/post_document/` as multipart form
  - Bulk edit: `POST /api/bulk_edit/` with `{documents: [], method: "", parameters: {}}`
  - Custom fields: can be attached to documents, types include string, url, date, integer, float, monetary, document_link, select
- Verify response parsing matches the actual response schema
- Check for API version mismatches (Paperless-ngx changes field names between versions)
- Known gotchas:
  - `created` is now a date, not datetime. `created_date` is deprecated.
  - Custom field select options return `{id, label}` objects, not plain strings
  - `user` field in document notes returns a user object, not just an ID
  - Workflows replaced consumption templates — endpoint changed
  - `acknowledge tasks` moved to `/api/tasks/acknowledge/`
- **Output:** Verdict — `CLIENT_BUG`, `API_MISMATCH`, `SERVER_BUG`, or `SPEC_UNCLEAR`

### Pass 3 — Root Cause Analysis

**Goal:** Identify the exact code path that fails and why.

- Trace the call chain from UI → provider → repository → API client → model
- Check for:
  - **Null safety violations** — `!` operators on nullable API fields
  - **JSON deserialization failures** — missing fields, wrong types, unexpected nulls
  - **State management bugs** — stale providers, disposed notifiers, missing `ref.watch` vs `ref.read`
  - **Async race conditions** — concurrent API calls, unguarded `setState` after disposal
  - **Pagination edge cases** — off-by-one, empty pages, count mismatches
  - **Image/thumbnail loading failures** — auth headers missing on image requests
  - **Platform channel issues** — file picker, camera, share intent differences iOS vs Android
- Read `git log --oneline -20` for recent changes to affected files
- Read related test files for assumptions that may no longer hold
- **Output:** 3 ranked hypotheses with file:line references

### Pass 4 — Fix Implementation

**Goal:** Implement the minimal correct fix.

- Fix ONE thing per commit
- Follow existing code patterns — don't introduce new patterns during a bugfix
- If the fix touches a model class, regenerate with `build_runner` if using `json_serializable` / `freezed`:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- If the fix touches API client code, add/update the corresponding integration test
- If the fix touches UI code, verify on both Android and iOS (or at minimum the primary target)
- **Do not** refactor adjacent code during a bugfix. File a separate issue.

### Pass 5 — Verification & Regression

**Goal:** Prove the fix works and doesn't break anything else.

- Run the specific failing test — it must pass
- Run the full test suite:
  ```bash
  flutter test
  ```
- Run static analysis:
  ```bash
  flutter analyze
  ```
- If the bug was an API contract issue, add a test that mocks the exact response that caused the failure
- If the bug was a state management issue, add a test that reproduces the race condition or lifecycle error
- Run the app on a device/emulator and manually verify the fixed flow
- **Output:** Updated `debug/reports/<bug-name>.md` with resolution notes

---

## Subagent Architecture

This project defines specialized subagents in `.claude/agents/` for the debug pipeline. The main Claude Code session acts as **Orchestrator** and delegates to these agents.

### Agent Roster

| Agent | File | Purpose | Tools |
|---|---|---|---|
| Diagnostician | `.claude/agents/diagnostician.md` | Pass 1+2: Reproduce, capture, verify API contract | Read, Grep, Glob, Bash |
| Analyst | `.claude/agents/analyst.md` | Pass 3: Root cause analysis, hypothesis generation | Read, Grep, Glob, Bash |
| Fixer | `.claude/agents/fixer.md` | Pass 4: Implement minimal fix | Read, Write, Edit, Bash |
| Verifier | `.claude/agents/verifier.md` | Pass 5: Run tests, static analysis, regression check | Read, Bash, Grep |

### Orchestration Flow

```
User reports bug
       │
       ▼
  ┌─────────────┐
  │ Orchestrator │ (main Claude Code session / CLAUDE.md)
  │  reads bug   │
  └──────┬──────┘
         │
         ▼
  ┌──────────────┐     Output: debug/reports/<bug>.md
  │ Diagnostician │───► with stack trace, HTTP context,
  │  (Pass 1+2)   │     reproduction steps, API verdict
  └──────┬────────┘
         │
         ▼
  ┌──────────────┐     Output: 3 ranked hypotheses
  │   Analyst     │───► with file:line references
  │  (Pass 3)     │     and evidence chain
  └──────┬────────┘
         │
         ▼
  ┌──────────────┐     Output: minimal diff
  │    Fixer      │───► single-concern commit
  │  (Pass 4)     │     follows existing patterns
  └──────┬────────┘
         │
         ▼
  ┌──────────────┐     Output: test results,
  │   Verifier    │───► analysis clean,
  │  (Pass 5)     │     regression report
  └──────┘────────┘
         │
         ▼
    Bug resolved ✅
    (or cycle back to Diagnostician if verification fails)
```

---

## YOLO Mode Configuration

When running overnight autonomous debug sessions, use these settings:

```bash
# Launch with full autonomy
claude --dangerously-skip-permissions \
  --model claude-sonnet-4-5-20250929 \
  -p "$(cat debug/queue/next-bug.md)"
```

### YOLO Rules

1. **Always commit before fixing** — create a checkpoint: `git add -A && git commit -m "checkpoint: pre-fix <bug-name>"`
2. **Never force-push** — all work is on a `debug/<bug-name>` branch
3. **Auto-branch** — each bug gets its own branch off `main`: `git checkout -b debug/<bug-name> main`
4. **Max 3 fix attempts per bug** — if Pass 4→5 fails 3 times, log the findings and move to the next bug in the queue
5. **Leave breadcrumbs** — every action gets logged to `debug/logs/<bug-name>-<timestamp>.log`
6. **Don't touch `main`** — merge only happens with human review
7. **Respect the API** — never make live writes to the Paperless-ngx instance during debug; use mock data or read-only endpoints

### Bug Queue

Bugs to fix overnight go in `debug/queue/` as individual markdown files:

```
debug/queue/
├── 01-document-list-pagination.md
├── 02-thumbnail-auth-failure.md
├── 03-search-empty-results.md
└── 04-upload-custom-fields.md
```

Each file should contain:
```markdown
# Bug: <title>

## Observed behavior
<what happens>

## Expected behavior
<what should happen>

## Steps to reproduce
1. ...
2. ...

## Severity
critical | high | medium | low

## Notes
<any additional context>
```

### Overnight Runner Script

```bash
#!/bin/bash
# scripts/debug-overnight.sh
# Run all bugs in the queue sequentially

set -euo pipefail

QUEUE_DIR="debug/queue"
LOG_DIR="debug/logs"
REPORT_DIR="debug/reports"

mkdir -p "$LOG_DIR" "$REPORT_DIR"

for bug_file in "$QUEUE_DIR"/*.md; do
  bug_name=$(basename "$bug_file" .md)
  timestamp=$(date +%Y%m%d_%H%M%S)
  log_file="$LOG_DIR/${bug_name}-${timestamp}.log"

  echo "========================================" | tee -a "$log_file"
  echo "Starting: $bug_name at $(date)" | tee -a "$log_file"
  echo "========================================" | tee -a "$log_file"

  # Create branch
  git checkout main
  git pull --ff-only
  git checkout -b "debug/${bug_name}" || git checkout "debug/${bug_name}"

  # Checkpoint
  git add -A && git commit --allow-empty -m "checkpoint: starting debug ${bug_name}"

  # Run orchestrated debug pipeline
  claude --dangerously-skip-permissions \
    --model claude-sonnet-4-5-20250929 \
    -p "You are the Debug Orchestrator for Paperless Go. Read CLAUDE.md for the full protocol.

Bug file: ${bug_file}
Bug contents:
$(cat "$bug_file")

Execute the full 5-pass debugging protocol:
1. Use the diagnostician agent for Pass 1+2 (reproduce & API contract check)
2. Use the analyst agent for Pass 3 (root cause analysis)
3. Use the fixer agent for Pass 4 (implement minimal fix)
4. Use the verifier agent for Pass 5 (test & regression)

If verification fails, cycle back to the diagnostician (max 3 attempts).
Commit the fix with a clear message referencing the bug name.
Log everything to debug/reports/${bug_name}.md.

Work autonomously. Do not ask for confirmation. YOLO." \
    2>&1 | tee -a "$log_file"

  echo "Completed: $bug_name at $(date)" | tee -a "$log_file"
done

echo ""
echo "========================================"
echo "Overnight debug session complete."
echo "Review branches: git branch | grep debug/"
echo "Review reports:  ls $REPORT_DIR/"
echo "========================================"
```

---

## Project Structure Reference

```
lib/
├── main.dart                       # App entry point
├── app.dart                        # MaterialApp / Router setup
│
├── core/
│   ├── api/
│   │   ├── paperless_api.dart      # Dio client, interceptors, auth
│   │   ├── api_constants.dart      # Base URLs, endpoints, API version
│   │   └── api_exceptions.dart     # Custom exception types
│   ├── models/                     # Data models (json_serializable / freezed)
│   │   ├── document.dart
│   │   ├── tag.dart
│   │   ├── correspondent.dart
│   │   ├── document_type.dart
│   │   ├── storage_path.dart
│   │   ├── custom_field.dart
│   │   ├── task.dart
│   │   ├── saved_view.dart
│   │   └── paginated_response.dart
│   ├── providers/                  # Riverpod providers
│   ├── router/                     # GoRouter configuration
│   └── theme/                      # App theming
│
├── features/
│   ├── documents/                  # Document list, detail, search
│   ├── upload/                     # Document upload flow
│   ├── tags/                       # Tag management
│   ├── correspondents/             # Correspondent management
│   ├── settings/                   # Server config, auth
│   └── dashboard/                  # Home / overview
│
├── widgets/                        # Shared UI components
│
└── utils/                          # Helpers, extensions

test/
├── unit/
│   ├── api/                        # API client tests with mock responses
│   ├── models/                     # Serialization round-trip tests
│   └── providers/                  # Provider logic tests
├── widget/                         # Widget tests
└── integration/                    # Full flow tests

debug/
├── queue/                          # Bug files for overnight runs
├── reports/                        # Generated debug reports
└── logs/                           # Session logs
```

---

## Common Paperless-ngx API Patterns

### Authentication
```dart
// All requests need this header
headers: {
  'Authorization': 'Token $apiToken',
  'Accept': 'application/json; version=5',
}
```

### Paginated List
```dart
// GET /api/documents/?page=1&page_size=25
// Response:
{
  "count": 142,
  "next": "https://your-server.example.com/api/documents/?page=2&page_size=25",
  "previous": null,
  "results": [ ... ]
}
```

### Document Object (key fields)
```
id, title, content, tags (list of IDs), correspondent (ID or null),
document_type (ID or null), storage_path (ID or null),
created (date string YYYY-MM-DD), modified (datetime), added (datetime),
archive_serial_number, original_file_name, archived_file_name,
custom_fields (list of {field: ID, value: mixed}),
notes (list of {id, note, created, user: {id, username}}),
owner (ID or null), permissions ({view: {users, groups}, change: {users, groups}})
```

### Thumbnails & Downloads (require auth headers!)
```
GET /api/documents/<pk>/thumb/        → PNG thumbnail
GET /api/documents/<pk>/preview/      → Inline document view
GET /api/documents/<pk>/download/     → Download original
GET /api/documents/<pk>/download/?original=true  → Force original (not archived)
```

### Upload
```
POST /api/documents/post_document/
Content-Type: multipart/form-data
Fields: document (file), title, correspondent, document_type, tags (repeat), created, archive_serial_number, custom_fields
Returns: task UUID → poll /api/tasks/?task_id=<uuid> for status
```

### Full Text Search
```
GET /api/documents/?query=invoice+2024
GET /api/search/auto_complete/?term=inv  → autocomplete suggestions
```

---

## Build & Test Commands

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run a specific test file
flutter test test/unit/api/paperless_api_test.dart

# Run only tests matching a pattern
flutter test --name "should parse paginated documents"

# Static analysis
flutter analyze

# Code generation (models, providers)
dart run build_runner build --delete-conflicting-outputs

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Run on device
flutter run
```

---

## Debugging Tips

- **API debugging:** Use `dio` interceptors to log all HTTP traffic. Enable with an env flag, don't ship to release.
- **Riverpod debugging:** Use `ProviderObserver` to log state changes. Helps catch stale state issues.
- **Image loading:** Thumbnails and previews require the auth token in headers. If using `Image.network`, you need a custom `HttpClient` or `CachedNetworkImage` with headers.
- **Pagination gotcha:** The `count` field is the total count, not the page count. Calculate pages as `(count / pageSize).ceil()`.
- **Date fields:** `created` is `YYYY-MM-DD` (date only). Don't try to parse it as ISO 8601 datetime.
- **Custom fields:** When updating a document with select-type custom fields, send the option `id`, not the label or index.
- **Bulk operations:** `/api/bulk_edit/` methods: `set_correspondent`, `set_document_type`, `set_storage_path`, `add_tag`, `remove_tag`, `modify_tags`, `delete`, `redo_ocr`, `set_permissions`, `rotate`, `merge`, `split`.
- **Task polling:** After upload, the response is just a task UUID. Poll `/api/tasks/?task_id=<uuid>` until `status` is `SUCCESS` or `FAILURE`.
