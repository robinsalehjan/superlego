# DevDocs Testing Guide

This document describes manual test scenarios for the DevDocs skill, including Beads integration testing.

## Prerequisites

**Required:**
- Git repository initialized
- GitHub CLI (`gh`) installed and authenticated
- Bash shell (for running scripts)

**Optional (for full integration testing):**
- Beads task tracker installed (`npm install -g @beads/cli` or equivalent)
- Superpowers plugin installed
- `jq` installed for JSON processing
- Test GitHub repository with issues enabled

## Test Scenarios

### Scenario 1: Basic DevDocs Creation (Standalone Mode)

**Purpose:** Verify DevDocs works without superpowers or Beads

**Prerequisites:**
- No `docs/plans/` directory in project
- No Beads installation

**Steps:**
1. Create a test directory structure:
   ```bash
   mkdir -p .github/devdocs/templates
   cp skills/devdocs/templates/* .github/devdocs/templates/
   ```

2. Manually create a devdocs task:
   ```bash
   mkdir -p .github/devdocs/test-feature
   cp .github/devdocs/templates/plan.template.md .github/devdocs/test-feature/plan.md
   cp .github/devdocs/templates/progress.template.md .github/devdocs/test-feature/progress.md
   ```

3. Edit `plan.md` with test content
4. Edit `progress.md` and mark some tasks complete

**Expected Behavior:**
- ✅ Files created in `.github/devdocs/test-feature/`
- ✅ Both `plan.md` and `progress.md` exist
- ✅ Templates properly filled in
- ✅ No errors or warnings

**Verification:**
```bash
ls -la .github/devdocs/test-feature/
cat .github/devdocs/test-feature/plan.md
cat .github/devdocs/test-feature/progress.md
```

---

### Scenario 2: DevDocs with Superpowers Integration

**Purpose:** Verify DevDocs detects and integrates with superpowers specs

**Prerequisites:**
- Superpowers plugin available
- `docs/plans/` directory exists

**Steps:**
1. Create superpowers specs (or manually create test specs):
   ```bash
   mkdir -p docs/plans
   cat > docs/plans/2026-02-04-test-feature.md <<'EOF'
   # Test Feature Implementation Plan

   ## Overview
   Test feature for DevDocs integration

   ## Phases
   - Phase 1: Setup
   - Phase 2: Implementation
   - Phase 3: Testing
   EOF
   ```

2. Create DevDocs progress tracking:
   ```bash
   mkdir -p docs/plans/test-feature
   # Use progress.template.md and reference the superpowers spec
   ```

3. Verify progress.md references the superpowers spec

**Expected Behavior:**
- ✅ Progress file created in `docs/plans/test-feature/`
- ✅ **No** `plan.md` created (superpowers spec is the plan)
- ✅ Progress.md contains link to superpowers spec
- ✅ Header shows superpowers integration fields

**Verification:**
```bash
ls -la docs/plans/test-feature/
# Should only show progress.md, not plan.md
grep "Superpowers Plan:" docs/plans/test-feature/progress.md
```

---

### Scenario 3: GitHub Issue Integration

**Purpose:** Verify devdocs-create.sh script integration with GitHub

**Prerequisites:**
- GitHub CLI authenticated (`gh auth status`)
- Test repository with issues enabled
- Scripts copied to `./scripts/`

**Steps:**
1. Create a test GitHub issue:
   ```bash
   gh issue create --title "Test DevDocs Integration" --body "Test issue for devdocs" --label "test"
   # Note the issue number (e.g., #42)
   ```

2. Run devdocs-create script:
   ```bash
   ./scripts/devdocs-create.sh 42
   ```

3. Check created files and GitHub issue

**Expected Behavior:**
- ✅ DevDocs directory created with issue number in name
- ✅ Plan.md pre-filled with issue body
- ✅ Progress.md contains issue link
- ✅ GitHub issue has comment linking back to devdocs
- ✅ Script detects superpowers vs standalone mode correctly

**Verification:**
```bash
# Check local files
ls -la .github/devdocs/issue-42-* || ls -la docs/plans/issue-42-*
cat .github/devdocs/issue-42-*/plan.md || cat docs/plans/issue-42-*/progress.md

# Check GitHub
gh issue view 42 --comments
```

---

### Scenario 4: Beads Integration - Task Start

**Purpose:** Verify Beads task tracking initialization

