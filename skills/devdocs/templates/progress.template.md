# [Task Name] - Progress

> This file tracks session-to-session progress. Update before ending each session.

<!-- If using with superpowers plugin, uncomment the next line and link to the spec -->
<!-- **Superpowers Spec:** [YYYY-MM-DD-feature-name.md](../YYYY-MM-DD-feature-name.md) -->

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

- [ ] **Close GitHub Issue** (if applicable)
  - [ ] Ensure final PR includes `Closes #<number>` in description
  - [ ] Or close manually: `gh issue close <number> --comment "Completed in PR #..."`
- [ ] **Update Feature Documentation** in `{{DOCS_PATH}}/features/`
  - [ ] Update `Implementation_Status.md` with completed work
  - [ ] Add implementation history link (see below)
  - [ ] Mark phases complete in `Implementation_Plan.md`
- [ ] **Feed back debugging discoveries** to `.github/devdocs/DEBUGGING.md`
  - [ ] Add any new error patterns and solutions
  - [ ] Document gotchas that future sessions should know
- [ ] **Update archive index** in `.github/devdocs/archive/INDEX.md`
- [ ] **Create archive summary** at `.github/devdocs/archive/<task-name>.md`
- [ ] **Delete working files** after archiving (no 30-day wait needed if archived properly)
- [ ] **Add implementation history** to feature docs:
  ```markdown
  ## Implementation History
  - [Task Name](/.github/devdocs/archive/<task-name>.md) - Brief description
  ```
