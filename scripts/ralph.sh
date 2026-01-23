#!/bin/bash

# Ralph Wiggum - True Context-Isolated Development Loop
# Based on Geoffrey Huntley's original technique: https://github.com/ghuntley/how-to-ralph-wiggum
#
# Key difference from the official plugin:
# - Each iteration starts a FRESH claude process with clean context
# - Previous iteration's reasoning is completely discarded
# - Only filesystem changes (code, git commits, progress.txt) carry forward
# - This prevents "context rot" where accumulated tokens degrade quality

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PROMPT_FILE=""
MAX_ITERATIONS=0
COMPLETION_PROMISE=""
ITERATION=0
PROJECT_DIR="$(pwd)"
SIGNAL_FILE=".ralph-signal"
INACTIVITY_TIMEOUT=300  # 5 minutes of no file changes after PRD change = stuck
CONSECUTIVE_FAILURES=0
MAX_CONSECUTIVE_FAILURES=5  # Stop after 5 consecutive failures (likely rate limited)

print_usage() {
  cat << 'EOF'
Ralph Wiggum - True Context-Isolated Development Loop

USAGE:
  ./scripts/ralph.sh <prompt-file> [OPTIONS]

ARGUMENTS:
  <prompt-file>    Path to markdown file containing the task prompt

OPTIONS:
  --max-iterations <n>           Maximum iterations (default: unlimited)
  --completion-promise '<text>'  Promise phrase to detect completion
  --inactivity-timeout <seconds> Kill if no file changes for N seconds (default: 300)
  -h, --help                     Show this help

RATE LIMIT HANDLING:
  - Detects consecutive failures (exit code != 0)
  - Applies exponential backoff: 10s, 20s, 40s, 80s
  - Stops after 5 consecutive failures to avoid burning iterations
  - Re-run when rate limits reset to continue

PHASE COMPLETION:
  - Checks if all stories pass BEFORE starting each iteration
  - Watchdog kills Claude when PHASE_COMPLETE signal detected
  - Prevents unnecessary iterations when all work is done

DESCRIPTION:
  Unlike the official /ralph-loop plugin, this script starts a FRESH
  claude process for each iteration. This provides true context isolation:

  - Each iteration gets a clean context window
  - No accumulated tokens from previous iterations
  - State persists ONLY through files and git
  - Prevents "context rot" that degrades AI quality

EXAMPLES:
  ./scripts/ralph.sh ralph-specs/phase-prompt.md --max-iterations 20
  ./scripts/ralph.sh PROMPT.md --completion-promise "PHASE_COMPLETE"
  ./scripts/ralph.sh task.md --max-iterations 30 --completion-promise "DONE"

PROMPT FILE FORMAT:
  The prompt file should contain:
  - Clear task description
  - Instructions to read progress.txt for state
  - Instructions to update progress.txt before exiting
  - Completion criteria

RECOMMENDED PROMPT STRUCTURE:
  See ralph-specs/phase-prompt-template.md for best practices
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      print_usage
      exit 0
      ;;
    --max-iterations)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    --inactivity-timeout)
      INACTIVITY_TIMEOUT="$2"
      shift 2
      ;;
    *)
      if [[ -z "$PROMPT_FILE" ]]; then
        PROMPT_FILE="$1"
      else
        echo -e "${RED}Error: Unknown argument: $1${NC}" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

# Validate prompt file
if [[ -z "$PROMPT_FILE" ]]; then
  echo -e "${RED}Error: No prompt file specified${NC}" >&2
  print_usage
  exit 1
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo -e "${RED}Error: Prompt file not found: $PROMPT_FILE${NC}" >&2
  exit 1
fi

# Create log directory
mkdir -p .claude/ralph-logs

# Log file for this run
RUN_ID=$(date +%Y%m%d_%H%M%S)
LOG_FILE=".claude/ralph-logs/run_${RUN_ID}.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_completion() {
  local output="$1"

  if [[ -n "$COMPLETION_PROMISE" ]]; then
    if echo "$output" | grep -q "<promise>${COMPLETION_PROMISE}</promise>"; then
      return 0  # Completed
    fi
  fi
  return 1  # Not completed
}

