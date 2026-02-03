# [Task Name] - Progress

> This file tracks session-to-session progress. Update before ending each session.

<!-- ═══════════════════════════════════════════════════════════════
     WITH SUPERPOWERS: Uncomment and link to superpowers specs
     ═══════════════════════════════════════════════════════════════ -->
<!-- **Superpowers Design:** [YYYY-MM-DD-feature-design.md](../YYYY-MM-DD-feature-design.md) -->
<!-- **Superpowers Plan:** [YYYY-MM-DD-feature.md](../YYYY-MM-DD-feature.md) -->

<!-- ═══════════════════════════════════════════════════════════════
     STANDALONE (No Superpowers): Use this format
     ═══════════════════════════════════════════════════════════════ -->
**Plan:** [plan.md](plan.md)

**GitHub Issue:** #[number] or N/A
**Last Updated:** [YYYY-MM-DD]
**Current Phase:** [Phase X - Name]
**Overall Status:** 🟡 In Progress

---

## Session Handoff (TL;DR)

> **For instant context resumption.** Update this section at the end of each session.

| Field | Value |
|-------|-------|
| **Next Action** | [Specific next step, e.g., "Implement batch upload in `SomeManager:L45`"] |
| **Context Needed** | [Files to read, e.g., "Read `SomeData` file for batch size constants"] |
| **Blocker** | None / [Description of blocker] |
| **Failed Approaches** | None / [What was tried and didn't work] |
| **Current Superpowers Skill** | [test-driven-development / systematic-debugging / none] |

---

## Superpowers Workflow Tracking

> **Only include this section if using superpowers plugin**

**Completed:**
- [x] brainstorming (design spec created)
- [x] writing-plans (implementation plan created)

**In Progress:**
- [ ] test-driven-development (TDD cycles tracked below)
- [ ] systematic-debugging (debugging log below if needed)

**Next:**
- [ ] verification-before-completion
- [ ] requesting-code-review
- [ ] finishing-a-development-branch

---

## Quick Status

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 1 | ✅ Complete | [brief note] |
| Phase 2 | 🟡 In Progress | [brief note] |
| Phase 3 | ⬜ Not Started | — |

---

## Phase 1: [Phase Name] ✅

- [x] Completed item 1
- [x] Completed item 2
- [x] Completed item 3

**Session Notes:**
- [Any learnings or decisions from this phase]

---

## Phase 2: [Phase Name] 🟡

- [x] Completed item
- [ ] **Current →** In-progress item
- [ ] Upcoming item

**Session Notes:**
- [What was accomplished this session]
- [What's next]

---

## Phase 3: [Phase Name] ⬜

- [ ] Item 1
- [ ] Item 2

---

## TDD Cycle Tracking

> **Only include if using superpowers:test-driven-development**
> Track RED-GREEN-REFACTOR cycles for accountability and progress visibility

| Cycle | Feature/Test | RED | GREEN | REFACTOR | Notes |
|-------|--------------|-----|-------|----------|-------|
| 1 | [Feature/test name] | ✅ | ✅ | ✅ | [What was learned] |
| 2 | [Feature/test name] | ✅ | 🟡 | ⬜ | Currently here - [status] |
| 3 | [Feature/test name] | ⬜ | ⬜ | ⬜ | Planned |

**TDD Notes:**
- [Any observations about the TDD process]
- [Adjustments made to approach]

---

## Debugging Log

> **Only include if using superpowers:systematic-debugging**
> Log root cause analysis from debugging sessions

**Session [N] - [Date]**

| Phase | Status | Findings |
|-------|--------|----------|
| 1. Reproduce | ✅ | [Steps to reproduce] |
| 2. Isolate | ✅ | [Where the bug occurs] |
| 3. Root Cause | ✅ | [Why it happens] |
| 4. Verify Fix | 🟡 | [How fix was tested] |

**Root Cause:** [Clear description from systematic-debugging analysis]

**Fix Applied:** [What was changed]

**Verification:** [How confirmed the fix works]

**Added to Failed Approaches:** [Yes/No - if this approach failed, log below]

---

## Blockers

- [ ] [Blocker description - who/what is needed to unblock]

## Decisions Made

| Decision | Rationale | Date |
|----------|-----------|------|
| [Decision 1] | [Why] | [Date] |
| [Decision 2] | [Why] | [Date] |

## Files Changed

Key files touched during this task:
- `path/to/file1` - [what was changed]
- `path/to/file2` - [what was changed]

## Next Session

**To resume this task, tell the agent:**
```
Continue work on [task-name]. Read .github/devdocs/[task-name]/progress.md for current state. Begin [specific next step].
```

**Priority for next session:**
1. [Most important next step]
2. [Second priority]
3. [Third priority]

## Session Log

| Date | Work Done | Notes |
|------|-----------|-------|
| [Date] | [Brief summary] | [Any issues] |
| [Date] | [Brief summary] | [Any issues] |

---

## Completion Checklist

> **Use this checklist when the task is complete.** Do not delete working files until all items are checked.

### With Superpowers Plugin

- [ ] **Run verification** (superpowers:verification-before-completion)
  - [ ] All tests pass
  - [ ] Build succeeds with no errors
  - [ ] No linter warnings
  - [ ] Manual testing checklist complete

- [ ] **Request code review** (superpowers:requesting-code-review)
  - [ ] Create review request
  - [ ] Address all feedback
  - [ ] Re-verify after changes

- [ ] **Finish development branch** (superpowers:finishing-a-development-branch)
  - [ ] Decide: Merge / Create PR / Clean up
  - [ ] Follow guided workflow

- [ ] **Archive devdocs**
  - [ ] Run: `./scripts/archive-devdocs.sh <feature-name>`
  - [ ] Verify archive created in `docs/plans/archive/<feature-name>.md`
  - [ ] Verify entry added to `docs/plans/archive/INDEX.md`
  - [ ] Superpowers specs remain in `docs/plans/` (do not delete!)
  - [ ] Progress directory `docs/plans/<feature-name>/` deleted

- [ ] **Close GitHub Issue** (if applicable)
  - [ ] Ensure final PR includes `Closes #<number>` in description
  - [ ] Or close manually: `gh issue close <number> --comment "Completed - see archive"`

- [ ] **Update Feature Documentation** (if applicable)
  - [ ] Update feature status documents
  - [ ] Add implementation history link:
    ```markdown
    ## Implementation History
    - [Feature Name](/docs/plans/archive/<feature-name>.md) - Brief description
    ```

- [ ] **Feed back discoveries** to `skills/devdocs/DEBUGGING.md`
  - [ ] Add any new debugging patterns
  - [ ] Document gotchas for future work

### Without Superpowers (Standalone)

- [ ] **Verify completion**
  - [ ] All tests pass
  - [ ] Build succeeds
  - [ ] Code reviewed

- [ ] **Archive devdocs**
  - [ ] Run: `./scripts/archive-devdocs.sh <task-name>`
  - [ ] Archive created in `.github/devdocs/archive/<task-name>.md`
  - [ ] Entry added to `.github/devdocs/archive/INDEX.md`

- [ ] **Close GitHub Issue** (if applicable)
  - [ ] Final PR includes `Closes #<number>`

- [ ] **Update documentation** (if applicable)
  - [ ] Feature docs updated
  - [ ] Implementation history added
