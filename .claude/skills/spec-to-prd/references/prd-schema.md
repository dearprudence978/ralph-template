# PRD JSON Schema Reference

Complete JSON schema specification for `ralph-specs/prd-phase-{N}-{feature-slug}.json`.

---

## JSON Schema Definition

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "PRD",
  "description": "Product Requirements Document for Ralph loop execution",
  "type": "object",
  "required": ["project", "specId", "userStories"],
  "properties": {
    "project": {
      "type": "string",
      "description": "Human-readable feature name"
    },
    "specId": {
      "type": "string",
      "pattern": "^[A-Z]{2,6}$",
      "description": "Short identifier (AUTH, NOTIF, DASH, PAY)"
    },
    "branchName": {
      "type": "string",
      "pattern": "^feature/phase-[0-9]+-[a-z0-9-]+$",
      "description": "Git branch name derived from PRD filename: feature/phase-{N}-{slug}"
    },
    "description": {
      "type": "string",
      "description": "Brief feature description"
    },
    "specFile": {
      "type": "string",
      "description": "Path to full specification document"
    },
    "userStories": {
      "type": "array",
      "items": { "$ref": "#/definitions/UserStory" },
      "minItems": 1
    },
    "globalSuccessCriteria": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Commands to validate entire feature"
    },
    "createdAt": {
      "type": "string",
      "format": "date-time"
    },
    "updatedAt": {
      "type": "string",
      "format": "date-time"
    }
  },
  "definitions": {
    "UserStory": {
      "type": "object",
      "required": ["id", "title", "acceptanceCriteria", "passes"],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^[A-Z]{2,6}-[0-9]{3}$",
          "description": "Unique ID: SPEC_ID-NNN format"
        },
        "title": {
          "type": "string",
          "maxLength": 100,
          "description": "Short descriptive title"
        },
        "description": {
          "type": "string",
          "description": "What needs to be implemented"
        },
        "category": {
          "type": "string",
          "enum": ["setup", "core", "api", "ui", "test", "docs"],
          "description": "Type of task"
        },
        "acceptanceCriteria": {
          "type": "array",
          "items": { "type": "string" },
          "minItems": 1,
          "description": "Testable success conditions"
        },
        "verificationCommands": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Commands to verify completion"
        },
        "filesToModify": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Files this story will create/modify"
        },
        "dependsOn": {
          "type": "array",
          "items": { "type": "string" },
          "description": "IDs of stories that must complete first"
        },
        "priority": {
          "type": "integer",
          "minimum": 1,
          "description": "Execution order (lower = first)"
        },
        "complexity": {
          "type": "string",
          "enum": ["simple", "medium", "complex"],
          "description": "Estimated implementation difficulty"
        },
        "passes": {
          "type": "boolean",
          "description": "KEY TRACKING FIELD: false until complete"
        },
        "notes": {
          "type": "string",
          "description": "Implementation notes added by Ralph"
        }
      }
    }
  }
}
```

---

## Validation Rules

### ID Format
- Pattern: `[SPEC_ID]-[NNN]`
- SPEC_ID: 2-6 uppercase letters
- NNN: Zero-padded 3-digit number
- Examples: `AUTH-001`, `NOTIF-012`, `PAY-100`

### Category Values
| Value | Description |
|-------|-------------|
| `setup` | Infrastructure, schemas, configuration |
| `core` | Business logic, domain services |
| `api` | HTTP endpoints, controllers |
| `ui` | Frontend components, pages |
| `test` | Test files, coverage |
| `docs` | Documentation, README |

### Complexity Values
| Value | Iterations | Files |
|-------|------------|-------|
| `simple` | 1 | 1-2 |
| `medium` | 1-2 | 2-4 |
| `complex` | 2-3 | 3-5+ |

---

## jq Commands for Querying

### View All Stories
```bash
cat ralph-specs/prd-phase-{N}-{name}.json | jq '.userStories[] | {id, title, passes}'
```

### Count Remaining Stories
```bash
cat ralph-specs/prd-phase-{N}-{name}.json | jq '[.userStories[] | select(.passes == false)] | length'
```

### Get Next Story to Work On
```bash
cat ralph-specs/prd-phase-{N}-{name}.json | jq '
  .userStories
  | map(select(.passes == false))
  | sort_by(.priority)
  | .[0]
'
```

### Check Stories Blocked by Dependencies
```bash
cat ralph-specs/prd-phase-{N}-{name}.json | jq '
  .userStories
  | map(select(.passes == false and (.dependsOn | length > 0)))
  | .[] | {id, dependsOn}
'
```

### Get Completed Stories
```bash
cat ralph-specs/prd-phase-{N}-{name}.json | jq '.userStories[] | select(.passes == true) | {id, title}'
```

### View Story Notes
```bash
cat ralph-specs/prd-phase-{N}-{name}.json | jq '.userStories[] | select(.notes != "") | {id, notes}'
```

### Get Stories by Category
```bash
cat ralph-specs/prd-phase-{N}-{name}.json | jq '.userStories[] | select(.category == "api") | {id, title}'
```

### Summary Stats
```bash
cat ralph-specs/prd-phase-{N}-{name}.json | jq '{
  total: (.userStories | length),
  completed: ([.userStories[] | select(.passes == true)] | length),
  remaining: ([.userStories[] | select(.passes == false)] | length)
}'
```

---

## Updating the PRD

### Mark Story Complete (via jq)
```bash
# Mark AUTH-001 as complete
cat ralph-specs/prd-phase-{N}-{name}.json | jq '
  .userStories |= map(
    if .id == "AUTH-001" then .passes = true else . end
  )
' > ralph-specs/prd-phase-{N}-{name}.json.tmp && mv ralph-specs/prd-phase-{N}-{name}.json.tmp ralph-specs/prd-phase-{N}-{name}.json
```

### Add Notes to Story
```bash
cat ralph-specs/prd-phase-{N}-{name}.json | jq '
  .userStories |= map(
    if .id == "AUTH-001" then .notes = "Implemented with bcrypt" else . end
  )
' > ralph-specs/prd-phase-{N}-{name}.json.tmp && mv ralph-specs/prd-phase-{N}-{name}.json.tmp ralph-specs/prd-phase-{N}-{name}.json
```

### Update Timestamp
```bash
cat ralph-specs/prd-phase-{N}-{name}.json | jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
  .updatedAt = $now
' > ralph-specs/prd-phase-{N}-{name}.json.tmp && mv ralph-specs/prd-phase-{N}-{name}.json.tmp ralph-specs/prd-phase-{N}-{name}.json
```

---

## Best Practices

1. **Never manually edit `passes`** - Let Ralph update it via verification
2. **Keep IDs immutable** - Don't rename story IDs mid-implementation
3. **Add notes liberally** - Document decisions and learnings
4. **Update timestamps** - Track when changes occur
5. **Validate JSON** - Use `jq '.' ralph-specs/prd-phase-{N}-{name}.json` to check syntax
