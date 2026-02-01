# Debugging Guide

This document captures common debugging patterns and solutions discovered during development. It serves as an active reference for both human developers and AI agents.

> **Note:** Customize this file with your project's specific debugging patterns, error messages, and solutions.

## Build Issues

### Linter Failures

**Symptom:** Build fails with linter errors

**Solution:**
```bash
# Check issues
{{LINTER}}

# Auto-fix what can be fixed
{{LINTER}} --fix

# Common issues:
# - Line length violations
# - Trailing whitespace
# - Missing newline at end of file
```

### Module/Package Not Found

**Symptom:** `Module not found` or `Cannot find package` errors

**Causes & Solutions:**
1. **Clean build needed:** Run clean command for your build tool
2. **Package cache:** Delete package cache directory and rebuild
3. **Wrong target:** Ensure building correct scheme/target

### Build Fails but Linter Passes

**Symptom:** CI passes but local build fails (or vice versa)

**Solution:**
```bash
# Reset build cache
{{CLEAN_CMD}}

# Clean and rebuild
{{BUILD_CMD}}
```

---

## Runtime Issues

### Dependency Injection Issues

**Symptom:** Runtime error about missing dependency registration

**Cause:** Service/Manager not registered in DI container

**Solution:**
1. Check DI registration file
2. Add missing registration
3. Ensure registration happens before first use

### Thread/Async Issues

**Symptom:** Race conditions, data corruption, or UI not updating

**Common Patterns:**
- Ensure UI updates happen on main thread
- Use proper synchronization for shared mutable state
- Cancel async operations when views disappear

### API/Backend Authorization Issues

**Symptom:** API requests return 401/403 or permission errors

**Debugging Steps:**
1. Check authentication token validity
2. Verify correct scopes/permissions requested
3. Check API endpoint matches environment (dev/staging/prod)
4. Test with debug tools (Postman, curl, etc.)

---

## Testing Issues

### Tests Not Discovered

**Symptom:** Tests exist but don't run

**Causes:**
1. Missing test framework import
2. Test methods not properly annotated/named
3. Test file not in correct directory

### Mocks Not Being Used

**Symptom:** Tests hitting real services

**Cause:** Forgot to inject mock in test setup

**Solution:**
- Ensure mock is registered BEFORE creating system under test
- Verify DI container is reset between tests

### Async Test Issues

**Symptom:** Tests timeout or have race conditions

**Solution:**
- Ensure proper async/await usage
- Use test helpers for async assertions
- Check mock implementations return immediately

---

## Environment Issues

### Backend Emulator/Local Server Issues

**Starting Local Services:**
```bash
# Start local development server/emulators
# (customize for your project, e.g., docker-compose up, npm run dev:server)
```

**Common Issues:**

| Symptom | Cause | Solution |
|---------|-------|----------|
| "Port already in use" | Previous process still running | Kill process or use different port |
| Config not updating | Cache issues | Restart services |
| Data not persisting | Missing persistence flag | Check startup command flags |
| Auth not working | Wrong environment config | Check config files match local setup |

---

## Common Gotchas

> Add project-specific gotchas here as they're discovered.

### Example Gotcha 1

**Issue:** [Description of the issue]

**Solution:** [How to fix it]

### Example Gotcha 2

**Issue:** [Description of the issue]

**Solution:** [How to fix it]

---

## Performance Debugging

### UI/Rendering Issues

**Symptom:** UI stutters or excessive CPU usage

**Debugging:**
1. Use profiling tools to identify bottlenecks
2. Check for unnecessary re-renders
3. Look for expensive computations in render path

### Memory Issues

**Symptom:** Memory grows over time

**Common Causes:**
1. Reference cycles (closures capturing self)
2. Async operations not cancelled
3. Observers/listeners not removed

---

## Error Recovery Flowchart (For AI Agents)

Use this decision tree when encountering failures:

### Build Failure Recovery

```
Build Failed?
    │
    ├─► Linter error?
    │       └─► Run: {{LINTER}} --fix
    │           └─► Still fails? Fix manually based on error message
    │
    ├─► Missing import/module?
    │       └─► Add missing import or install missing dependency
    │
    ├─► Dependency not found?
    │       └─► Clean build cache and rebuild
    │
    └─► Unknown error?
        └─► Read the FULL error message
            └─► Search codebase for similar patterns
                └─► Still stuck? Document in devdocs and ask for help
```

### Test Failure Recovery

```
Tests Failed?
    │
    ├─► Mock not being used?
    │       └─► Ensure mock is registered BEFORE creating SUT
    │
    ├─► Async test timing out?
    │       └─► Check: Are you awaiting async calls?
    │       └─► Check: Is the mock returning immediately?
    │
    ├─► Assertion failing?
    │       └─► Print actual vs expected values
    │       └─► Check for floating point comparison issues
    │
    └─► Test not running?
        └─► Check test framework import
        └─► Check test annotation/naming
        └─► Check file location
```

### When to Give Up and Persist State

If you've tried 3+ approaches without success:
1. **Stop making changes**
2. **Commit what works** (even partial progress)
3. **Document the blocker** in `.github/devdocs/<task>/progress.md`:
   ```markdown
   ## Blockers
   - [ ] Build fails with: [exact error message]
   - Tried: [approach 1], [approach 2], [approach 3]
   - Suspicion: [your hypothesis]
   - Need: [human help / more context / specific file]
   ```
4. **Ask for human assistance** with specific questions

---

## Adding New Debug Info

When you discover a new debugging pattern or solution:

1. Add it to the appropriate section above
2. Include:
   - **Symptom:** What the developer sees
   - **Cause:** Why it happens
   - **Solution:** How to fix it
3. Add code examples where helpful
4. Keep solutions concise and actionable
