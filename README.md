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

### Option 1: Global Setup Skill (Recommended)

If you have the `setup-ralph` skill installed globally:

```bash
cd your-repo
# In Claude Code:
/setup-ralph
```

### Option 2: Manual Installation

```bash
# Clone this template
git clone https://github.com/dearprudence978/ralph-template.git

# Copy to your project
cp -r ralph-template/.claude/skills/* your-repo/.claude/skills/
cp -r ralph-template/scripts your-repo/
mkdir -p your-repo/ralph-specs/{specs,docs,prompts}
```

### Option 3: Curl Installation

```bash
cd your-repo
curl -sL https://raw.githubusercontent.com/dearprudence978/ralph-template/main/install.sh | bash
```

## Included Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| spec-to-prd | `/spec-to-prd` | Transform feature ideas into specs and phased PRDs |
| run-phase | `/run-phase <prd-file>` | Execute a PRD phase with git branching |
| close-phase | `/close-phase <prd-file>` | Verify completion and merge to development |
| setup-ralph | `/setup-ralph` | Install Ralph into a new repository |

## Workflow

```
1. /spec-to-prd
   ├── Answer discovery questions
   ├── Codebase analysis (patterns, conventions)
   ├── Generate technical specification
   └── Create phased PRD with user stories

2. /run-phase prd-phase-1-*.json
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

After running `/spec-to-prd`:

```
your-repo/
├── .claude/
│   └── skills/
│       ├── spec-to-prd/
│       │   ├── SKILL.md
│       │   └── references/
│       ├── run-phase/
│       │   └── SKILL.md
│       └── close-phase/
│           └── SKILL.md
├── scripts/
│   └── ralph.sh           # Context-isolated iteration runner
└── ralph-specs/
    ├── specs/             # Technical specifications
    ├── docs/              # Completion reports
    ├── prompts/           # Phase prompts (for --isolated mode)
    ├── progress.txt       # Relay baton state file
    └── prd-phase-*.json   # Phase PRD files
```

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

## Recommended Permissions

Add to your `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(./scripts/ralph.sh:*)",
      "Bash(git checkout:*)",
      "Bash(git merge:*)"
    ]
  }
}
```

## References

- [Geoffrey Huntley's Ralph Wiggum](https://github.com/ghuntley/how-to-ralph-wiggum)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [A Brief History of Ralph](https://www.humanlayer.dev/blog/brief-history-of-ralph)

## License

MIT
