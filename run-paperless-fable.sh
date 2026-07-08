#!/bin/bash
#
# run-paperless-fable.sh — bounded autonomous debug-pipeline launcher for
# Paperless Go (Flutter/Dart client for Paperless-ngx).
#
# Runs the 5-pass debugging protocol documented in CLAUDE.md
# (Diagnostician -> Analyst -> Fixer -> Verifier, via .claude/agents/) against
# the next bug file in debug/queue/. Unlike a prior version of this script,
# it does NOT target the Go codebase, does NOT use
# --dangerously-skip-permissions, and does NOT retry forever.
#
# Usage:
#   ./run-paperless-fable.sh [bug-file] [max-attempts]
#
#   bug-file       Path to a single debug/queue/*.md file to work on.
#                  Defaults to the first file in debug/queue/ (alphabetical).
#   max-attempts   Bounded retry count if the session exits non-zero.
#                  Defaults to 3. Set to 1 to disable retries entirely.
#
# To run the whole queue sequentially, use scripts/debug-overnight.sh instead.

set -euo pipefail

QUEUE_DIR="debug/queue"
LOG_DIR="debug/logs"

MAX_ATTEMPTS="${2:-3}"
if ! [[ "$MAX_ATTEMPTS" =~ ^[0-9]+$ ]] || [ "$MAX_ATTEMPTS" -lt 1 ]; then
  echo "error: max-attempts must be a positive integer, got '$MAX_ATTEMPTS'" >&2
  exit 1
fi

BUG_FILE="${1:-}"
if [ -z "$BUG_FILE" ]; then
  BUG_FILE=$(find "$QUEUE_DIR" -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort | head -n1)
fi

if [ -z "$BUG_FILE" ] || [ ! -f "$BUG_FILE" ]; then
  echo "error: no bug file found. Pass a path or add one to $QUEUE_DIR/." >&2
  exit 1
fi

mkdir -p "$LOG_DIR"

BUG_NAME=$(basename "$BUG_FILE" .md)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/${BUG_NAME}-${TIMESTAMP}.log"

PROMPT_CONTENT=$(cat << EOF
You are the Debug Orchestrator for Paperless Go, a Flutter/Dart mobile
client for Paperless-ngx. Read CLAUDE.md in the repo root for the full
5-pass debugging protocol before doing anything else.

Bug file: ${BUG_FILE}
Bug contents:
$(cat "$BUG_FILE")

Execute the protocol in order, delegating each pass to its subagent:
1. diagnostician (.claude/agents/diagnostician.md) — Pass 1+2: reproduce
   the bug and verify the API contract against the Paperless-ngx spec.
2. analyst (.claude/agents/analyst.md) — Pass 3: root cause analysis with
   3 ranked hypotheses and file:line references.
3. fixer (.claude/agents/fixer.md) — Pass 4: implement the minimal fix for
   the highest-confidence hypothesis. One fix per commit. Follow existing
   patterns (dio, riverpod, freezed/json_serializable). Regenerate
   generated code with build_runner if models change.
4. verifier (.claude/agents/verifier.md) — Pass 5: run \`flutter test\` and
   \`flutter analyze\`, add/confirm a regression test, and report evidence.

If verification fails, cycle back to the diagnostician — max 3 attempts
per the YOLO Rules in CLAUDE.md, then stop and log findings instead of
looping further.

Do not run \`go test\`, do not create Go-specific artifacts
(PR_DESCRIPTION.md / ROADMAP.md / ENG_AUDIT_AND_BUILD_LOG.md are not part
of this project's workflow), and do not touch main directly — work on a
debug/<bug-name> branch per CLAUDE.md's Bug Queue rules.

Commit the fix with a clear conventional-commit message referencing the
bug name. Update debug/reports/${BUG_NAME}.md with the resolution.
EOF
)

echo "Paperless Go debug pipeline: ${BUG_NAME}"
echo "Log: ${LOG_FILE}"
echo "Max attempts: ${MAX_ATTEMPTS}"
echo "----------------------------------------------------------------------"

attempt=1
status=1
while [ "$attempt" -le "$MAX_ATTEMPTS" ]; do
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] Attempt ${attempt}/${MAX_ATTEMPTS}" | tee -a "$LOG_FILE"

  # Runs under the project's normal permission flow — no
  # --dangerously-skip-permissions. The interactive session will prompt for
  # anything it isn't already allowed to do.
  if claude -p "$PROMPT_CONTENT" 2>&1 | tee -a "$LOG_FILE"; then
    status=0
    break
  fi

  status=$?
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] Attempt ${attempt} exited with status ${status}." | tee -a "$LOG_FILE"
  attempt=$((attempt + 1))
done

echo "----------------------------------------------------------------------"
if [ "$status" -eq 0 ]; then
  echo "Done: ${BUG_NAME} completed. See ${LOG_FILE} and debug/reports/${BUG_NAME}.md."
else
  echo "Gave up on ${BUG_NAME} after ${MAX_ATTEMPTS} attempt(s). See ${LOG_FILE}." >&2
fi
exit "$status"
