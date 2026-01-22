---
name: setup-ralph
description: Bootstrap Ralph workflow (spec-to-prd, run-phase, close-phase) into current repository. Use when setting up a new repo for autonomous phased development.
---

# Setup Ralph Workflow

Install the Ralph autonomous development workflow into the current repository.

## What Gets Installed

| Directory | Purpose |
|-----------|---------|
| `.claude/skills/spec-to-prd/` | Transform feature ideas into specs and PRDs |
| `.claude/skills/run-phase/` | Execute PRD phases with context isolation |
| `.claude/skills/close-phase/` | Verify completion and merge phases |
| `scripts/ralph.sh` | Context-isolated iteration runner |
| `ralph-specs/` | Directory structure for specs, docs, prompts |

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

### Step 4: Set Permissions

```bash
chmod +x scripts/ralph.sh
```

### Step 5: Create Placeholder Files

```bash
touch ralph-specs/specs/.gitkeep
touch ralph-specs/docs/.gitkeep
touch ralph-specs/prompts/.gitkeep
```

### Step 6: Verify Installation

Run these checks:
```bash
test -f .claude/skills/spec-to-prd/SKILL.md && echo "spec-to-prd: OK"
test -f .claude/skills/run-phase/SKILL.md && echo "run-phase: OK"
test -f .claude/skills/close-phase/SKILL.md && echo "close-phase: OK"
test -x scripts/ralph.sh && echo "ralph.sh: OK"
```

### Step 7: Print Success Message

After successful installation, print:

```
Ralph workflow installed successfully!

Installed skills:
  /spec-to-prd  - Create specifications and PRDs from feature ideas
  /run-phase    - Execute PRD phases with git branching
  /close-phase  - Verify and merge completed phases

Next steps:
  1. Run /spec-to-prd to create your first specification
  2. The skill will guide you through discovery and PRD creation
  3. Use /run-phase <prd-file> to execute phases
  4. Use /close-phase <prd-file> to complete and merge

Recommended: Add to .claude/settings.local.json:
{
  "permissions": {
    "allow": [
      "Bash(./scripts/ralph.sh:*)"
    ]
  }
}
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
