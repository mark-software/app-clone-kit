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
    3. Test EVERY user_stories entry for this feature — not just the primary action.
       For each user story, perform the described action and verify the expected outcome
    4. Test CRUD if applicable (based on data_model entities)
    5. CRUD matrix:
       - CREATE: FAB/add button -> fill form -> save -> verify appears in list
       - READ: Verify seed data displays with correct fields, badges, counts
       - UPDATE: Tap item -> edit a field -> save -> verify change persists in list
       - DELETE: Long-press -> Delete (from list) AND trash icon (from editor) -> verify removed
       - RESULT WIRING: If create/edit navigates to sub-screens, verify results flow back
         (e.g., selecting an item in a picker actually adds it to the parent editor's list)
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
5. Test EVERY user story in the test flow — not just the primary action. Each story must be performed and verified
6. Track every bug you find

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

## MCP Tool Guidance

- Accessibility tree may desync during rapid tab switches — this is a TOOL LIMITATION, not an app bug.
  Verify state by BOTH screenshot AND element list. If they conflict, trust the screenshot.
- After typing text, ALWAYS dismiss keyboard (press BACK) before clicking other UI elements.
- If a button tap produces NO visible change (no navigation, no state change, no feedback), that IS a bug.
  Do not move on — report it.
- "Screen renders" is NOT the same as "screen works". Toggle switches must change state.
  Dropdowns must open and close. Save buttons must persist data. Test the RESULT, not just the arrival.

Return ONLY a structured bug report. No narration.
```

### Phase 4: Interaction Audit

After all feature test flows complete, run an interaction audit on every screen. This catches elements that render but have no wired-up handlers — the most common class of missed bugs.

For each screen in `feature-map.json`, delegate to an agent with this prompt template:

```
You are auditing interactive elements on device "{device_id}".

## Screen: {screen_name}

Navigate to this screen: {navigation_instructions}

## Instructions

1. Call `mobile_list_elements_on_screen` to get ALL elements
2. Identify every interactive element: buttons, FABs, icon buttons, list items, text fields, switches, toggles, checkboxes, radio buttons, tabs, bottom nav items, menu items, clickable cards, links
3. For EACH interactive element:
   a. Screenshot (before state)
   b. Tap it using `mobile_click_on_screen_at_coordinates`
   c. Screenshot (after state)
   d. Check: did ANYTHING change? (new screen, dialog, keyboard, state toggle, animation, snackbar, selection highlight, expanded content)
   e. If nothing changed: record as a DEAD ELEMENT bug (severity: major)
   f. For each element type, verify the SPECIFIC expected feedback:
      - Buttons: produce visible feedback (navigation, dialog, snackbar, state change)
      - Toggles/switches: state visibly changes AND persists on re-visit
      - Save/submit: data persists (navigate away and return to verify)
      - Search/filter: results update to match query (including partial matches, enum names, hyphenated terms)
      - Destructive actions (delete, clear, reset): show confirmation OR success feedback (snackbar/toast)
   g. Press back / dismiss to return to the original screen
   h. Call `mobile_list_elements_on_screen` again to re-establish coordinates (they shift after navigation)
4. For text fields: tap to verify keyboard appears, then dismiss keyboard
5. For elements that navigate away: verify the destination screen loads, then navigate back

## Bug Report Format

For each dead element found:
- **Bug ID**: Sequential number
- **Screen**: {screen_name}
- **Element**: Element text/description and type (button, FAB, list item, etc.)
- **Coordinates**: Where you tapped
- **Expected**: Element should respond to tap (navigate, toggle, open dialog, etc.)
- **Actual**: No visible response
- **Severity**: major
- **Screenshot**: Before and after screenshots show no change

Return ONLY a structured bug report. If all elements respond correctly, return "All interactive elements verified — no dead elements found."
```

### Phase 5: Consolidate Results

After all agents complete (both feature flow agents and interaction audit agents):

1. Collect bug reports from each agent (feature flows + interaction audit)
2. Deduplicate bugs (same root cause across screens)
3. Categorize by severity — dead elements from the interaction audit are major by default
4. Generate final report

### Phase 6: Output Report

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
