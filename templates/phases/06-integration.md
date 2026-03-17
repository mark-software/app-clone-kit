# Phase 6: Integration & Polish

## Goal

Fix deferred issues, test cross-feature flows, polish UI, final walkthrough. Transform "features work individually" into "feels like a real app."

## Inputs

- Completed app from Phase 5
- `test-results.json` (deferred issues)
- `feature-map.json`
- `config.json`

## Outputs

- All deferred issues resolved
- Cross-feature flows tested
- UI polished
- Final screenshots
- `progress.json` updated

## Instructions

### Step 1: Fix deferred issues

Read `test-results.json` for `pass_with_issues` and `failed` entries.

For each:
1. Reproduce via mobile MCP
2. Fix
3. Verify fix
4. Regression test related features

### Step 2: Cross-feature integration testing

Test flows that span multiple features:
- Dashboard/home shows aggregated data from all features
- Adding data in one feature doesn't corrupt another
- Multi-profile switching (if applicable) isolates data correctly
- Concurrent timers (if applicable) don't conflict
- Reports/summaries correctly aggregate across features
- Settings changes apply consistently everywhere
- Dark mode (if applicable) renders on every screen
- Notifications from different features don't interfere

For each flow: execute with MCP, screenshot, fix issues.

### Step 3: UI polish

Screen by screen:

**Visual fidelity check (reference screenshots):**
- Open reference screenshots from `research/screenshots/` side by side with the built screens
- For each major screen, compare against the original:
  - Color palette matches
  - Layout structure and element positioning match
  - Typography weight and sizing match
  - Spacing and density match
  - Icon style matches
- Fix any significant visual deviations before proceeding to general polish

**Spacing & layout:**
- Consistent padding
- No text clipping or overflow
- Touch targets minimum 44x44pt
- Lists scroll smoothly

**States & transitions:**
- Loading states aren't blank
- Empty states have messaging + call-to-action
- Errors are user-friendly
- Transitions feel natural

**Typography & color:**
- Font sizes consistent per element type
- Colors consistent (same color = same meaning)
- Sufficient contrast
- Dark mode readable (if applicable)

**Platform conventions:**
- Back navigation works
- Pull-to-refresh where expected
- Keyboard dismisses properly
- Status bar matches

**UI/UX improvement pass:**

After confirming visual fidelity with the original, review each screen for genuine improvements:

- Accessibility: ensure contrast ratios meet WCAG AA (4.5:1 for text, 3:1 for large text/UI)
- Touch targets: enlarge any below 44x44pt
- Visual hierarchy: ensure the most important content draws the eye first
- Consistency: fix any inconsistencies the original app had (e.g., mismatched padding, inconsistent icon weights)
- Modern patterns: if the original uses clearly dated patterns (e.g., hamburger menu when bottom tabs would work better), consider updating — but only for clear wins

Rules for this pass:
- Do NOT change the color palette or brand identity
- Do NOT rearrange screen layouts unless the original has a clear usability problem
- Do NOT add decorative elements, animations, or visual flourish
- Every change must have a concrete justification (accessibility, usability, consistency)
- When in doubt, keep the original's design
- Take before/after screenshots for each change made

### Step 4: First-run experience

If onboarding exists in the feature map:
1. Clear all app data
2. Launch fresh
3. Complete onboarding
4. Add first entry in each feature
5. Verify everything works from empty state

### Step 5: Final walkthrough

For a comprehensive automated QA pass, run `/test-mobile-app` — it auto-generates test flows from `feature-map.json`, delegates each to agents, and produces a consolidated bug report in `docs/qa/`.

For manual walkthrough of every feature:

```
FOR EACH FEATURE:
  1. Navigate to it
  2. Screenshot primary screen
  3. Perform main action
  4. Verify
  5. Next feature
```

Save to `screenshots/final/`.

### Step 6: Clean up

- Hide or remove seed data loader from default builds
- Verify no placeholder screens remain
- Remove debug logging
- Resolve or document TODO comments

## Completion

```
Pipeline complete.

- [N] features implemented and verified
- [N] deferred issues resolved
- [N] known omissions (documented)
- Screenshots in screenshots/final/

FINAL REVIEW (~10-20 min): Open the app and walk through it.
- Try each main feature
- Note anything off

If issues found, describe them in a new Claude Code session:
  "Fix these issues: [list]. Test each with mobile MCP."
```
