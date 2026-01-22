---
name: run-phase
description: Execute a PRD phase with Ralph loop. Usage: /run-phase <phase-file>
---

# Run Phase

Execute user stories from a PRD phase file with git branching, progress tracking, and completion documentation.

## Usage

```
/run-phase <phase-file> [--isolated]
```

Examples:
```
/run-phase prd-phase-1-infrastructure.json           # Uses plugin (in-session)
/run-phase prd-phase-2-authentication.json --isolated # Uses bash (fresh context each iteration)
```

## Two Approaches: Plugin vs Bash

### Plugin Approach (Default)

Uses `/ralph-loop` command within the current session:
- **Convenient**: Runs in current terminal
- **Interactive**: See progress in real-time
- **Context accumulates**: Previous iterations visible in session

### Bash Approach (`--isolated`)

Uses `./scripts/ralph.sh` for true context isolation:
- **Fresh context**: Each iteration is a new Claude process
- **No context rot**: Accumulated tokens don't degrade quality
- **Original Ralph technique**: Matches Geoffrey Huntley's design

**Recommendation**: Use `--isolated` for phases with 3+ stories to prevent context degradation.

---

## Workflow

### Step 1: Create Feature Branch

Extract phase number and name from filename, then create branch:

```bash
git checkout development
git pull origin development 2>/dev/null || true
git checkout -b feature/{phase-name}
```

Example: `prd-phase-1-infrastructure.json` → `feature/phase-1-infrastructure`

### Step 2a: Execute Ralph Loop (Plugin - Default)

**CRITICAL**: The prompt below includes mandatory progress.txt updates. Do not remove these instructions.

```
/ralph-loop "Implement user stories from ralph-specs/{phase-file} using the PROGRESS-DRIVEN WORKFLOW below.

## PROGRESS-DRIVEN WORKFLOW

You are part of a continuous development loop. Your job is to:
1. Read progress.txt to understand what's done and what's next
2. Complete exactly ONE story (not more!)
3. Update progress.txt with what you did
4. Output a signal and STOP - let the next iteration handle the next story

**CRITICAL: ONE STORY PER ITERATION**
- Complete ONE story, then STOP
- Do NOT start the next story in the same iteration
- Output `<story-complete>STORY_ID</story-complete>` after finishing a story
- Only output `<promise>PHASE_COMPLETE</promise>` when ALL stories pass

Think of it as a relay race - you run ONE leg, pass the baton, and a fresh runner continues.

## BEFORE STARTING ANY STORY

1. Read ralph-specs/progress.txt FIRST - check:
   - Completed Stories section for what's done
   - Current Work section for any in-progress work
   - Learnings section for gotchas to avoid
   - Blockers section for unresolved issues

2. Find the next story in the PRD where:
   - passes=false
   - All dependencies have passes=true

3. Update progress.txt 'Current Work' section:
   ```
   ## Current Work
   Story: [STORY_ID] - [Title]
   Started: [timestamp]
   Status: IN_PROGRESS
   Plan:
   - [ ] Step 1
   - [ ] Step 2
   ```

## DURING STORY IMPLEMENTATION

1. Follow the acceptance criteria from the PRD
2. Run verification commands to confirm progress
3. If you discover a useful pattern or gotcha, IMMEDIATELY append to Learnings:
   ```
   ### Learning: [Topic]
   - Context: [what you were doing]
   - Discovery: [what you learned]
   - Action: [how to handle it in future]
   ```

4. If blocked for 3+ attempts, append to Blockers:
   ```
   ### Blocker: [STORY_ID] - [timestamp]
   - Issue: [description]
   - Attempts: [what you tried]
   - Status: BLOCKED | RESOLVED
   - Resolution: [if resolved, how]
   ```

## AFTER COMPLETING A STORY

1. Run ALL verification commands from the PRD
2. If all pass, update the PRD: set passes=true, add notes
3. Commit with message '[STORY_ID]: [title]'
4. Update progress.txt - append to Completed Stories:
   ```
   ### [STORY_ID]: [Title]
   - Completed: [timestamp]
   - Files: [comma-separated list]
   - Verification: [summary of commands run]
   - Notes: [key implementation details]
   ```

5. Clear the Current Work section

## AFTER COMPLETING ONE STORY - STOP AND SIGNAL

**If more stories remain (some have passes=false):**
Output this signal and STOP immediately:
```
<story-complete>STORY_ID</story-complete>
```

**If ALL stories now have passes=true:**
Output this signal and STOP immediately:
```
<promise>PHASE_COMPLETE</promise>
```

Do NOT continue to the next story. A fresh iteration will pick it up.

This is a TRUTH statement - never output signals falsely." --max-iterations 30 --completion-promise "PHASE_COMPLETE"
```

### Step 2b: Execute Ralph Loop (Bash - Isolated)

If `--isolated` flag is used, create a prompt file and run the bash script:

1. Create prompt file `ralph-specs/prompts/{phase-name}.md`:

