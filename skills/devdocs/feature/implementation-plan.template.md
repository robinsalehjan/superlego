# [Feature Name] - Implementation Plan

> Copy this template to `{{DOCS_PATH}}/features/[FeatureName]/Implementation_Plan.md` during planning.
>
> **Reference:** See [`AGENTS.md`](/.github/AGENTS.md) for coding standards.

## Overview

**Feature:** [Link to feature spec](./FeatureName.md)
**GitHub Issue:** [#number](https://github.com/{{REPO_OWNER}}/{{REPO_NAME}}/issues/number) (if applicable)
**Target Version:** [version or milestone]
**Estimated Effort:** [X days/weeks]

---

## Scope

### ✅ In Scope

- [Specific deliverable 1]
- [Specific deliverable 2]
- [Specific deliverable 3]

### ❌ Out of Scope

- [Explicitly excluded item 1]
- [Explicitly excluded item 2]

### ⚡ Future Considerations

- [Item to consider for v2]
- [Nice-to-have for later]

---

## Architecture

### High-Level Design

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Layer 1   │────▶│   Layer 2   │────▶│   Layer 3   │
└─────────────┘     └─────────────┘     └─────────────┘
```

### Key Components

| Component | Responsibility | New/Modified |
|-----------|----------------|--------------|
| [Component 1] | [What it does] | New |
| [Component 2] | [What it does] | Modified |

### Data Model Changes

[Describe new entities, schema changes, migrations needed]

### API Changes

[Describe new endpoints, breaking changes, deprecations]

---

## Implementation Phases

### Phase 1: [Foundation/Setup] — [X days]

**Goal:** [What this phase accomplishes]

- [ ] [Task 1.1]
- [ ] [Task 1.2]
- [ ] [Task 1.3]

**Deliverables:**
- [What will be done/demonstrable after this phase]

**Testing:**
- [ ] Unit tests for [component]

---

### Phase 2: [Core Implementation] — [X days]

**Goal:** [What this phase accomplishes]

- [ ] [Task 2.1]
- [ ] [Task 2.2]
- [ ] [Task 2.3]

**Deliverables:**
- [What will be done/demonstrable after this phase]

**Testing:**
- [ ] Unit tests for [component]
- [ ] Integration tests for [flow]

---

### Phase 3: [Polish/Integration] — [X days]

**Goal:** [What this phase accomplishes]

- [ ] [Task 3.1]
- [ ] [Task 3.2]
- [ ] [Task 3.3]

**Deliverables:**
- [What will be done/demonstrable after this phase]

**Testing:**
- [ ] End-to-end tests
- [ ] Manual testing checklist

---

## Testing Strategy

### Unit Tests
- [Component/Module 1]: [What to test]
- [Component/Module 2]: [What to test]

### Integration Tests
- [Flow 1]: [What to test]
- [Flow 2]: [What to test]

### Manual Testing Checklist
- [ ] [Manual test case 1]
- [ ] [Manual test case 2]
- [ ] [Edge case 1]
- [ ] [Edge case 2]

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Medium | High | [Mitigation strategy] |
| [Risk 2] | Low | Medium | [Mitigation strategy] |

---

## Dependencies

| Dependency | Owner | Status | Blocker? |
|------------|-------|--------|----------|
| [Dependency 1] | @owner | ✅ Ready | No |
| [Dependency 2] | @owner | 🟡 In Progress | Blocks Phase 2 |

---

## Rollout Plan

### Feature Flags
- `feature_[name]_enabled`: [Description]

### Rollout Stages
1. **Internal testing:** [date/milestone]
2. **Beta users:** [date/milestone]
3. **General availability:** [date/milestone]

### Rollback Plan
[How to disable/rollback if issues are found]

---

## Success Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| [Metric 1] | [Target value] | [Measurement method] |
| [Metric 2] | [Target value] | [Measurement method] |

---

## Notes

[Any additional context, decisions made, or assumptions]
