# Phase 5: Iterative Build Loop

## Goal

Build each feature from the build queue, test with mobile MCP, proceed only on pass. One session per build phase.

## Inputs

- `feature-map.json` (only features for current build phase)
- `build-queue.json`
- `test-results.json` (prior results)
- `progress.json`

## Outputs

- Implemented features
- `screenshots/` per feature
- `test-results.json` updated
- `progress.json` updated

## The Loop

```
FOR EACH FEATURE IN THIS BUILD PHASE:
  1. READ spec from feature-map.json
  2. BUILD the feature
  3. TEST with mobile MCP
  4. EVALUATE
     ├─ PASS → log, continue
     └─ FAIL → fix, re-test (max 3 attempts)

AFTER ALL FEATURES:
  5. REGRESSION TEST prior features
     ├─ PASS → update progress, done
     └─ FAIL → fix regressions first
```

## Build Order Within a Feature

1. Wire up data repository calls
2. Build primary screen UI
3. Add create/add flow
4. Add edit flow
5. Add delete with confirmation
6. Implement special behaviors (timers, calculations, auto-defaults)
7. Handle empty state
8. Handle loading state
9. Handle error state

**Code rules:**
- No hardcoded strings
- No inline styles - use the design system
- Every screen handles: loading, empty, populated, error
- Every list handles: empty, single item, many items, scroll
- Every form handles: validation, required fields, save
- Use shared components from Phase 4

## Test Protocol

For standalone QA runs, use `/test-mobile-app` which auto-detects framework and generates test plans from `feature-map.json`.

For each feature, via mobile MCP:

```
a. Navigate to the feature's primary screen
b. Screenshot: verify UI renders (no crash, correct layout)
c. Happy path: perform primary action, verify result
d. Edit: modify an entry, verify persistence
e. Delete: remove an entry, verify removal
f. Empty state: verify empty UI shows correctly
g. Edge cases: test behaviors from feature spec
h. Navigate away and back: verify state persists
```

Screenshots: `screenshots/phase-{N}/{feature_id}/{test_name}.png`

## Pass Criteria (ALL required)

- No crashes during any test step
- UI renders correctly (no clipping, overlap, missing elements)
- CRUD operations work
- Data persists across navigation
- Empty states display correctly
- Feature-specific behaviors work per spec

## Fail Handling

- Identify failure, fix, re-run FULL test sequence
- Max 3 fix-and-retest cycles per feature
- After 3 failures: log in test-results.json with details, move on (deferred to Phase 6)

## Regression Testing

After all features in this build phase pass:

```
FOR EACH PREVIOUSLY-BUILT FEATURE:
  a. Navigate to its screen
  b. Screenshot
  c. Perform one quick action
  d. Verify no crash or breakage
```

Fix regressions before reporting phase complete.

## Progress Tracking

Update `test-results.json`:

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
      "issues": [],
      "timestamp": ""
    }
  ]
}
```

Update `progress.json` with `last_build_phase_completed`.

## Context Management

Each build phase should be a separate Claude Code session. At session start:
1. Read this file
2. Read feature-map.json - ONLY entries for current build phase
3. Read test-results.json and progress.json
4. Do NOT load full feature map or prior phase docs

For complex features, use the Task tool to delegate to subagents.

## Completion

```
Build phase [N] complete.
- [N] features: [N] passed, [N] with issues, [N] failed
- Regression tests: PASSED
- Deferred issues: [list if any]
```
