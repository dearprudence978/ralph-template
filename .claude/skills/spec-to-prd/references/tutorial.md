# Ralph Wiggum + Spec-to-PRD Workflow Tutorial

A complete guide to setting up an autonomous development workflow using the Ralph Wiggum plugin for Claude Code.

---

## Table of Contents

1. [Understanding the Workflow](#understanding-the-workflow)
2. [Prerequisites](#prerequisites)
3. [Part 1: Install Ralph Wiggum Plugin](#part-1-install-ralph-wiggum-plugin)
4. [Part 2: Create Folder Structure](#part-2-create-folder-structure)
5. [Part 3: Install the Skill](#part-3-install-the-skill)
6. [Part 4: Codebase Analysis](#part-4-codebase-analysis)
7. [Part 5: Using the Workflow](#part-5-using-the-workflow)
8. [Part 6: Running Ralph](#part-6-running-ralph)
9. [Part 7: JSON Tracking](#part-7-json-tracking)
10. [Part 8: Progress File](#part-8-progress-file)
11. [Best Practices](#best-practices)
12. [Troubleshooting](#troubleshooting)

---

## Understanding the Workflow

```
Feature Idea → Codebase Analysis → Spec → prd.json + progress.txt → Ralph Loop → Done
```

**Key files:**
- `prd.json` - Master tracking with `passes: true/false` per story
- `progress.txt` - Auto-populated codebase patterns + Ralph's learnings
- `specs/*.md` - Generated specification documents

---

## Prerequisites

- Claude Code CLI 2.0.76+
- Anthropic API subscription
- `jq` installed (`brew install jq`)

---

## Part 1: Install Ralph Wiggum Plugin

```bash
claude
/plugin install ralph-wiggum@claude-plugins-official
/plugin list  # Verify installation
```

**Commands added:**
- `/ralph-loop "prompt" --max-iterations N --completion-promise "TEXT"`
- `/cancel-ralph`

---

## Part 2: Create Folder Structure

```bash
mkdir -p ralph-specs/specs
```

---

## Part 3: Install the Skill

```bash
mkdir -p .claude/skills
cp -r ralph-specs-skill/skills/spec-to-prd .claude/skills/
```

Structure:
```
.claude/skills/spec-to-prd/
├── SKILL.md
└── references/
    ├── spec-template.md
    ├── prd-template.md
    ├── prd-schema.md
    └── progress-template.md
```

---

## Part 4: Codebase Analysis

The skill automatically scans your repo before generating anything:

| Scans | Extracts |
|-------|----------|
| `package.json` | Language, framework, scripts, dependencies |
| `tsconfig.json` | TypeScript settings |
| `prisma/schema.prisma` | ORM, database type |
| `jest.config.*` | Test framework, patterns |
| Existing source files | Naming conventions, export style |
| Directory structure | Where services, types, tests go |

**Output:** Auto-populated `progress.txt` with discovered patterns.

---

## Part 5: Using the Workflow

### Trigger the skill:

```
Create a spec for user authentication with email/password login and password reset.
```

### Claude will:
1. Ask discovery questions
2. Analyze your codebase
3. Generate `ralph-specs/specs/AUTH-user-auth.md`
4. Generate `ralph-specs/prd.json`
5. Generate `ralph-specs/progress.txt` (auto-populated)

### Review before running Ralph:

```bash
# Check the spec
cat ralph-specs/specs/AUTH-user-auth.md

# Check user stories
cat ralph-specs/prd.json | jq '.userStories[] | {id, title, passes}'

# Check discovered patterns
cat ralph-specs/progress.txt
```

### Add any missing patterns:

```bash
echo "
### Additional Notes
- Always use feature flags
- Ignore legacy code in src/old/
" >> ralph-specs/progress.txt
```

---

## Part 6: Running Ralph

### Start the loop:

```
/ralph-loop "Read ralph-specs/prd.json and implement user stories in priority order.

For each story where passes=false and dependencies are met:
1. Read ralph-specs/progress.txt for codebase patterns
2. Implement requirements in specified files
3. Run verification commands
4. If criteria pass, update passes to true in prd.json
5. Add notes and commit

Output <promise>ALL_STORIES_COMPLETE</promise> when done." --max-iterations 50 --completion-promise "ALL_STORIES_COMPLETE"
```

### Monitor progress:

```bash
cat ralph-specs/prd.json | jq '.userStories[] | {id, title, passes}'
```

### Stop if needed:

```
/cancel-ralph
```

### Resume after interruption:

Just run the same command again. Ralph reads `prd.json` and continues from incomplete stories.

---

## Part 7: JSON Tracking

### prd.json structure:

```json
{
  "userStories": [
    {
      "id": "AUTH-001",
      "title": "Create User schema",
      "acceptanceCriteria": ["criterion 1", "criterion 2"],
      "verificationCommands": ["npm run test"],
      "dependsOn": [],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

### Key fields:
- `passes` - Tracking field, `false` until complete
- `dependsOn` - Story IDs that must complete first
- `verificationCommands` - Commands Ralph runs to verify
- `notes` - Ralph adds implementation details

### Useful commands:

```bash
# All stories with status
cat ralph-specs/prd.json | jq '.userStories[] | {id, title, passes}'

# Count remaining
cat ralph-specs/prd.json | jq '[.userStories[] | select(.passes == false)] | length'

# See completed
cat ralph-specs/prd.json | jq '.userStories[] | select(.passes == true)'
```

---

## Part 8: Progress File

### Auto-populated content:

```markdown
### Code Style (detected)
- Naming: camelCase for variables, PascalCase for types
- Exports: Named exports
- Async: async/await pattern

### File Organization (detected)
- Services: src/services/*.service.ts
- Types: src/types/*.types.ts

### Available Scripts
- npm run test
- npm run lint
- npm run db:migrate

### Key Dependencies
- bcrypt, zod, prisma
```

### Ralph adds during execution:

```markdown
## Completed Stories
### AUTH-001: Create User schema
- Completed: 2026-01-14T10:15:00Z
- Notes: Used UUID for id, added email unique constraint

## Learnings
- Prisma requires `npx prisma generate` after schema changes
```

---

## Best Practices

1. **Always set `--max-iterations`** to prevent runaway loops
2. **Review all files** before running Ralph
3. **Test verification commands** manually first
4. **Keep stories small**: 1-5 files, 1-3 iterations
5. **Write specific acceptance criteria**: "Returns 200 with {id, email}" not "Works"

---

## Troubleshooting

### Ralph stops early
Run the command again. It continues from incomplete stories.

### Wrong execution order
Check `dependsOn` arrays in prd.json.

### Inconsistent code style
Add more detail to progress.txt.

### Verification commands fail
Edit `verificationCommands` in prd.json to match your actual commands.

### Files in wrong locations
Add explicit paths to progress.txt:
```markdown
### File Organization
- Services: src/services/
- Types: src/types/
```

---

## Quick Reference

```bash
# Start workflow
"Create a spec for [feature]"

# Run Ralph
/ralph-loop "..." --max-iterations 50 --completion-promise "ALL_STORIES_COMPLETE"

# Check progress
cat ralph-specs/prd.json | jq '.userStories[] | {id, title, passes}'

# Stop
/cancel-ralph
```