```markdown
# Phase {N}: {Name} - Implementation Task

## Your Mission

Implement user stories from `ralph-specs/{phase-file}`.

## CRITICAL: Read State First

You have NO memory of previous iterations. Before doing ANYTHING:

1. **Read `ralph-specs/progress.txt`** - This is your only source of truth:
   - Check "Current Work" for any in-progress story
   - Check "Completed Stories" for what's already done
   - Check "Learnings" for gotchas to avoid
   - Check "Blockers" for unresolved issues

2. **Read the PRD file** - Check which stories have `passes: true`

3. **Check git log**: `git log --oneline -10`

## CRITICAL: One Story Per Iteration

**Complete exactly ONE story per iteration, then STOP.**

Do NOT start the next story. A fresh context will handle it.

## Implementation Workflow

### Finding the Next Story

Look in the PRD for the first story where:
- `passes: false`
- All items in `dependsOn` have `passes: true`

If "Current Work" in progress.txt shows an in-progress story, resume that one.

### Before Starting Work

Update progress.txt "Current Work" section with story ID, timestamp, and plan.

### During Implementation

1. Follow acceptance criteria from the PRD
2. Run verification commands to confirm progress
3. If you discover a gotcha, IMMEDIATELY append to Learnings
4. If blocked 3+ times, append to Blockers

### After Completing the Story

1. Run ALL verification commands from the PRD
2. If all pass: update PRD (`passes: true`), commit, update progress.txt
3. Clear "Current Work" section

## Completion Signals - STOP AFTER OUTPUTTING

**After completing ONE story (more stories remain):**
```
<story-complete>STORY_ID</story-complete>
```
Then STOP. Do not continue.

**When ALL stories have `passes: true`:**
```
<promise>PHASE_COMPLETE</promise>
```
Then STOP. The phase is done.

Only output this when it is genuinely TRUE. Do not lie to exit the loop.
```

2. Run the bash script:

```bash
mkdir -p ralph-specs/prompts
# Create prompt file as above
./scripts/ralph.sh ralph-specs/prompts/{phase-name}.md \
  --max-iterations 30 \
  --completion-promise "PHASE_COMPLETE"
```

### Step 3: Generate Completion Document

After Ralph completes, create `ralph-specs/docs/{phase-name}-completion.md`:

```markdown
# Phase {N}: {Name} - Completion Report

**Completed:** {date}
**Branch:** feature/{phase-name}
**PRD:** ralph-specs/{phase-file}

## Summary

{2-3 sentences on what was accomplished}

## Stories Completed

| ID | Title | Status |
|----|-------|--------|
{List each story with id, title, and passes status}

## Files Created/Modified

{List files touched during this phase}

## Verification Results

{Summary of verification commands and outcomes}

## Learnings (from progress.txt)

{Copy relevant learnings discovered during this phase}

## Ready for Next Phase

- [ ] All stories pass
- [ ] progress.txt updated with all completed stories
- [ ] No uncommitted changes
- [ ] Branch pushed
```

Commit the document:
```bash
mkdir -p ralph-specs/docs
git add ralph-specs/docs/
git commit -m "docs: {phase-name} completion report"
```

---

## Plugin vs Bash: When to Use Which

| Scenario | Recommended Approach |
|----------|---------------------|
| 1-2 simple stories | Plugin (default) |
| 3+ stories | Bash (`--isolated`) |
| Complex implementation | Bash (`--isolated`) |
| Debugging/interactive work | Plugin (default) |
| Long-running phase | Bash (`--isolated`) |
| Network-heavy builds | Bash (`--isolated`) - handles interruptions better |

---

## Context Window Management

### The Problem: Context Rot

As tokens accumulate in a session:
1. Early in context: Claude is sharp and focused
2. Late in context: Quality degrades from accumulated noise
3. Multiple stories: Risk of referencing stale information

### The Solution: True Isolation

The bash approach (`--isolated`) solves this:
1. Each iteration is a fresh `claude` process
2. Previous reasoning is completely discarded
3. Only filesystem state (files, git, progress.txt) carries forward
4. Quality stays consistent across all iterations

### The "Relay Baton" Pattern

```
Iteration 1: Read progress.txt → Do work → Write progress.txt → Exit
   ↓
Iteration 2: Read progress.txt → Do work → Write progress.txt → Exit
   ↓
Iteration 3: Read progress.txt → Do work → Write progress.txt → Exit
```

State flows through files, not through conversation memory.

---

## Check Progress

```bash
# View story status from PRD
cat ralph-specs/<phase-file> | jq '.userStories[] | {id, title, passes}'

# View progress log
cat ralph-specs/progress.txt | grep -A5 "## Completed Stories"

# View Ralph bash logs (if using --isolated)
ls -la .claude/ralph-logs/
```

---

## Progress.txt Structure

The progress file MUST have these sections (Ralph updates them during the loop):

```markdown
## Current Work
[Ralph updates this with the current story being worked on]

## Completed Stories
[Ralph appends here after each story completes]

## Learnings
[Ralph appends here when discovering patterns or gotchas]

## Blockers Encountered
[Ralph documents blocking issues here]
```

---

## Why Progress Tracking Matters

Based on best practices from autonomous AI agent research:

1. **Relay baton pattern**: Each iteration passes context to the next via the file
2. **Reduces context drift**: Without written progress, the model may repeat work or go in circles
3. **Self-teaching**: Learnings section prevents repeating the same mistakes
4. **Audit trail**: Clear record of what was done and why
5. **Recovery**: If the loop restarts, progress.txt shows exactly where to resume

---

## Sources

- [Geoffrey Huntley's Ralph Wiggum](https://github.com/ghuntley/how-to-ralph-wiggum) - Original technique with context isolation
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) - Using markdown as working scratchpad
- [Continuous Claude](https://github.com/AnandChowdhary/continuous-claude) - Relay race pattern for iterative loops
- [A Brief History of Ralph](https://www.humanlayer.dev/blog/brief-history-of-ralph) - Evolution of the technique
