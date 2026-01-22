---
name: setup-ralph
description: Bootstrap Ralph workflow (spec-to-prd, run-phase, close-phase) into current repository. Use when setting up a new repo for autonomous phased development.
---

# Setup Ralph Workflow

Install the Ralph autonomous development workflow into the current repository.

## What Gets Installed

| Directory/File | Purpose |
|----------------|---------|
| `.claude/skills/spec-to-prd/` | Transform feature ideas into specs and PRDs |
| `.claude/skills/run-phase/` | Execute PRD phases with context isolation |
| `.claude/skills/close-phase/` | Verify completion and merge phases |
| `.claude/settings.local.json` | Permissions for autonomous Ralph operation |
| `scripts/ralph.sh` | Context-isolated iteration runner |
| `ralph-specs/` | Directory structure for specs, docs, prompts |
| `ralph-specs/WORKFLOW.md` | Quick reference guide |

## Prerequisites

- Current directory must be a git repository
- Internet access to download from GitHub

## Execution Steps

### Step 1: Check Prerequisites

First, verify we're in a git repository:

```bash
git rev-parse --git-dir > /dev/null 2>&1
```

If this fails, stop and inform the user they need to run `git init` first.

Check if Ralph is already installed:

```bash
test -d .claude/skills/spec-to-prd && echo "ALREADY_INSTALLED"
```

If already installed, ask the user if they want to reinstall/update.

### Step 2: Create Directory Structure

```bash
mkdir -p .claude/skills/spec-to-prd/references
mkdir -p .claude/skills/run-phase
mkdir -p .claude/skills/close-phase
mkdir -p scripts
mkdir -p ralph-specs/specs ralph-specs/docs ralph-specs/prompts
```

### Step 3: Download Skills from GitHub

**Base URL**: `https://raw.githubusercontent.com/dearprudence978/ralph-template/main`

Download each file using curl. For each file, use:
```bash
curl -sL "$BASE_URL/$PATH" -o "$LOCAL_PATH" --create-dirs
```

**Files to download:**

1. **spec-to-prd skill**:
   - `.claude/skills/spec-to-prd/SKILL.md`
   - `.claude/skills/spec-to-prd/references/spec-template.md`
   - `.claude/skills/spec-to-prd/references/prd-schema.md`
   - `.claude/skills/spec-to-prd/references/prd-template.md`
   - `.claude/skills/spec-to-prd/references/progress-template.md`
   - `.claude/skills/spec-to-prd/references/example-prd.json`
   - `.claude/skills/spec-to-prd/references/tutorial.md`

2. **run-phase skill**:
   - `.claude/skills/run-phase/SKILL.md`

3. **close-phase skill**:
   - `.claude/skills/close-phase/SKILL.md`

4. **ralph.sh script**:
   - `scripts/ralph.sh`

5. **README (workflow reference)**:
   - `ralph-specs/WORKFLOW.md` (downloaded from template README.md)

### Step 4: Set Permissions

```bash
chmod +x scripts/ralph.sh
```

### Step 5: Download Workflow README

Download the workflow reference guide:
```bash
curl -sL "$BASE_URL/README.md" -o "ralph-specs/WORKFLOW.md"
```

This gives users a quick refresher on how to use the Ralph workflow.

### Step 6: Create Placeholder Files

```bash
touch ralph-specs/specs/.gitkeep
touch ralph-specs/docs/.gitkeep
touch ralph-specs/prompts/.gitkeep
```

### Step 7: Create Settings File (if not exists)

Check if `.claude/settings.local.json` exists. If not, create it with baseline permissions for Ralph:

```bash
if [ ! -f .claude/settings.local.json ]; then
  # Create new settings file
fi
```

**Create `.claude/settings.local.json` with this content:**

```json
{
  "permissions": {
    "allow": [
      "Bash(./scripts/ralph.sh*)",
      "Bash(make *)",
      "Bash(npm *)",
      "Bash(docker compose*)",
      "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(git status*)",
      "Bash(git log*)",
      "Bash(git diff*)",
      "Bash(git branch*)",
      "Bash(curl*)"
    ],
    "ask": [
      "Bash(git push*)",
      "Bash(git merge*)",
      "Bash(git checkout development*)",
      "Bash(git checkout main*)",
      "Bash(git switch development*)",
      "Bash(git switch main*)"
    ],
    "deny": [
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git reset --hard*)",
      "Bash(git branch -d development)",
      "Bash(git branch -D development)",
      "Bash(git branch -d main)",
      "Bash(git branch -D main)"
    ]
  }
}
```

**If the file already exists**, inform the user:
```
Settings file already exists at .claude/settings.local.json
Please ensure these permissions are configured for Ralph to work:
- allow: Bash(./scripts/ralph.sh*)
- ask: Bash(git push*), Bash(git merge*), Bash(git checkout development/main*)
```

### Step 8: Verify Installation

Run these checks:
```bash
test -f .claude/skills/spec-to-prd/SKILL.md && echo "spec-to-prd: OK"
test -f .claude/skills/run-phase/SKILL.md && echo "run-phase: OK"
test -f .claude/skills/close-phase/SKILL.md && echo "close-phase: OK"
test -x scripts/ralph.sh && echo "ralph.sh: OK"
test -f ralph-specs/WORKFLOW.md && echo "WORKFLOW.md: OK"
test -f .claude/settings.local.json && echo "settings.local.json: OK"
```

### Step 9: Print Success Message

After successful installation, print:

```
Ralph workflow installed successfully!

Installed:
  Skills:
    /spec-to-prd  - Create specifications and PRDs from feature ideas
    /run-phase    - Execute PRD phases with git branching
    /close-phase  - Verify and merge completed phases

  Files:
    scripts/ralph.sh          - Context-isolated iteration runner
    ralph-specs/WORKFLOW.md   - Quick reference guide
    .claude/settings.local.json - Permissions for autonomous operation

Permissions configured:
  ✓ Ralph loop can run autonomously
  ✓ Git push/merge/checkout to main branches requires approval
  ✓ Dangerous git operations (force push, hard reset) are blocked

Next steps:
  1. Run /spec-to-prd to create your first specification
  2. The skill will guide you through discovery and PRD creation
  3. Use /run-phase <prd-file> to execute phases
  4. Use /close-phase <prd-file> to complete and merge
```

## Error Handling

If any download fails:
1. Report which file failed
2. Check if the GitHub repo exists and is accessible
3. Suggest manual installation as fallback

## Updating

To update an existing installation, run `/setup-ralph` again. It will:
1. Detect existing installation
2. Ask for confirmation to overwrite
3. Re-download all files from the latest version

## Manual Installation Alternative

If GitHub access fails, the user can manually copy files from another repo that has Ralph installed:

```bash
# From a repo with Ralph
cp -r .claude/skills/{spec-to-prd,run-phase,close-phase} /path/to/new-repo/.claude/skills/
cp scripts/ralph.sh /path/to/new-repo/scripts/
```