**Prerequisites:**
- Beads installed and configured
- GitHub issue created (e.g., #42)
- DevDocs created for the issue

**Steps:**
1. Initialize Beads tracking:
   ```bash
   beads task start 42
   ```

2. Check Beads state file:
   ```bash
   cat .beads/tasks/42.json
   ```

3. Verify GitHub issue updated:
   ```bash
   gh issue view 42
   ```

**Expected Behavior:**
- ✅ `.beads/tasks/42.json` created
- ✅ Task status set to `in_progress`
- ✅ GitHub issue labeled with `in-progress` or similar
- ✅ GitHub issue has comment about task start
- ✅ Task linked to devdocs directory

**Verification:**
```bash
# Check Beads state
cat .beads/tasks/42.json | jq '.status'
# Should output: "in_progress"

# Check GitHub
gh issue view 42 --json labels,comments
```

---

### Scenario 5: Beads Integration - Parallel Work Detection

**Purpose:** Verify Beads detects when multiple people work on same files

**Prerequisites:**
- Beads installed
- Multiple team members with Beads configured
- Shared repository

**Steps:**
1. User A starts task on feature.py:
   ```bash
   beads task start 42
   # Modify src/feature.py
   ```

2. User B starts different task on same file:
   ```bash
   beads task start 43
   beads check
   ```

3. Check warning output

**Expected Behavior:**
- ✅ `beads check` detects User A working on feature.py
- ✅ Warning message displayed:
   ```
   Warning: @userA is working on src/feature.py (issue #42)
   Your task #43 also modifies this file
   Consider coordinating before proceeding
   ```
- ✅ User B can proceed but is informed
- ✅ No blocking error (just warning)

**Verification:**
```bash
beads check --verbose
# Should show file-level conflict warnings
```

---

### Scenario 6: Beads Integration - Progress Sync

**Purpose:** Verify progress updates sync to GitHub

**Prerequisites:**
- Beads task started
- DevDocs progress.md being updated

**Steps:**
1. Update progress.md with completed phase:
   ```markdown
   ## Phase 1: Setup
   - [x] Create data models
   - [x] Add unit tests
   - [ ] Integration tests ← Currently here
   ```

2. Sync to Beads and GitHub:
   ```bash
   beads task update
   ```

3. Check GitHub issue

**Expected Behavior:**
- ✅ Beads reads progress.md current phase
- ✅ GitHub issue comment added with progress update
- ✅ `.beads/tasks/<issue>.json` updated with timestamp
- ✅ Issue labels updated if phase changed

**Verification:**
```bash
# Check Beads state
cat .beads/tasks/42.json | jq '.lastUpdate'

# Check GitHub
gh issue view 42 --comments | tail -n 10
```

---

### Scenario 7: Beads Integration - Task Completion

**Purpose:** Verify task completion workflow

**Prerequisites:**
- Beads task in progress
- Work completed and ready for review

**Steps:**
1. Complete all tasks in progress.md
2. Run completion:
   ```bash
   beads task complete
   ```

3. Check GitHub and Beads state

**Expected Behavior:**
- ✅ Beads status set to `done`
- ✅ GitHub issue comment added: "Task completed"
- ✅ Issue labeled with `review` or `done`
- ✅ Optionally triggers PR creation
- ✅ `.beads/tasks/<issue>.json` archived or marked complete

**Verification:**
```bash
# Check Beads
cat .beads/tasks/42.json | jq '.status'
# Should output: "done"

# Check GitHub
gh issue view 42 --json labels
gh pr list --search "Closes #42"
```

---

### Scenario 8: Archive Workflow

**Purpose:** Verify archiving completed devdocs

**Prerequisites:**
- Completed DevDocs task
- Scripts available in `./scripts/`

**Steps:**
1. Run archive script:
   ```bash
   ./scripts/archive-devdocs.sh test-feature
   ```

2. Follow prompts for tags and gotchas

3. Check archive directory

**Expected Behavior:**
- ✅ Archive summary created in `docs/plans/archive/` or `.github/devdocs/archive/`
- ✅ INDEX.md updated with new entry
- ✅ Working directory optionally deleted
- ✅ Superpowers specs preserved (not deleted)
- ✅ Archive includes key learnings and gotchas

**Verification:**
```bash
# Check archive created
cat docs/plans/archive/test-feature.md || cat .github/devdocs/archive/test-feature.md

# Check INDEX updated
grep "test-feature" docs/plans/archive/INDEX.md || grep "test-feature" .github/devdocs/archive/INDEX.md

# Verify superpowers specs still exist
ls docs/plans/2026-*.md
```

---

### Scenario 9: Full Integration Test (End-to-End)

**Purpose:** Verify complete workflow from planning to archive

**Prerequisites:**
- All tools installed (gh, beads, superpowers, jq)
- Test repository ready

**Steps:**
1. **Planning:**
   ```bash
   # Create GitHub issue
   gh issue create --title "E2E Test Feature" --body "Complete workflow test" --label "test"
   # Note issue number: 100

   # Create superpowers spec (optional)
   # superpowers:writing-plans
   ```

2. **Setup:**
   ```bash
   # Create devdocs
   ./scripts/devdocs-create.sh 100

   # Start Beads tracking
   beads task start 100
   ```

3. **Work:**
   ```bash
   # Update progress.md with work
   # Make code changes
   # Check for parallel work
   beads check

   # Sync progress
   beads task update
   ```

4. **Complete:**
   ```bash
   # Mark complete
   beads task complete

   # Archive
   ./scripts/archive-devdocs.sh issue-100-e2e-test
   ```

**Expected Behavior:**
- ✅ All steps complete without errors
- ✅ GitHub issue has full history of comments
- ✅ DevDocs properly archived
- ✅ Beads state properly managed
- ✅ All integrations work together

**Verification:**
```bash
# Full verification
gh issue view 100 --comments
cat .beads/tasks/100.json
cat docs/plans/archive/issue-100-e2e-test.md || cat .github/devdocs/archive/issue-100-e2e-test.md
```

---

## Common Issues and Troubleshooting

### Issue: Beads not detecting superpowers

**Symptom:** Beads creates plan.md when superpowers spec exists

**Fix:**
```bash
# Ensure superpowers specs follow naming convention
ls docs/plans/YYYY-MM-DD-*.md

# Script should auto-detect based on directory structure
```

### Issue: GitHub CLI not authenticated

**Symptom:** `gh` commands fail with authentication error

**Fix:**
```bash
gh auth login
gh auth status
```

### Issue: Beads parallel work not detected

**Symptom:** No warning when multiple users edit same file

**Fix:**
```bash
# Ensure Beads syncing is configured
beads config --sync-interval 60

# Manually sync before checking
beads sync
beads check
```

### Issue: Archive script fails to find devdocs

**Symptom:** "Directory not found" error

**Fix:**
```bash
# Script expects full directory name
./scripts/archive-devdocs.sh issue-42-feature-name
# NOT: ./scripts/archive-devdocs.sh 42
```

## Test Checklist

Use this checklist to verify all integration points:

- [ ] Standalone mode (no superpowers, no Beads)
- [ ] Superpowers integration (plan detection)
- [ ] GitHub issue integration (devdocs-create.sh)
- [ ] Beads task start
- [ ] Beads parallel work detection
- [ ] Beads progress sync
- [ ] Beads task completion
- [ ] Archive workflow
- [ ] Full end-to-end workflow
- [ ] .beads/ in .gitignore (not committed)
- [ ] Scripts execute without errors
- [ ] Templates properly structured

## Performance Testing

### Script Performance

Test script execution time for creating devdocs:

```bash
time ./scripts/devdocs-create.sh 42
# Should complete in < 5 seconds with GitHub API calls
```

### Beads Sync Performance

Test Beads sync speed:

```bash
time beads task update
# Should complete in < 3 seconds
```

## Security Testing

### Verify .beads/ Not Committed

```bash
# Create test task with Beads
beads task start 42

# Check git status
git status | grep ".beads"
# Should show nothing (ignored)

# Verify .gitignore
grep ".beads" .gitignore
# Should show: .beads/
```

### Verify No Sensitive Data in Archives

```bash
# Check archive doesn't include secrets
cat docs/plans/archive/*.md | grep -i "password\|token\|secret\|api_key"
# Should return nothing
```

## Automation Testing

For CI/CD pipelines, create automated tests:

```bash
#!/bin/bash
# test-devdocs.sh - Automated test suite

# Test 1: Standalone mode
mkdir -p test-standalone
cd test-standalone
# ... test steps ...

# Test 2: Superpowers mode
mkdir -p test-superpowers
cd test-superpowers
# ... test steps ...

# Cleanup
rm -rf test-standalone test-superpowers
```

## Reporting Issues

When reporting issues, include:

1. Tool versions:
   ```bash
   gh --version
   beads --version
   git --version
   jq --version
   ```

2. Environment:
   - OS and version
   - Shell (bash/zsh)
   - Repository type (public/private)

3. Reproduction steps with full command output

4. Expected vs actual behavior

5. Relevant configuration files (.beads/config.json, .github/devdocs/ structure)
