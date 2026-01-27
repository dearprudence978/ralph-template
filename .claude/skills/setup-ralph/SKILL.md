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
| `.claude/skills/setup-ralph/` | Reinstall/update Ralph workflow |
| `.claude/settings.json` | Project-level sandbox + permission guardrails |
| `scripts/ralph.sh` | Context-isolated iteration runner |
| `ralph-specs/` | Directory structure for specs, docs, prompts |
| `ralph-specs/WORKFLOW.md` | Quick reference guide |

## Permission Model

Ralph uses a **sandbox + deny/ask** approach instead of individual command allowlists:

| Layer | Purpose | Example |
|-------|---------|---------|
| **Sandbox** | Auto-approve all Bash in sandboxed environment | `autoAllowBashIfSandboxed: true` |
| **Allow** | Broad tool-level permissions | `Bash`, `Read`, `Edit`, `Write`, `WebSearch` |
| **Deny** | Block destructive operations (always enforced) | `git push --force`, `git reset --hard`, delete main/development |
| **Ask** | Require human approval for risky-but-needed ops | `git push`, `git merge`, checkout main/development |

**Why this approach?**
- The original Ralph technique uses `--dangerously-skip-permissions` for autonomy
- This is safer: sandbox provides autonomy while deny/ask lists protect against mistakes
- No need to build up individual command allowlists over time
- `settings.json` is project-level (checked into repo) so all team members get the same guardrails

**Two settings files:**
- `.claude/settings.json` - Project-level (checked into repo), provides sandbox + permissions
- `.claude/settings.local.json` - User-level (gitignored), user-specific overrides

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
mkdir -p .claude/skills/run-phase/references
mkdir -p .claude/skills/close-phase
mkdir -p .claude/skills/setup-ralph
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
   - `.claude/skills/run-phase/references/viewlogs.txt`

3. **close-phase skill**:
   - `.claude/skills/close-phase/SKILL.md`

4. **setup-ralph skill** (self-referencing for updates):
   - `.claude/skills/setup-ralph/SKILL.md`

5. **ralph.sh script**:
   - `scripts/ralph.sh`

6. **README (workflow reference)**:
   - `ralph-specs/WORKFLOW.md` (downloaded from template README.md)

### Step 4: Set Script Permissions

```bash
chmod +x scripts/ralph.sh
```

### Step 5: Create Placeholder Files

```bash
touch ralph-specs/specs/.gitkeep
touch ralph-specs/docs/.gitkeep
touch ralph-specs/prompts/.gitkeep
```

### Step 6: Configure Settings (Project-Level)

Download and install `.claude/settings.json` from the template. This is the **project-level** settings file that provides sandbox mode and permission guardrails.

**If `.claude/settings.json` does NOT exist:**

```bash
curl -sL "$BASE_URL/.claude/settings.json" -o ".claude/settings.json"
```

This creates the following configuration:

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["docker"],
    "network": {
      "allowUnixSockets": ["/var/run/docker.sock"]
    }
  },
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch",
      "Read",
      "Edit",
      "Write",
      "Bash"
    ],
    "deny": [
      "Bash(git branch -d development)",
      "Bash(git branch -D development)",
      "Bash(git branch -d main)",
      "Bash(git branch -D main)",
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git reset --hard*)",
      "Bash(docker run -v /mnt/c*)",
      "Bash(docker run -v /mnt/d/*)",
      "Bash(docker run -v ~*)",
      "Bash(rm -rf /)",
      "Bash(rm -rf /*)"
    ],
    "ask": [
      "Bash(git push*)",
      "Bash(git merge*)",
      "Bash(git rebase*)",
      "Bash(git checkout development*)",
      "Bash(git checkout main*)",
      "Bash(git switch development*)",
      "Bash(git switch main*)"
    ]
  }
}
```

**If `.claude/settings.json` ALREADY exists:**

Check if sandbox is configured:
```bash
grep -q '"autoAllowBashIfSandboxed"' .claude/settings.json
```

- If sandbox is already present: skip, inform user settings are already configured
- If sandbox is missing: download Ralph settings to `.claude/settings.ralph.json` and inform user to merge manually:

```
ACTION REQUIRED: Merge .claude/settings.ralph.json into .claude/settings.json
Key sections to add:
  - sandbox.enabled: true
  - sandbox.autoAllowBashIfSandboxed: true
  - permissions.deny: [destructive git commands]
  - permissions.ask: [push, merge, checkout main/development]
```

**Note on settings.local.json:** If the user has an existing `.claude/settings.local.json`, leave it untouched. User-level settings override project-level settings and may contain per-user permissions accumulated over time.

### Step 7: Verify Installation

Run these checks:
```bash
test -f .claude/skills/spec-to-prd/SKILL.md && echo "spec-to-prd: OK"
test -f .claude/skills/run-phase/SKILL.md && echo "run-phase: OK"
test -f .claude/skills/close-phase/SKILL.md && echo "close-phase: OK"
test -f .claude/skills/setup-ralph/SKILL.md && echo "setup-ralph: OK"
test -x scripts/ralph.sh && echo "ralph.sh: OK"
test -f ralph-specs/WORKFLOW.md && echo "WORKFLOW.md: OK"
test -f .claude/settings.json && echo "settings.json: OK"
```

### Step 8: Print Success Message

After successful installation, print:

```
Ralph workflow installed successfully!

Installed:
  Skills:
    /spec-to-prd   - Create specifications and PRDs from feature ideas
    /run-phase     - Execute PRD phases with git branching
    /close-phase   - Verify and merge completed phases
    /setup-ralph   - Reinstall/update Ralph workflow

  Files:
    scripts/ralph.sh           - Context-isolated iteration runner
    ralph-specs/WORKFLOW.md    - Quick reference guide
    .claude/settings.json     - Sandbox + permission guardrails (project-level)

Permission model:
  Sandbox:  autoAllowBashIfSandboxed = true (autonomous operation)
  Deny:     Force push, hard reset, delete main/development branches
  Ask:      Push, merge, rebase, checkout main/development
  Allow:    All other Bash, Read, Edit, Write, WebSearch, WebFetch

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
4. Merge settings.json if existing one lacks sandbox config

## Manual Installation Alternative

If GitHub access fails, the user can manually copy files from another repo that has Ralph installed:

```bash
# From a repo with Ralph
cp -r .claude/skills/{spec-to-prd,run-phase,close-phase,setup-ralph} /path/to/new-repo/.claude/skills/
cp .claude/settings.json /path/to/new-repo/.claude/settings.json
cp scripts/ralph.sh /path/to/new-repo/scripts/
```
