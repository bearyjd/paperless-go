#!/bin/bash
# scripts/debug-overnight.sh
# Orchestrated overnight debug session for Paperless Go
#
# Usage:
#   chmod +x scripts/debug-overnight.sh
#   ./scripts/debug-overnight.sh
#
# Prerequisites:
#   - Claude Code CLI installed
#   - debug/queue/ contains bug files (*.md)
#   - Git repo is clean (or changes are committed)

set -euo pipefail

QUEUE_DIR="debug/queue"
LOG_DIR="debug/logs"
REPORT_DIR="debug/reports"
MAX_ATTEMPTS=3
MODEL="claude-sonnet-4-5-20250929"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

mkdir -p "$LOG_DIR" "$REPORT_DIR"

# Check prerequisites
if ! command -v claude &> /dev/null; then
  echo -e "${RED}Error: Claude Code CLI not found. Install it first.${NC}"
  exit 1
fi

if [ ! -d "$QUEUE_DIR" ] || [ -z "$(ls -A "$QUEUE_DIR"/*.md 2>/dev/null)" ]; then
  echo -e "${YELLOW}No bug files found in $QUEUE_DIR/. Add .md files and retry.${NC}"
  exit 0
fi

# Ensure clean working state
if [ -n "$(git status --porcelain)" ]; then
  echo -e "${YELLOW}Working directory not clean. Committing current state...${NC}"
  git add -A
  git commit -m "checkpoint: pre-overnight-debug $(date +%Y%m%d_%H%M%S)"
fi

ORIGINAL_BRANCH=$(git branch --show-current)
BUGS_TOTAL=$(ls "$QUEUE_DIR"/*.md 2>/dev/null | wc -l)
BUGS_FIXED=0
BUGS_FAILED=0
START_TIME=$(date +%s)

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Paperless Go — Overnight Debug Session${NC}"
echo -e "${BLUE}  Started: $(date)${NC}"
echo -e "${BLUE}  Bugs in queue: $BUGS_TOTAL${NC}"
echo -e "${BLUE}  Model: $MODEL${NC}"
echo -e "${BLUE}  Max attempts per bug: $MAX_ATTEMPTS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo ""

for bug_file in "$QUEUE_DIR"/*.md; do
  bug_name=$(basename "$bug_file" .md)
  timestamp=$(date +%Y%m%d_%H%M%S)
  log_file="$LOG_DIR/${bug_name}-${timestamp}.log"

  echo -e "${BLUE}────────────────────────────────────────${NC}"
  echo -e "${BLUE}  Bug: $bug_name${NC}"
  echo -e "${BLUE}  Started: $(date)${NC}"
  echo -e "${BLUE}────────────────────────────────────────${NC}"

  # Return to main and create debug branch
  git checkout "$ORIGINAL_BRANCH" 2>/dev/null
  git checkout -b "debug/${bug_name}" 2>/dev/null || git checkout "debug/${bug_name}" 2>/dev/null

  # Checkpoint
  git add -A && git commit --allow-empty -m "checkpoint: starting debug ${bug_name}" 2>/dev/null

  # Run the orchestrated debug pipeline
  claude --dangerously-skip-permissions \
    --model "$MODEL" \
    -p "You are the Debug Orchestrator for Paperless Go.

Read CLAUDE.md for the full debugging protocol and project context.

## Bug to Fix

$(cat "$bug_file")

## Your Mission

Execute the full 5-pass orchestrated debugging pipeline:

1. **Diagnostician** (Pass 1+2): Reproduce the bug, capture stack trace and HTTP context, verify against the Paperless-ngx API contract. Write findings to debug/reports/${bug_name}.md.

2. **Analyst** (Pass 3): Read the diagnostic report. Trace the call chain from UI to API. Generate 3 ranked hypotheses with file:line evidence. Append to the report.

3. **Fixer** (Pass 4): Read the analysis. Implement the minimal fix for the top hypothesis. Follow existing code patterns. Single-concern commit. Add a regression test. Append to the report.

4. **Verifier** (Pass 5): Run the regression test, full test suite, static analysis, and build check. Append pass/fail verdict to the report.

If verification FAILS, cycle back to the Diagnostician with the failure feedback. Maximum $MAX_ATTEMPTS attempts.

After each pass, commit progress: git add -A && git commit -m '<pass>: <bug-name> — <summary>'

## Rules
- Work autonomously. Do not ask for confirmation.
- Stay on branch debug/${bug_name}.
- Never force-push. Never touch $ORIGINAL_BRANCH.
- Log everything to the debug report.
- If you hit $MAX_ATTEMPTS failed fix attempts, log your findings and move on.
- Use read-only API endpoints only. Never write to the live Paperless-ngx instance." \
    2>&1 | tee -a "$log_file"

  # Check result
  if grep -q "PASS ✅" "$REPORT_DIR/${bug_name}.md" 2>/dev/null; then
    echo -e "${GREEN}  ✅ FIXED: $bug_name${NC}"
    BUGS_FIXED=$((BUGS_FIXED + 1))
  else
    echo -e "${RED}  ❌ UNRESOLVED: $bug_name${NC}"
    BUGS_FAILED=$((BUGS_FAILED + 1))
  fi

  echo -e "  Log: $log_file"
  echo ""
done

# Return to original branch
git checkout "$ORIGINAL_BRANCH" 2>/dev/null

END_TIME=$(date +%s)
DURATION=$(( (END_TIME - START_TIME) / 60 ))

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Overnight Debug Session Complete${NC}"
echo -e "${BLUE}  Duration: ${DURATION} minutes${NC}"
echo -e "${GREEN}  Fixed: $BUGS_FIXED${NC}"
echo -e "${RED}  Unresolved: $BUGS_FAILED${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo ""
echo "  Review branches:  git branch | grep debug/"
echo "  Review reports:   ls $REPORT_DIR/"
echo "  Review logs:      ls $LOG_DIR/"
echo ""
echo "  To merge a fix:"
echo "    git checkout $ORIGINAL_BRANCH"
echo "    git merge --no-ff debug/<bug-name>"
echo ""
