# PRD JSON Template

This template shows the structure of `ralph-specs/prd.json`. Ralph reads this file to track implementation progress.

---

## Template Structure

```json
{
  "project": "[Feature Name]",
  "specId": "[SPEC_ID]",
  "branchName": "ralph/[SPEC_ID]-[feature-slug]",
  "description": "[Brief description of what this feature does]",
  "specFile": "specs/[SPEC_ID]-[feature-slug].md",
  "userStories": [
    {
      "id": "[SPEC_ID]-001",
      "title": "[Short descriptive title]",
      "description": "[1-2 sentences about what to implement]",
      "category": "setup",
      "acceptanceCriteria": [
        "[Specific testable criterion 1]",
        "[Specific testable criterion 2]",
        "[Specific testable criterion 3]"
      ],
      "verificationCommands": [
        "npm run typecheck",
        "npm run test -- --grep '[pattern]'"
      ],
      "filesToModify": [
        "src/path/to/file.ts",
        "src/path/to/other.ts"
      ],
      "dependsOn": [],
      "priority": 1,
      "complexity": "simple",
      "passes": false,
      "notes": ""
    },
    {
      "id": "[SPEC_ID]-002",
      "title": "[Next task title]",
      "description": "[Description]",
      "category": "core",
      "acceptanceCriteria": [
        "[Criterion 1]",
        "[Criterion 2]"
      ],
      "verificationCommands": [
        "npm run test -- --grep '[pattern]'"
      ],
      "filesToModify": [
        "src/services/feature.service.ts"
      ],
      "dependsOn": ["[SPEC_ID]-001"],
      "priority": 2,
      "complexity": "medium",
      "passes": false,
      "notes": ""
    }
  ],
  "globalSuccessCriteria": [
    "All tests pass: npm run test",
    "No linter errors: npm run lint",
    "TypeScript compiles: npm run typecheck",
    "Build succeeds: npm run build"
  ],
  "createdAt": "[ISO 8601 timestamp]",
  "updatedAt": "[ISO 8601 timestamp]"
}
```

---

## Field Descriptions

### Root Fields

| Field | Type | Description |
|-------|------|-------------|
| `project` | string | Human-readable feature name |
| `specId` | string | Short identifier (AUTH, NOTIF, etc.) |
| `branchName` | string | Git branch for this feature |
| `description` | string | Brief feature description |
| `specFile` | string | Path to full spec document |
| `userStories` | array | List of implementation tasks |
| `globalSuccessCriteria` | array | Final validation commands |
| `createdAt` | string | ISO timestamp of creation |
| `updatedAt` | string | ISO timestamp of last update |

### User Story Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique ID: `[SPEC_ID]-[NNN]` |
| `title` | string | Short descriptive title |
| `description` | string | What to implement |
| `category` | enum | setup, core, api, ui, test, docs |
| `acceptanceCriteria` | array | Testable success conditions |
| `verificationCommands` | array | Commands to verify completion |
| `filesToModify` | array | Files this story touches |
| `dependsOn` | array | Story IDs that must complete first |
| `priority` | number | Execution order (lower = first) |
| `complexity` | enum | simple, medium, complex |
| `passes` | boolean | **KEY FIELD**: false until complete |
| `notes` | string | Ralph adds implementation notes here |

---

## Category Guidelines

| Category | When to Use | Typical Priority |
|----------|-------------|------------------|
| `setup` | Database schemas, config, base classes | 1-2 |
| `core` | Business logic, services | 3-5 |
| `api` | Endpoints, controllers, routes | 4-6 |
| `ui` | Components, pages, styles | 5-7 |
| `test` | Additional test coverage | 8-9 |
| `docs` | Documentation, README updates | 10 |

---

## Complexity Guidelines

| Complexity | Description | Expected Iterations |
|------------|-------------|-------------------|
| `simple` | Single file, clear implementation | 1 |
| `medium` | 2-3 files, some decisions | 1-2 |
| `complex` | Multiple files, integration | 2-3 |

---

## Dependency Rules

1. Stories with dependencies wait until all dependencies have `passes: true`
2. Use explicit story IDs in `dependsOn` array
3. Avoid circular dependencies
4. Setup stories typically have no dependencies
5. API stories often depend on core stories

Example dependency chain:
```
AUTH-001 (setup)     → no dependencies
AUTH-002 (core)      → depends on AUTH-001
AUTH-003 (api)       → depends on AUTH-002
AUTH-004 (test)      → depends on AUTH-002, AUTH-003
```

---

## Best Practices

1. **Keep stories small**: 1-5 files max per story
2. **Make criteria specific**: "Returns 200 with user object" not "Works correctly"
3. **Include real commands**: Actual runnable verification commands
4. **Order by dependency**: Use priority to suggest execution order
5. **Estimate conservatively**: Mark complex if uncertain
