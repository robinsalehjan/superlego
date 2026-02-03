# Archive Index

> **Searchable index of completed tasks.** Update this when archiving a task.
>
> Use this to find: "Have we done something like this before?"

## How to Use

1. **Search by tags** to find related past work
2. **Check gotchas** before starting similar tasks
3. **Reference files changed** when modifying the same areas
4. **Check linked issues** for discussion context

## Search Tips

**Finding Related Work:**
- Use Cmd+F (Mac) or Ctrl+F (Windows) to search this file
- Search by **file path** to find tasks that touched the same code
- Search by **tag** to find similar work (e.g., `migration`, `authentication`)
- Search by **gotcha keywords** to find known issues (e.g., `timestamp`, `null`, `race condition`)
- Look for **tag combinations** when planning complex work (e.g., `schema` + `backward-compat`)

**Common Search Patterns:**
- "Before adding a migration" → Search: `migration`, `schema`, `backward-compat`
- "Before refactoring Manager classes" → Search: `manager`, `di`, `refactor`
- "Before writing async code" → Search: `async`, `threading`, `race condition`
- "Before adding UI animations" → Search: `animation`, `performance`
- "Before touching test infrastructure" → Search: `mocks`, `unit-tests`, `integration-tests`

---

## Completed Tasks

| Task | Issue | Completed | Tags | Summary | Key Gotchas |
|------|-------|-----------|------|---------|-------------|
| [example-feature-v2-migration](example-feature-v2-migration.md) | — | YYYY-MM | `schema`, `migration`, `backward-compat`, `json` | JSON schema V1→V2 migration with backward compatibility | Timestamps changed from strings to ISO8601; null handling differs between versions |

<!--
═══════════════════════════════════════════════════════════════════════════════
ADD NEW ENTRIES BELOW THIS LINE (most recent first)
═══════════════════════════════════════════════════════════════════════════════

Template:
| [task-name](task-name.md) | [#123](https://github.com/owner/repo/issues/123) | YYYY-MM | `tag1`, `tag2`, `tag3` | Brief summary (what was accomplished) | Key gotcha (what to watch out for) |

Example entries showing tag patterns:

MIGRATION/REFACTORING:
| [auth-manager-di-refactor](auth-manager-di-refactor.md) | [#456](https://github.com/owner/repo/issues/456) | 2024-02 | `refactor`, `di`, `manager`, `authentication` | Refactored AuthManager to use dependency injection | Must register all dependencies before AuthManager initialization; circular dependency with TokenManager required protocol extraction |

FEATURE IMPLEMENTATION:
| [background-sync-implementation](background-sync-implementation.md) | [#789](https://github.com/owner/repo/issues/789) | 2024-03 | `feature`, `sync`, `background`, `ios` | Added background sync for offline data | iOS background task time limits require batch size tuning; must handle app termination mid-sync |

BUG FIX:
| [race-condition-user-state](race-condition-user-state.md) | [#234](https://github.com/owner/repo/issues/234) | 2024-01 | `bugfix`, `threading`, `race-condition`, `async` | Fixed race condition in user state updates | Actor isolation required for UserState; @MainActor needed for UI updates |

TEST INFRASTRUCTURE:
| [mock-framework-upgrade](mock-framework-upgrade.md) | — | 2024-02 | `testing`, `mocks`, `unit-tests`, `refactor` | Upgraded to new mock framework with better async support | All existing mocks needed async throws variants; test execution order affects shared state |

UI/ANIMATION:
| [onboarding-animations](onboarding-animations.md) | [#567](https://github.com/owner/repo/issues/567) | 2024-03 | `feature`, `ui`, `animation`, `swiftui`, `accessibility` | Added animated onboarding flow with accessibility support | Reduced motion setting must disable animations; timing values different on slower devices |

-->

---

## Tag Reference

Common tags for categorization. Use 3-5 tags per task: task type + domain + specific technologies.

### Tag Categories

| Category | Tags | When to Use |
|----------|------|-------------|
| **Task Type** | `feature`, `bugfix`, `refactor`, `migration`, `cleanup`, `performance` | Always include one task type |
| **Data** | `schema`, `migration`, `json`, `database`, `api`, `cache`, `persistence` | Data model or storage changes |
| **Architecture** | `di`, `manager`, `viewmodel`, `service`, `protocol`, `pattern` | Structural code changes |
| **Domain** | `authentication`, `sync`, `onboarding`, `payments`, `analytics`, `notifications` | Business domain/feature area |
| **Platform** | `ios`, `android`, `web`, `macos`, `desktop`, `backend` | Target platform |
| **Concurrency** | `async`, `threading`, `race-condition`, `actor`, `background` | Async/concurrent code |
| **Testing** | `unit-tests`, `integration-tests`, `e2e`, `mocks`, `test-infra` | Testing infrastructure |
| **UI** | `swiftui`, `uikit`, `react`, `vue`, `design-system`, `accessibility`, `animation` | User interface work |
| **Quality** | `backward-compat`, `breaking-change`, `deprecation`, `security`, `performance` | Quality attributes |

### Effective Tagging Patterns

**Good Tagging Examples:**
- `migration`, `schema`, `backward-compat`, `json` → Schema migration with compatibility
- `feature`, `authentication`, `ios`, `async` → New auth feature using async Swift
- `bugfix`, `race-condition`, `threading`, `manager` → Concurrency bug fix
- `refactor`, `di`, `viewmodel`, `swiftui` → Dependency injection refactoring

**Avoid:**
- Too few tags: `feature` (not searchable)
- Too many tags: `feature`, `ios`, `swiftui`, `json`, `api`, `async`, `di`, `manager` (noisy)
- Redundant tags: `swiftui`, `ui`, `ios` (SwiftUI implies iOS and UI)

### Tag Combinations for Common Scenarios

| Scenario | Recommended Tags |
|----------|-----------------|
| Adding new API endpoint | `feature`, `api`, `backend`, `[domain]` |
| Refactoring for testability | `refactor`, `di`, `unit-tests`, `[component-type]` |
| Performance optimization | `performance`, `[component]`, `[platform]` |
| Breaking API change | `breaking-change`, `api`, `migration`, `deprecation` |
| Async/await migration | `migration`, `async`, `threading`, `[platform]` |
| UI accessibility improvements | `ui`, `accessibility`, `[framework]`, `[platform]` |
