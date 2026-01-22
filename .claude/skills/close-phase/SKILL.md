---
name: close-phase
description: Verify phase completion and merge to development. Usage: /close-phase <phase-file>
---

# Close Phase

Verify that a phase is truly complete, generate/update completion documentation, and merge the feature branch back into development.

## Usage

```
/close-phase <phase-file>
```

Examples:
```
/close-phase prd-phase-1-infrastructure.json
/close-phase prd-phase-2-authentication.json
```

---

## Workflow

### Step 1: Pre-flight Checks

Before anything else, verify the environment:

```bash
# Check we're on a feature branch (not development/main)
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

# Check for uncommitted changes
git status --porcelain
```

**STOP if:**
- On `development` or `main` branch (should be on `feature/{phase-name}`)
- Uncommitted changes exist (commit or stash first)

### Step 2: Verify All Stories Pass

Read the PRD file and check every story:

```bash
# Extract story status
cat ralph-specs/{phase-file} | jq '.userStories[] | {id, title, passes}'
```

**Checklist:**

| Check | Command | Expected |
|-------|---------|----------|
| All stories pass | `jq '[.userStories[].passes] \| all'` | `true` |
| No empty notes | `jq '.userStories[] \| select(.notes == "" or .notes == null) \| .id'` | No output |

**STOP if any story has `passes: false`** - phase is not complete.

### Step 3: Verify Progress.txt

Check that progress.txt reflects completion:

```bash
# Check Completed Stories section has all story IDs
cat ralph-specs/progress.txt | grep -A50 "## Completed Stories"
```

**Verify:**
- All story IDs from the PRD appear in "Completed Stories"
- "Current Work" section is empty or shows "[No story in progress]"
- No unresolved items in "Blockers Encountered"

### Step 4: Verify/Create Completion Document

Check if completion document exists:

```bash
# Extract phase name from filename (e.g., prd-phase-1-infrastructure.json -> phase-1-infrastructure)
PHASE_NAME=$(echo "{phase-file}" | sed 's/prd-//' | sed 's/\.json//')
ls -la ralph-specs/docs/${PHASE_NAME}-completion.md
```

**If missing, create it:**

```markdown
# Phase {N}: {Name} - Completion Report

**Completed:** {date}
**Branch:** feature/{phase-name}
**PRD:** ralph-specs/{phase-file}

## Summary

{Extract from PRD phaseDescription + summary of what was built}

## Stories Completed

| ID | Title | Status |
|----|-------|--------|
{For each story in PRD: id, title, passes status}

## Files Created/Modified

{List key files from each story's filesToModify}

## Verification Results

{Run and document results of verificationCommands from PRD}

## Learnings (from progress.txt)

{Copy learnings discovered during this phase}

## Blockers Resolved

{Copy resolved blockers from progress.txt}

## Ready for Merge

- [x] All stories pass
- [x] progress.txt updated
- [x] Completion document created
- [x] No uncommitted changes
```

Commit if newly created:
```bash
git add ralph-specs/docs/
git commit -m "docs: ${PHASE_NAME} completion report"
```

### Step 5: Run Final Verification

Execute the phase's global success criteria:

```bash
# Extract and run globalSuccessCriteria from PRD
cat ralph-specs/{phase-file} | jq -r '.globalSuccessCriteria[]'
```

Run each criterion and document results. Common checks:

```bash
# Example for Phase 1 (Infrastructure)
docker compose ps                    # Containers running?
make status                          # Services healthy?
docker compose exec app npm run typecheck  # Types pass?
```

**STOP if any verification fails** - fix before merging.

### Step 6: Merge to Development

Once all checks pass:

```bash
# Ensure we have latest development
git fetch origin development

# Switch to development
git checkout development
git pull origin development

# Merge the feature branch
FEATURE_BRANCH="feature/${PHASE_NAME}"
git merge ${FEATURE_BRANCH} --no-ff -m "Merge ${FEATURE_BRANCH}: Phase complete

Stories completed:
$(cat ralph-specs/{phase-file} | jq -r '.userStories[] | "- " + .id + ": " + .title')

See: ralph-specs/docs/${PHASE_NAME}-completion.md"

# Push to remote
git push origin development
```