# Main loop header
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Ralph Wiggum - True Context-Isolated Development Loop       ║${NC}"
echo -e "${BLUE}║  Based on: ghuntley/how-to-ralph-wiggum                       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Prompt file: ${GREEN}$PROMPT_FILE${NC}"
echo -e "Max iterations: ${YELLOW}$(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)${NC}"
echo -e "Completion promise: ${YELLOW}$(if [[ -n "$COMPLETION_PROMISE" ]]; then echo "$COMPLETION_PROMISE"; else echo "none"; fi)${NC}"
echo -e "Inactivity timeout: ${YELLOW}${INACTIVITY_TIMEOUT}s${NC}"
echo -e "Log file: ${GREEN}$LOG_FILE${NC}"
echo ""
echo -e "${YELLOW}⚠️  Each iteration starts a FRESH claude process with clean context${NC}"
echo -e "${YELLOW}   State persists only through files and git${NC}"
echo ""

log "Starting Ralph loop with prompt: $PROMPT_FILE"
log "Max iterations: $MAX_ITERATIONS, Completion promise: ${COMPLETION_PROMISE:-none}, Inactivity timeout: ${INACTIVITY_TIMEOUT}s"

# The main Ralph loop - simple and dumb, just like the original
while true; do
  ITERATION=$((ITERATION + 1))

  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}🔄 ITERATION $ITERATION${NC} $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo "of $MAX_ITERATIONS"; fi)"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo ""

  log "Starting iteration $ITERATION"

  # Check if phase is already complete (all stories pass)
  # This prevents starting unnecessary iterations when all work is done
  if [[ -d "ralph-specs" ]]; then
    INCOMPLETE_STORIES=$(grep -l '"passes": false' ralph-specs/prd-phase-*.json 2>/dev/null | wc -l)
    if [[ $INCOMPLETE_STORIES -eq 0 ]]; then
      # Double-check by looking for any passes:false in any PRD
      if ! grep -q '"passes": false' ralph-specs/prd-phase-*.json 2>/dev/null; then
        echo -e "${GREEN}✅ All stories already complete - no work remaining${NC}"
        echo -e "${GREEN}🎉 Ralph loop completed successfully after $((ITERATION - 1)) iterations!${NC}"
        log "All stories already complete, stopping before iteration $ITERATION"
        ITERATION=$((ITERATION - 1))  # Adjust count since we didn't actually run this iteration
        break
      fi
    fi
  fi

  # Check max iterations
  if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -gt $MAX_ITERATIONS ]]; then
    echo -e "${YELLOW}⏹️  Max iterations ($MAX_ITERATIONS) reached. Stopping.${NC}"
    log "Max iterations reached, stopping"
    break
  fi

  # Create iteration-specific output file
  ITERATION_OUTPUT=".claude/ralph-logs/iteration_${RUN_ID}_${ITERATION}.txt"
  ITERATION_ERROR=".claude/ralph-logs/iteration_${RUN_ID}_${ITERATION}.err"

  # WSL2 fix: Re-enter the project directory before each iteration
  # This prevents "working directory was deleted" errors that occur
  # when the directory inode changes between iterations
  cd "$PROJECT_DIR" || {
    echo -e "${RED}Failed to cd to project directory: $PROJECT_DIR${NC}"
    log "Failed to cd to project directory"
    exit 1
  }

  # THE CORE OF RALPH: Fresh claude process each iteration
  # This is what provides true context isolation
  #
  # We capture stdout and stderr separately to prevent error messages
  # from overwriting the completion promise output
  #
  # Signal file approach: Claude writes to .ralph-signal instead of relying on stdout
  # Activity-based detection: If no file changes for N minutes after PRD changed, treat as stuck

  # Clean up signal file before running Claude
  rm -f "$SIGNAL_FILE"

  CLAUDE_EXIT_CODE=0
  PRD_HASH_BEFORE=$(md5sum ralph-specs/prd-phase-*.json 2>/dev/null | md5sum | cut -d' ' -f1)
  LAST_ACTIVITY_TIME=$(date +%s)

  # Run Claude in background
  claude -p "$(cat "$PROMPT_FILE")" > "$ITERATION_OUTPUT" 2> "$ITERATION_ERROR" &
  CLAUDE_PID=$!

  # Activity-based watchdog: monitors file changes, kills if stuck or phase complete
  (
    PRD_CHANGED=false
    IDLE_SECONDS=0

    while kill -0 $CLAUDE_PID 2>/dev/null; do
      sleep 10

      # Check if signal file exists (early detection)
      if [[ -f "$SIGNAL_FILE" ]]; then
        SIGNAL_CONTENT=$(cat "$SIGNAL_FILE" 2>/dev/null || echo "")

        # If PHASE_COMPLETE, kill Claude immediately - nothing more to do
        if [[ "$SIGNAL_CONTENT" == *"PHASE_COMPLETE"* ]]; then
          echo -e "${GREEN}✅ PHASE_COMPLETE detected by watchdog - terminating iteration${NC}" >&2
          kill $CLAUDE_PID 2>/dev/null || true
          exit 0
        fi

        # For STORY_COMPLETE, also kill Claude - story is done
        if [[ "$SIGNAL_CONTENT" == *"STORY_COMPLETE"* ]]; then
          echo -e "${GREEN}✅ STORY_COMPLETE detected by watchdog - terminating iteration${NC}" >&2
          kill $CLAUDE_PID 2>/dev/null || true
          exit 0
        fi

        # Unknown signal, let main loop handle it
        exit 0
      fi

      # Check for recent file activity in project directories
      RECENT_FILES=$(find src/ prisma/ ralph-specs/ -type f -newer "$ITERATION_OUTPUT" 2>/dev/null | wc -l)

      if [[ $RECENT_FILES -gt 0 ]]; then
        IDLE_SECONDS=0
        # Check if PRD changed
        PRD_HASH_NOW=$(md5sum ralph-specs/prd-phase-*.json 2>/dev/null | md5sum | cut -d' ' -f1)
        if [[ "$PRD_HASH_BEFORE" != "$PRD_HASH_NOW" ]]; then
          PRD_CHANGED=true
        fi
      else
        IDLE_SECONDS=$((IDLE_SECONDS + 10))

        # If PRD changed but process is idle for too long, kill it (likely hung)
        if $PRD_CHANGED && [[ $IDLE_SECONDS -ge $INACTIVITY_TIMEOUT ]]; then
          echo -e "${YELLOW}⏰ Process idle for ${IDLE_SECONDS}s after PRD change - killing hung process${NC}" >&2
          kill $CLAUDE_PID 2>/dev/null || true
          exit 0
        fi
      fi
    done
  ) &
  WATCHDOG_PID=$!

  # Wait for Claude to finish
  wait $CLAUDE_PID || CLAUDE_EXIT_CODE=$?

  # Kill watchdog if still running
  kill $WATCHDOG_PID 2>/dev/null || true
  wait $WATCHDOG_PID 2>/dev/null || true

  PRD_HASH_AFTER=$(md5sum ralph-specs/prd-phase-*.json 2>/dev/null | md5sum | cut -d' ' -f1)

  # Show output to terminal
  cat "$ITERATION_OUTPUT"

  if [[ $CLAUDE_EXIT_CODE -eq 0 ]]; then
    log "Iteration $ITERATION completed successfully"
    CONSECUTIVE_FAILURES=0  # Reset on success
  else
    log "Iteration $ITERATION exited with code $CLAUDE_EXIT_CODE (checking for completion anyway)"
    # Show errors if any
    if [[ -s "$ITERATION_ERROR" ]]; then
      echo -e "${YELLOW}Stderr output:${NC}"
      cat "$ITERATION_ERROR"
    fi

    # Check for rate limit or repeated failures
    CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
    if [[ $CONSECUTIVE_FAILURES -ge $MAX_CONSECUTIVE_FAILURES ]]; then
      echo ""
      echo -e "${RED}⚠️  $CONSECUTIVE_FAILURES consecutive failures detected (likely rate limited)${NC}"
      echo -e "${YELLOW}   Stopping to avoid burning through iterations.${NC}"
      echo -e "${YELLOW}   Re-run the script when rate limits reset.${NC}"
      log "Stopping after $CONSECUTIVE_FAILURES consecutive failures (likely rate limited)"
      break
    elif [[ $CONSECUTIVE_FAILURES -ge 2 ]]; then
      # Exponential backoff: 10s, 20s, 40s, 80s
      BACKOFF_SECONDS=$((10 * (2 ** (CONSECUTIVE_FAILURES - 2))))
      echo -e "${YELLOW}⏳ $CONSECUTIVE_FAILURES consecutive failures - backing off ${BACKOFF_SECONDS}s${NC}"
      log "Backing off ${BACKOFF_SECONDS}s after $CONSECUTIVE_FAILURES failures"
      sleep $BACKOFF_SECONDS
    fi
  fi

  # Check signal file FIRST (most reliable - no stdout buffering issues)
  SIGNAL_DETECTED=false
  if [[ -f "$SIGNAL_FILE" ]]; then
    SIGNAL=$(cat "$SIGNAL_FILE")
    rm -f "$SIGNAL_FILE"
    CONSECUTIVE_FAILURES=0  # Signal file means work was done, reset failures

    if [[ "$SIGNAL" == *"PHASE_COMPLETE"* ]]; then
      echo ""
      echo -e "${GREEN}✅ Phase complete signal detected (via signal file)${NC}"
      echo -e "${GREEN}🎉 Ralph loop completed successfully after $ITERATION iterations!${NC}"
      log "Phase complete signal detected via signal file, stopping"
      break
    elif [[ "$SIGNAL" == *"STORY_COMPLETE"* ]]; then
      echo ""
      echo -e "${GREEN}✅ Story complete signal detected (via signal file): $SIGNAL${NC}"
      log "Story complete signal detected via signal file, continuing to next iteration"
      SIGNAL_DETECTED=true
    fi
  fi

  # Fallback: check stdout/stderr for completion promise (existing behavior)
  if ! $SIGNAL_DETECTED; then
    OUTPUT=$(cat "$ITERATION_OUTPUT" 2>/dev/null || echo "")
    ERROR_OUTPUT=$(cat "$ITERATION_ERROR" 2>/dev/null || echo "")
    COMBINED_OUTPUT="$OUTPUT $ERROR_OUTPUT"

    if check_completion "$COMBINED_OUTPUT"; then
      echo ""
      echo -e "${GREEN}✅ Completion promise detected: <promise>${COMPLETION_PROMISE}</promise>${NC}"
      echo -e "${GREEN}🎉 Ralph loop completed successfully after $ITERATION iterations!${NC}"
      log "Completion promise detected in stdout, stopping"
      break
    fi

    # Check if PRD was updated despite no explicit signal (work was done, possibly hung)
    if [[ "$PRD_HASH_BEFORE" != "$PRD_HASH_AFTER" ]]; then
      echo -e "${GREEN}📝 PRD was updated - work was done, continuing...${NC}"
      log "PRD updated, continuing to next iteration"
    fi
  fi

  echo ""
  echo -e "${YELLOW}📝 Iteration $ITERATION complete. Starting fresh context...${NC}"
  log "Iteration $ITERATION complete, continuing to next iteration"

  # Small delay to prevent hammering
  sleep 2
done

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Ralph loop finished${NC}"
echo -e "Total iterations: ${YELLOW}$ITERATION${NC}"
echo -e "Log file: ${GREEN}$LOG_FILE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

log "Ralph loop finished after $ITERATION iterations"
