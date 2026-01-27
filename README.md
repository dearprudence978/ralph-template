# Ralph Template

Portable workflow for autonomous phased development with Claude Code.

## What is Ralph?

Ralph is an autonomous development workflow that:
- Transforms feature ideas into structured specifications and PRDs
- Executes implementation in isolated phases with progress tracking
- Uses context isolation to prevent "context rot" in long sessions
- Tracks progress via file-based state (the "relay baton" pattern)

Based on [Geoffrey Huntley's Ralph Wiggum technique](https://github.com/ghuntley/how-to-ralph-wiggum).

## Quick Setup

### Option 1: Curl Installation (Recommended)

```bash
cd your-repo
curl -sL https://raw.githubusercontent.com/dearprudence978/ralph-template/main/install.sh | bash
```

This downloads all skills, scripts, and configures sandbox permissions automatically.

### Option 2: Setup Skill

If you have the `setup-ralph` skill installed:

```bash
cd your-repo
# In Claude Code:
/setup-ralph
```

### Option 3: Manual Installation

```bash
# Clone this template
git clone https://github.com/dearprudence978/ralph-template.git

# Copy to your project
cp -r ralph-template/.claude/skills/* your-repo/.claude/skills/
cp ralph-template/.claude/settings.json your-repo/.claude/settings.json
cp -r ralph-template/scripts your-repo/
mkdir -p your-repo/ralph-specs/{specs,docs,prompts}
```

## Included Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| spec-to-prd | `/spec-to-prd` | Transform feature ideas into specs and phased PRDs |
| run-phase | `/run-phase <prd-file>` | Execute a PRD phase with git branching |
| close-phase | `/close-phase <prd-file>` | Verify completion and merge to development |
| setup-ralph | `/setup-ralph` | Install/update Ralph in a repository |

## Workflow

```
1. /spec-to-prd
   ├── Answer discovery questions
   ├── Codebase analysis (patterns, conventions)
   ├── Generate technical specification
   └── Create phased PRD with user stories

2. /run-phase prd-phase-1-*.json [--isolated]
   ├── Create feature branch
   ├── Ralph loop: read progress → implement → update progress
   ├── Each story: implement → verify → commit
   └── Generate completion document

3. /close-phase prd-phase-1-*.json
   ├── Verify all stories pass
   ├── Verify progress.txt complete
   ├── Run final verification
   └── Merge to development
```

## Directory Structure

After installation and running `/spec-to-prd`:

```
your-repo/
├── .claude/
│   ├── settings.json          # Sandbox + permission guardrails
│   └── skills/
│       ├── spec-to-prd/
│       │   ├── SKILL.md
│       │   └── references/
│       ├── run-phase/
│       │   └── SKILL.md
│       ├── close-phase/
│       │   └── SKILL.md
│       └── setup-ralph/
│           └── SKILL.md
├── scripts/
│   └── ralph.sh               # Context-isolated iteration runner
└── ralph-specs/
    ├── specs/                  # Technical specifications
    ├── docs/                   # Completion reports
    ├── prompts/                # Phase prompts (for --isolated mode)
    ├── progress.txt            # Relay baton state file
    └── prd-phase-*.json        # Phase PRD files
```

## Permission Model

Ralph uses a **sandbox + deny/ask** approach for autonomous operation without `--dangerously-skip-permissions`.

### How It Works

The installer creates `.claude/settings.json` (project-level, checked into your repo):

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
    "allow": ["WebSearch", "WebFetch", "Read", "Edit", "Write", "Bash"],
    "deny": [ ... ],
    "ask": [ ... ]
  }
}
```

| Layer | What it does | Example |
|-------|--------------|---------|
| **Sandbox** | Auto-approve all Bash commands in sandboxed env | Ralph loop runs without prompts |
| **Allow** | Broad tool-level permissions | `Bash`, `Read`, `Edit`, `Write` |
| **Deny** | Block destructive operations (always enforced) | `git push --force`, `git reset --hard` |
| **Ask** | Require human approval for risky-but-needed ops | `git push`, `git merge` |

### Configuring for Your Branch Strategy

The default `settings.json` protects `main` and `development` branches. **You should customise the deny and ask lists to match your branching strategy.**

#### Example: `development` → `main` Flow

This is the default configuration, suitable for teams using a staging branch:

```
feature/phase-X → development → main
                  (staging)     (production)
```

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

**What this does:**
- Ralph can freely create feature branches, commit, and work autonomously
- Deleting `main` or `development` is **blocked** (deny)
- Force push and hard reset are **blocked** (deny)
- Pushing, merging, and checking out protected branches **requires approval** (ask)
- Docker volume mounts from host filesystem are **blocked** (deny)

#### Example: `main`-Only Flow

For simpler projects with just a `main` branch:

```json
{
  "permissions": {
    "deny": [
      "Bash(git branch -d main)",
      "Bash(git branch -D main)",
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git reset --hard*)"
    ],
    "ask": [
      "Bash(git push*)",
      "Bash(git merge*)",
      "Bash(git checkout main*)",
      "Bash(git switch main*)"
    ]
  }
}
```

#### Example: GitFlow (`develop` / `release` / `main`)

```json
{
  "permissions": {
    "deny": [
      "Bash(git branch -d develop)",
      "Bash(git branch -D develop)",
      "Bash(git branch -d main)",
      "Bash(git branch -D main)",
      "Bash(git branch -d release*)",
      "Bash(git branch -D release*)",
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git reset --hard*)"
    ],
    "ask": [
      "Bash(git push*)",
      "Bash(git merge*)",
      "Bash(git rebase*)",
      "Bash(git checkout develop*)",
      "Bash(git checkout main*)",
      "Bash(git checkout release*)",
      "Bash(git switch develop*)",
      "Bash(git switch main*)",
      "Bash(git switch release*)"
    ]
  }
}
```

#### Adding Your Own Rules

The pattern syntax supports wildcards:

```
"Bash(git push*)"          # Matches any git push command
"Bash(git branch -D main)" # Matches exact command only
"Bash(docker run -v ~*)"   # Matches docker volume mounts from home dir
```

**Deny** always wins over allow. **Ask** takes precedence over sandbox auto-approve. Use deny for operations that should never happen, and ask for operations that need a human decision.

### Two Settings Files

| File | Scope | Git | Purpose |
|------|-------|-----|---------|
| `.claude/settings.json` | Project | Checked in | Shared team guardrails |
| `.claude/settings.local.json` | User | Gitignored | Per-user overrides and accumulated permissions |

`settings.local.json` is automatically created by Claude Code as you approve commands during sessions. You don't need to manage it manually.

## Key Concepts

### The Relay Baton Pattern

Each Ralph iteration:
1. Reads `progress.txt` to understand context
2. Makes meaningful progress on one story
3. Writes updates to `progress.txt` for future iterations
4. State flows through files, not conversation memory

### Context Isolation

Use `--isolated` flag for phases with 3+ stories:

```bash
/run-phase prd-phase-2-auth.json --isolated
```

This runs each iteration as a fresh Claude process, preventing context degradation.

### PRD Structure

Each PRD contains:
- `userStories[]` - Implementation tasks with acceptance criteria
- `verificationCommands` - Commands to verify each story
- `passes` - Boolean flag (set to true when story completes)
- `dependsOn` - Story dependencies

## References

- [Geoffrey Huntley's Ralph Wiggum](https://github.com/ghuntley/how-to-ralph-wiggum)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [A Brief History of Ralph](https://www.humanlayer.dev/blog/brief-history-of-ralph)

## License

MIT