### Step 7: Cleanup (Optional)

After successful merge:

```bash
# Delete local feature branch
git branch -d feature/${PHASE_NAME}

# Delete remote feature branch (if pushed)
git push origin --delete feature/${PHASE_NAME} 2>/dev/null || true
```

### Step 8: Update Progress.txt

Add phase completion entry:

```markdown
## Phase Completions

### Phase {N}: {Name}
- Completed: {timestamp}
- Branch: feature/{phase-name} → development
- Stories: {list of story IDs}
- Duration: {if tracked}
```

---

## Verification Checklist

Before merging, all must be TRUE:

```markdown
## Close Phase Checklist

### PRD Status
- [ ] All userStories have passes: true
- [ ] All userStories have non-empty notes
- [ ] globalSuccessCriteria all pass

### Progress.txt Status
- [ ] All story IDs in "Completed Stories"
- [ ] "Current Work" is empty
- [ ] No unresolved "Blockers"

### Documentation
- [ ] Completion document exists at ralph-specs/docs/{phase-name}-completion.md
- [ ] Completion document has all sections filled

### Git Status
- [ ] No uncommitted changes
- [ ] Feature branch is ahead of development (has commits to merge)
- [ ] No merge conflicts with development

### Final Verification
- [ ] All globalSuccessCriteria commands pass
- [ ] Application runs correctly
- [ ] No TypeScript/lint errors
```

---

## Error Handling

### Story Not Passing

```
ERROR: Story {ID} has passes: false

Action: Complete the story before closing phase.
Run: /run-phase {phase-file}
```

### Uncommitted Changes

```
ERROR: Uncommitted changes detected

Action: Commit or stash changes first.
Run: git status
     git add . && git commit -m "WIP: {description}"
```

### Merge Conflicts

```
ERROR: Merge conflict with development

Action: Resolve conflicts manually.
Run: git checkout development
     git pull origin development
     git checkout feature/{phase-name}
     git merge development
     # Resolve conflicts
     git add .
     git commit -m "Resolve merge conflicts with development"
```

### Missing Completion Document

```
WARNING: Completion document missing

Action: Creating completion document from PRD and progress.txt...
```

---

## Example Output

```
╔══════════════════════════════════════════════════════════════╗
║  Close Phase: prd-phase-1-infrastructure.json                ║
╚══════════════════════════════════════════════════════════════╝

Step 1: Pre-flight Checks
  ✓ On branch: feature/phase-1-infrastructure
  ✓ No uncommitted changes

Step 2: Verify Stories
  ✓ CRM-001: passes=true
  ✓ CRM-002: passes=true
  ✓ All 2 stories complete

Step 3: Verify Progress.txt
  ✓ CRM-001 in Completed Stories
  ✓ CRM-002 in Completed Stories
  ✓ Current Work is empty
  ✓ No unresolved blockers

Step 4: Completion Document
  ✓ ralph-specs/docs/phase-1-infrastructure-completion.md exists

Step 5: Final Verification
  ✓ docker compose ps - containers running
  ✓ Database has 8 tables
  ✓ TypeScript compiles

Step 6: Merge to Development
  ✓ Fetched latest development
  ✓ Merged feature/phase-1-infrastructure
  ✓ Pushed to origin/development

Step 7: Cleanup
  ✓ Deleted local branch feature/phase-1-infrastructure

═══════════════════════════════════════════════════════════════
✅ Phase 1 (Infrastructure) closed successfully!

   Next: /run-phase prd-phase-2-authentication.json
═══════════════════════════════════════════════════════════════
```

---

## Quick Reference

```bash
# Full close sequence
/close-phase prd-phase-1-infrastructure.json

# Manual verification only (no merge)
cat ralph-specs/prd-phase-1-infrastructure.json | jq '[.userStories[].passes] | all'

# Check what would be merged
git log development..HEAD --oneline

# Preview merge
git merge development --no-commit --no-ff
git merge --abort  # If just previewing
```
