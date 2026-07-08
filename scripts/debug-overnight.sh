#!/bin/bash
# scripts/debug-overnight.sh
# Run all bugs in debug/queue/ sequentially through the 5-pass debug
# pipeline (see CLAUDE.md and run-paperless-fable.sh).
#
# Deliberately deviates from the CLAUDE.md "Overnight Runner Script"
# snippet in two ways:
#   - No --dangerously-skip-permissions: sessions run under the project's
#     normal permission flow.
#   - Bounded per-bug retries (via run-paperless-fable.sh's max-attempts
#     argument) instead of an unbounded loop.
#
# Usage:
#   scripts/debug-overnight.sh [max-attempts-per-bug]

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

QUEUE_DIR="debug/queue"
LOG_DIR="debug/logs"
REPORT_DIR="debug/reports"
MAX_ATTEMPTS="${1:-3}"

mkdir -p "$LOG_DIR" "$REPORT_DIR"

shopt -s nullglob
bug_files=("$QUEUE_DIR"/*.md)
shopt -u nullglob

if [ ${#bug_files[@]} -eq 0 ]; then
  echo "No bug files in $QUEUE_DIR/. Nothing to do." >&2
  exit 0
fi

echo "Overnight debug session: ${#bug_files[@]} bug(s) queued, max ${MAX_ATTEMPTS} attempt(s) each."
echo "========================================"

failures=()
for bug_file in "${bug_files[@]}"; do
  bug_name=$(basename "$bug_file" .md)

  echo ""
  echo "========================================"
  echo "Starting: $bug_name at $(date)"
  echo "========================================"

  if ./run-paperless-fable.sh "$bug_file" "$MAX_ATTEMPTS"; then
    echo "Completed: $bug_name at $(date)"
  else
    echo "Failed after ${MAX_ATTEMPTS} attempt(s): $bug_name at $(date)" >&2
    failures+=("$bug_name")
  fi
done

echo ""
echo "========================================"
echo "Overnight debug session complete."
echo "Review reports: ls $REPORT_DIR/"
echo "Review logs:    ls $LOG_DIR/"
if [ ${#failures[@]} -gt 0 ]; then
  echo "Bugs that did not complete: ${failures[*]}" >&2
  exit 1
fi
echo "========================================"
