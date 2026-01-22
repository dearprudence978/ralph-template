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
  -h, --help                     Show this help

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
echo -e "Log file: ${GREEN}$LOG_FILE${NC}"
echo ""
echo -e "${YELLOW}⚠️  Each iteration starts a FRESH claude process with clean context${NC}"
echo -e "${YELLOW}   State persists only through files and git${NC}"
echo ""

log "Starting Ralph loop with prompt: $PROMPT_FILE"
log "Max iterations: $MAX_ITERATIONS, Completion promise: ${COMPLETION_PROMISE:-none}"

# The main Ralph loop - simple and dumb, just like the original
while true; do
  ITERATION=$((ITERATION + 1))

  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}🔄 ITERATION $ITERATION${NC} $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo "of $MAX_ITERATIONS"; fi)"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo ""

  log "Starting iteration $ITERATION"

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
  CLAUDE_EXIT_CODE=0
  claude -p "$(cat "$PROMPT_FILE")" > "$ITERATION_OUTPUT" 2> "$ITERATION_ERROR" || CLAUDE_EXIT_CODE=$?

  # Show output to terminal
  cat "$ITERATION_OUTPUT"

  if [[ $CLAUDE_EXIT_CODE -eq 0 ]]; then
    log "Iteration $ITERATION completed successfully"
  else
    log "Iteration $ITERATION exited with code $CLAUDE_EXIT_CODE (checking for completion anyway)"
    # Show errors if any
    if [[ -s "$ITERATION_ERROR" ]]; then
      echo -e "${YELLOW}Stderr output:${NC}"
      cat "$ITERATION_ERROR"
    fi
  fi

  # Read output and check for completion (check even if there was an error)
  OUTPUT=$(cat "$ITERATION_OUTPUT" 2>/dev/null || echo "")

  # Also check stderr in case the completion promise ended up there
  ERROR_OUTPUT=$(cat "$ITERATION_ERROR" 2>/dev/null || echo "")
  COMBINED_OUTPUT="$OUTPUT $ERROR_OUTPUT"

  if check_completion "$COMBINED_OUTPUT"; then
    echo ""
    echo -e "${GREEN}✅ Completion promise detected: <promise>${COMPLETION_PROMISE}</promise>${NC}"
    echo -e "${GREEN}🎉 Ralph loop completed successfully after $ITERATION iterations!${NC}"
    log "Completion promise detected, stopping"
    break
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
