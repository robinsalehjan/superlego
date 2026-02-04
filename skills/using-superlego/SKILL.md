---
name: using-superlego
description: Introduction to the superlego skills system. Use when starting a session to understand available skills for Swift, SwiftUI, and iOS/macOS development.
---

# Using Superlego

## Overview

Superlego provides skills for Swift, SwiftUI, and iOS/macOS development. Each skill contains workflows, patterns, and reference documentation to guide your work.

## Available Skills

### Swift & SwiftUI Development

| Skill | Use When |
|-------|----------|
| `superlego:swiftui-ui-patterns` | Building SwiftUI views, tab architecture, navigation, sheets, lists, forms |
| `superlego:swiftui-performance-audit` | Profiling SwiftUI performance, optimizing view identity, lazy loading |
| `superlego:swiftui-view-refactor` | Refactoring views with MV patterns, improving state management |
| `superlego:swiftui-liquid-glass` | Implementing WWDC25 Liquid Glass design patterns |
| `superlego:swift-concurrency-expert` | Fixing Swift 6.2+ concurrency errors, actor isolation, Sendable safety |

### Development Workflows

| Skill | Use When |
|-------|----------|
| `superlego:devdocs` | Multi-session tasks, context approaching limits, resuming previous work |
| `superlego:gh-issue-fix-flow` | Implementing GitHub issue fixes end-to-end |
| `superlego:ios-debugger-agent` | Debugging iOS crashes, memory issues, performance problems |
| `superlego:macos-spm-app-packaging` | Packaging macOS apps, notarization, code signing, DMG creation |
| `superlego:app-store-changelog` | Generating App Store release notes from git history |

## How to Use Skills

### 1. Check for Relevant Skills

Before starting any task, review if a skill applies:
- Building SwiftUI UI? → `swiftui-ui-patterns`
- Concurrency compiler errors? → `swift-concurrency-expert`
- Multi-session feature work? → `devdocs`
- GitHub issue fix? → `gh-issue-fix-flow`

### 2. Load the Skill

Use the Skill tool to load the full skill content:

```
Load the superlego:swiftui-ui-patterns skill
```

### 3. Follow the Workflow

Each skill provides a structured workflow. Follow it step-by-step.

### 4. Use Reference Documents

Skills include `references/` directories with detailed patterns. Read them as needed:

```
Read the references in the swiftui-ui-patterns skill directory
```

## Skill Structure

Each skill contains:

```
skills/<skill-name>/
├── SKILL.md           # Main workflow and guidance
├── references/        # Detailed patterns and examples
│   ├── pattern1.md
│   └── pattern2.md
└── scripts/           # (Optional) Automation scripts
```

## Critical Rules

1. **If a skill applies, use it** - Don't skip relevant skills
2. **Read the full SKILL.md** - Workflows are designed to be followed
3. **Reference docs are detailed** - They contain the actual patterns and code examples
4. **Follow modern conventions** - Swift 6.2+, iOS 18+, latest SwiftUI APIs

## Integration with Superpowers

Superlego integrates with the [superpowers](https://github.com/obra/superpowers) plugin:

- The `devdocs` skill creates progress tracking alongside superpowers plans
- Workflows complement superpowers' brainstorming and plan execution
- Both can be installed together

## Skill Locations

Skills are located at:
```
~/.claude/plugins/superlego/skills/
```

Or browse the skill directory directly using file tools.
