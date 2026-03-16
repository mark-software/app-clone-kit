---
name: "test-mobile-app"
description: "Run a structured QA pass on a mobile app using the mobile MCP server. Auto-detects framework, builds, installs, and tests the app on an emulator, delegating individual test flows to agents for context efficiency. Returns a consolidated bug report."
version: 1.0.0
---

# Mobile App QA Testing

## Overview

Systematically test a mobile app on an Android emulator using the mobile MCP tools. This skill orchestrates the full QA lifecycle: build, install, and run through test flows — delegating screen-level tests to agents to conserve context.

Supports all frameworks used by app-clone-kit: KMP Compose, React Native Expo, Flutter, Native Android, and Native iOS.

## Inputs

The user provides either:
- A test plan (inline or file path) describing screens/flows to test
- `$ARGUMENTS` — optional flags like `--skip-build`, `--framework <name>`, `--device <id>`, or a path to a test plan file

If no test plan is provided, auto-generate one from the app's state:
1. Read `feature-map.json` for structured feature list with screens and user stories
2. Read `build-queue.json` for build phase groupings
3. Read `test-results.json` for prior test state
4. Fall back to scanning navigation/screen files if none of the above exist

## Process

### Phase 1: Setup

1. **Detect framework**: Determine build system in this order:
   - Read `config.json` → `clone_config.tech_stack` (if app-clone-kit project)
   - Check `--framework` flag from `$ARGUMENTS`
   - Auto-detect from project files (see detection table below)

2. **Discover device**: Call `mobile_list_available_devices` to find the target emulator/device

3. **Build** (unless `--skip-build`):
   Run the appropriate build command based on detected framework:

   | Framework | Detection file | Build command | APK location |
   |-----------|---------------|---------------|--------------|
   | `kmp_compose_multiplatform` | `composeApp/build.gradle.kts` | `./gradlew :composeApp:assembleDebug` | `composeApp/build/outputs/apk/debug/` |
   | `react_native_expo` | `app.json` + `node_modules/expo/` | `npx expo run:android` | `android/app/build/outputs/apk/debug/` |
   | `flutter` | `pubspec.yaml` | `flutter build apk --debug` | `build/app/outputs/flutter-apk/` |
   | `android_native` | `app/build.gradle.kts` (no `composeApp/`) | `./gradlew assembleDebug` | `app/build/outputs/apk/debug/` |
   | `ios_native` | `*.xcodeproj` or `*.xcworkspace` | See iOS section below | N/A (uses simulator) |

4. **Resolve applicationId / package name**:
   - `kmp_compose_multiplatform`: parse `composeApp/build.gradle.kts` for `applicationId`
   - `react_native_expo`: parse `app.json` → `expo.android.package`
   - `flutter`: parse `android/app/build.gradle` for `applicationId`
   - `android_native`: parse `app/build.gradle.kts` for `applicationId`
   - Or read from `config.json` → `target_app.android_package` if available

5. **Install**: Use `mobile_install_app` with the built APK
6. **Launch**: Use `mobile_launch_app` with the package name
7. **Verify launch**: Take a screenshot to confirm the app started

### Phase 2: Parse Test Plan

If a test plan was provided, parse it into independent **test flows**.

If no test plan, auto-generate from `feature-map.json`:

```
FOR EACH feature in feature-map.json:
  Create a flow named after the feature
  Steps:
    1. Navigate to the feature's primary screen (use navigation info from feature map)
    2. Verify screen elements render (based on feature's data_model fields)
    3. Perform primary action (based on feature's user_stories)
    4. Verify result
    5. Test CRUD if applicable (based on data_model entities)
    6. Test empty state
    7. Navigate away and back — verify persistence
    8. Screenshot
```

Group flows by dependency:
- **Independent flows** can run via parallel agents
- **Sequential flows** must run in order (e.g., onboarding before trackers)
- Use `build-queue.json` phase groupings as a dependency hint — earlier phases are prerequisites

### Phase 3: Execute Test Flows

For each test flow, delegate to an agent with this prompt template:

```
You are testing the mobile app on device "{device_id}".

## Your Test Flow: {flow_name}

{flow_steps}

## Instructions

1. Use `mobile_list_elements_on_screen` to find exact element coordinates before clicking — NEVER guess coordinates from screenshots
2. Use `mobile_click_on_screen_at_coordinates` with the coordinates from the element list
3. After each action, take a screenshot to verify the result
4. If something doesn't work, try once more with fresh element coordinates
5. Track every bug you find

## Bug Report Format

For each bug found, report:
- **Bug ID**: Sequential number
- **Screen**: Which screen
- **Action**: What you did
- **Expected**: What should happen
- **Actual**: What actually happened
- **Severity**: critical / major / minor / cosmetic
- **Screenshot**: Describe what the screenshot shows

## Important Mobile MCP Tips

- Always call `mobile_list_elements_on_screen` before clicking — element coordinates from screenshots are unreliable
- Use `mobile_press_button` with "BACK" to dismiss keyboards or go back on Android
- After typing with `mobile_type_keys`, dismiss keyboard before interacting with other elements
- Date pickers: list elements to find exact OK/Cancel button coordinates
- Wait briefly after navigation before taking screenshots

Return ONLY a structured bug report. No narration.
```

### Phase 4: Consolidate Results

After all agents complete:

1. Collect bug reports from each agent
2. Deduplicate bugs (same root cause across screens)
3. Categorize by severity
4. Generate final report

### Phase 5: Output Report

Write the consolidated report to `docs/qa/YYYY-MM-DD-qa-report.md`:

```markdown
# QA Report — {app_name} — {date}

## Summary
- Framework: {framework}
- Tested: {count} flows
- Bugs found: {count} (critical: X, major: X, minor: X, cosmetic: X)
- Device: {device_name} ({platform} {version})

## Bugs

### [Critical]

### [Major]

| # | Screen | Bug | Expected | Actual |
|---|--------|-----|----------|--------|

### [Minor]

### [Cosmetic]

## Flows Tested
- [x] {flow_name} — {pass/fail} ({bug_count} bugs)
```

Also update `test-results.json` if it exists (app-clone-kit integration):

```json
{
  "results": [
    {
      "feature_id": "feature_id",
      "phase": 0,
      "status": "pass | pass_with_issues | failed",
      "attempts": 1,
      "tests_run": 8,
      "tests_passed": 8,
      "screenshots": ["paths"],
      "issues": ["bug descriptions"],
      "timestamp": ""
    }
  ]
}
```

## iOS Support (Experimental)

When `config.json` specifies `ios_native` or test platform is `ios_simulator`:

- **Build**: `xcodebuild -scheme <scheme> -sdk iphonesimulator -configuration Debug build`
- **Install**: `xcrun simctl install booted <app_path>`
- **Launch**: `xcrun simctl launch booted <bundle_id>`
- **Device discovery**: `xcrun simctl list devices available`

The mobile MCP tools handle iOS simulators the same way as Android emulators — use the same `mobile_*` calls.

## Key Principles

- **Always use element list for coordinates** — screenshots give wrong pixel values
- **Dismiss keyboards** before tapping non-keyboard elements
- **One action, one verification** — screenshot after every meaningful action
- **Delegate to agents** — each screen/flow gets its own agent to save context
- **Report bugs precisely** — screen, action, expected vs actual, severity
- **Read app-clone-kit state first** — `feature-map.json` and `build-queue.json` have everything needed to generate test plans automatically
