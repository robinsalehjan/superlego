---
name: ios-debugger-agent
description: Use xcodebuild to build, run, launch, and debug the current iOS project on a booted simulator. Trigger when asked to run an iOS app, interact with the simulator UI, inspect on-screen state, capture logs/console output, or diagnose runtime behavior.
---

# iOS Debugger Agent

## Overview
Use `xcodebuild` to build and run the current project scheme on a booted iOS simulator, interact with the UI, and capture logs. Use `xcrun simctl` for simulator control, logs, and view inspection.

## Core Workflow
Follow this sequence unless the user asks for a narrower action.

### 1) Discover the booted simulator
- Run `xcrun simctl list devices booted` and select a booted simulator.
- If none are booted, ask the user to boot one (do not boot automatically unless asked).

### 2) Identify build parameters
- Determine the following for `xcodebuild`:
  - `-project` or `-workspace` (whichever the repo uses)
  - `-scheme` for the current app
  - `-destination 'id=<simulatorId>'` from the booted device
  - Optional: `-configuration Debug`

### 3) Build + run (when requested)
- Run `xcodebuild -scheme <scheme> -destination 'id=<simulatorId>' build`.
- If the app is already built and only launch is requested, use `xcrun simctl launch <simulatorId> <bundleId>`.
- If bundle id is unknown:
  1) Find the app path in `~/Library/Developer/Xcode/DerivedData`
  2) Run `defaults read <path>/Info.plist CFBundleIdentifier`

## UI Interaction & Debugging
Use these when asked to inspect or interact with the running app.

- **Describe UI**: Use `xcrun simctl ui <simulatorId> describe` or Accessibility Inspector.
- **Tap**: Use `xcrun simctl io <simulatorId> tap <x> <y>` for coordinate-based taps.
- **Type**: Use `xcrun simctl io <simulatorId> type <text>` after focusing a field.
- **Screenshot**: Use `xcrun simctl io <simulatorId> screenshot <path>` for visual confirmation.

## Logs & Console Output
- Stream logs: `xcrun simctl spawn <simulatorId> log stream --predicate 'subsystem == "<bundleId>"'`.
- Capture logs to file: redirect output to a file and summarize important lines.
- For console output, use `xcrun simctl launch --console <simulatorId> <bundleId>`.

## Troubleshooting
- If build fails, check `xcodebuild` output for errors and address them.
- If the wrong app launches, confirm the scheme and bundle id.
- If UI elements are not accessible, use Accessibility Inspector after layout changes.
