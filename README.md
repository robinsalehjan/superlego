# Superlego

A collection of AI coding assistant skills for Swift, SwiftUI, iOS/macOS development, and development workflows.

## Installation

### Claude Code

Install from GitHub:

```bash
/plugin install robinsalehjan/superlego
```

### Safety Hooks (Optional)

For additional protection against dangerous commands, install the safety-hooks plugin separately:

```bash
/plugin install robinsalehjan/superlego/plugins/safety-hooks
```

### Local Development

For local development or testing:

```bash
/plugin install /path/to/superlego
```

### Verify Installation

Check that skills are available:

```bash
/help
```

Or ask Claude to list available skills.

## Available Skills

### Swift & SwiftUI Development

| Skill | Description |
|-------|-------------|
| **swiftui-ui-patterns** | Best practices and example-driven guidance for building SwiftUI views and components. Tab architecture, navigation, sheets, lists, and more. |
| **swiftui-performance-audit** | Performance analysis and optimization for SwiftUI. Profiling with Instruments, identity optimization, lazy loading patterns. |
| **swiftui-view-refactor** | SwiftUI view refactoring using MV patterns. State management, view composition, dependency injection. |
| **swiftui-liquid-glass** | WWDC25 Liquid Glass design patterns for visionOS and iOS. Glassmorphism, depth effects, spatial UI. |
| **swift-concurrency-expert** | Swift 6.2+ concurrency review and remediation. Actor isolation, Sendable safety, data-race fixes. |

### Development Workflows

| Skill | Description |
|-------|-------------|
| **using-superlego** | Introduction to the superlego skills system. Overview of available skills and how to use them. |
| **devdocs** | Session continuity for AI-assisted development. Persist working state across sessions to prevent context loss. |
| **gh-issue-fix-flow** | End-to-end GitHub issue fix workflow. Issue intake, code changes, builds/tests, commit with closing message, and push. |
| **ios-debugger-agent** | iOS debugging workflow with LLDB and Instruments. Crash investigation, memory debugging, performance profiling. |
| **macos-spm-app-packaging** | macOS app packaging with Swift Package Manager. Notarization, code signing, DMG creation, release workflow. |
| **app-store-changelog** | App Store release notes generation. Parse git history, categorize changes, format for App Store Connect. |

### Safety & Protection

| Skill | Description |
|-------|-------------|
| **safety-hooks** | Pre-tool-use safety hooks. Protect against dangerous bash commands, sensitive file access, and git branch protection. Available as a separate plugin at `plugins/safety-hooks/`. |

## Usage

Skills are automatically available when the plugin is installed. Claude will detect relevant skills based on your task and offer to use them.

### Explicitly Request a Skill

```
Use the swiftui-ui-patterns skill to help me build a tab-based navigation
```

### Browse Skill References

Each skill includes reference documents with detailed patterns and examples:

```
Read the references in the swiftui-ui-patterns skill directory
```

## Skill Structure

Each skill contains:

- **SKILL.md** - Main skill definition with workflow and guidance
- **references/** - Supporting documentation and patterns
- **scripts/** - (Optional) Automation scripts for the skill

## Philosophy

- **Convention over configuration** - Follow Swift/SwiftUI community best practices
- **Modern patterns first** - Swift 6.2+, iOS 18+, latest SwiftUI APIs
- **Example-driven** - Learn from real patterns, not abstract descriptions
- **Session continuity** - Persist state to prevent context loss

## Contributing

1. Fork the repository
2. Create a new skill following the SKILL.md format
3. Add references/ with supporting documentation
4. Submit a PR

### Skill Template

```markdown
---
name: my-skill
description: Brief description. Use when [trigger condition].
---

# My Skill

## Overview

What this skill does.

## Workflow

### 1. First step
...

### 2. Second step
...
```

## Updating

Update installed plugins:

```bash
/plugin update robinsalehjan/superlego
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- **Issues**: https://github.com/robinsalehjan/superlego/issues
