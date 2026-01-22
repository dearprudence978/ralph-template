# Spec Template

Use this template when generating technical specifications.

---

## Template

```markdown
# [SPEC_ID]: [Feature Name] Specification

**Version**: 1.0  
**Created**: [DATE]  
**Author**: Claude (via spec-to-prd skill)  
**Status**: Draft

---

## 1. Executive Summary

[2-3 sentence summary of what this feature does and why it matters]

---

## 2. Problem Statement

### Current State
[What exists today and why it's insufficient]

### Pain Points
- [Pain point 1]
- [Pain point 2]
- [Pain point 3]

### Impact
[Business/user impact of not solving this problem]

---

## 3. Goals & Non-Goals

### Goals
- [Goal 1 - specific and measurable]
- [Goal 2]
- [Goal 3]

### Non-Goals (Out of Scope)
- [Non-goal 1 - explicitly excluded]
- [Non-goal 2]

---

## 4. User Stories

### Primary User: [Persona Name]

**US-001**: As a [user type], I want to [action] so that [benefit].

**Acceptance Criteria**:
- [ ] [Testable criterion 1]
- [ ] [Testable criterion 2]
- [ ] [Testable criterion 3]

**US-002**: [Next user story...]

---

## 5. Technical Design

### Architecture Overview

[High-level description of how components interact]

### Component Diagram

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Client     │────▶│   API        │────▶│   Database   │
└──────────────┘     └──────────────┘     └──────────────┘
```

### Key Components

| Component | Responsibility | Location |
|-----------|---------------|----------|
| [Name] | [What it does] | [File path] |

---

## 6. API Design

### Endpoints

#### POST /api/v1/[resource]

**Description**: [What this endpoint does]

**Request**:
```json
{
  "field1": "string",
  "field2": "number"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "field1": "string"
  }
}
```

**Errors**:
| Code | Description |
|------|-------------|
| 400 | Invalid request body |
| 401 | Unauthorized |
| 409 | Resource already exists |

---

## 7. Data Model

### New Entities

#### [EntityName]

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | PK | Primary identifier |
| created_at | DateTime | NOT NULL | Creation timestamp |

### Database Migrations

- Create [table_name] table
- Add [column] to [existing_table]
- Create index on [field]

---

## 8. Security Considerations

### Authentication
[How users will be authenticated]

### Authorization
[What permissions are required]

### Data Protection
[How sensitive data is protected]

---

## 9. Error Handling

### Error Categories

| Category | HTTP Code | User Message |
|----------|-----------|--------------|
| Validation | 400 | "Invalid input: [details]" |
| Auth | 401 | "Please log in to continue" |
| Permission | 403 | "You don't have permission" |
| Not Found | 404 | "[Resource] not found" |
| Conflict | 409 | "[Resource] already exists" |
| Server | 500 | "Something went wrong" |

---

## 10. Testing Strategy

### Unit Tests
- [Component/function to test]
- [Expected coverage %]

### Integration Tests
- [API endpoint tests]
- [Database integration tests]

### E2E Tests
- [Critical user flows to test]

---

## 11. Performance Requirements

| Metric | Target | Measurement |
|--------|--------|-------------|
| API Response Time | < 200ms p95 | [Tool] |
| Database Queries | < 50ms | Query logging |
| Throughput | 100 req/s | Load test |

---

## 12. Rollout Plan

### Phase 1: Internal Testing
- [ ] Deploy to staging
- [ ] QA testing
- [ ] Fix blocking issues

### Phase 2: Beta
- [ ] Enable for beta users
- [ ] Monitor metrics
- [ ] Gather feedback

### Phase 3: GA
- [ ] Enable for all users
- [ ] Update documentation
- [ ] Announce feature

---

## 13. Success Metrics

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| [Metric 1] | [Baseline] | [Goal] | [How measured] |
| [Metric 2] | [Baseline] | [Goal] | [How measured] |

---

## 14. Open Questions

- [ ] [Question 1 that needs resolution]
- [ ] [Question 2]

---

## Appendix

### A. Glossary

| Term | Definition |
|------|------------|
| [Term] | [Definition] |

### B. References

- [Link to related docs]
- [Link to design mockups]
```

---

## Usage Notes

1. **SPEC_ID**: Use short identifiers like AUTH, NOTIF, PAY, DASH
2. **Be Specific**: Acceptance criteria must be testable
3. **Include Examples**: Show actual request/response shapes
4. **Think About Errors**: Document all error cases upfront
5. **Define Success**: Make metrics measurable
