# Build Phase: Single-Session App Build

ALL CODE MUST BE CLEAN, MAINTAINABLE, AND ADHERE TO THE SINGLE RESPONSIBILITY PRINCIPLE. NO EXCEPTIONS.

Build the entire app in one session. Read all context first, then scaffold, build features, integrate, and verify.

## Section 1: Read Context

Before writing any code, read and internalize ALL of these files:

1. `config.json` — target app info, tech stack, platform
2. `feature-map.json` — every feature spec, screens, behaviors, interactions, dependencies
3. `build-queue.json` — phase ordering and feature groupings
4. `research/visual-design.json` — visual design analysis (colors, typography, layout patterns, interactions)
5. `research/screenshots/` — reference screenshots of the original app (for UI fidelity)
6. `research/*.json` — feature inventory and other research
7. `analysis/design-tokens.json` — extracted design tokens from APK (if present)
8. `analysis/*.json` — data models, screens, navigation, APIs, SDKs, storage (if present)

Understand the full picture before writing a single line.

## Section 2: Scaffold

### Step 1: Initialize project

Read `config.json` for tech stack. Initialize accordingly:

- **kmp-compose**: Download the JetBrains "Shared UI" Compose Multiplatform template (`curl -L -o template.zip "https://kmp.jetbrains.com/template/download/KMP-App-Template" && unzip template.zip`), then configure with SQLDelight, Koin, Ktor, and Compose Navigation
- **react-native-expo**: `npx create-expo-app@latest` with TypeScript, expo-router, expo-sqlite
- **flutter**: `flutter create` with sqflite, provider
- **android-native**: Gradle project with Room, Navigation Component, Hilt
- **ios-native**: Xcode project with SwiftData/CoreData, SwiftUI

### Step 2: Create data layer

Read ALL entities from `feature-map.json`. Create every model, table, and repository at once:
- Model/type definitions
- Database tables with proper indices
- Repository/DAO with CRUD operations
- Seed data (5-10 realistic entries per entity, spanning last 7 days)

**Architecture note:** Follow SRP — split large repositories into focused manager classes by domain (e.g., NoteManager, LabelManager, SearchManager) behind a repository facade.

### Step 3: Shared components

Extract common patterns from the feature map. Typical components:
- Timer display and controls (if app has timing features)
- Entry/item cards for list views
- Empty state placeholder
- Date/time pickers
- Category/type selectors
- Stat/metric display cards
- Chart containers
- FAB (floating action button) for quick-add
- Section headers for grouped lists

Set up a design system that matches the original app's visual identity:

1. Read `research/visual-design.json` and `analysis/design-tokens.json` (if available)
2. Color palette: Use the original app's colors. Map them to your framework's theme system (primary, secondary, background, surface, error, text colors)
3. Typography: Match the original's font family (or closest equivalent available for your framework) and size scale
4. Spacing: Use the original's spacing values, or match its density (compact/comfortable/spacious)
5. Corner radius: Match the original's corner style
6. Elevation/shadow: Match the original's depth style
7. Icon set: Use an icon set matching the original's style (outlined, filled, rounded, etc.)

If design tokens weren't extracted (no APK), derive values from the reference screenshots in `research/screenshots/`.

- Ensure all bottom-pinned content (bottom bars, FABs, toolbars, palettes) respects
  `navigationBarsPadding()` (Android) or safe area insets (iOS/Flutter) for edge-to-edge display.
  This prevents content from hiding behind system navigation bars.

### Step 4: Navigation structure

Create the full navigation from `feature-map.json` screens:
- Bottom tabs / drawer for main sections
- Stack navigators within each section
- Modal presentations for add/edit flows
- Placeholder screen for every route (shows name + "Phase N" badge)

### Step 5: Seed data loader

Build a dev utility that:
- Populates DB with realistic test data on first launch
- Can be re-run to reset
- Has a dev-mode toggle (hidden gesture or settings flag)

### Step 6: Verify scaffold

**MANDATORY: Install and run on emulator.** Build the APK, install it, launch the app, and verify using mobile MCP tools (screenshot, list elements, click). A compile-only check (`assembleDebug`) is NOT sufficient — you MUST see the app running.

1. Build: `./gradlew assembleDebug` (or equivalent)
2. Install: `mobile_install_app` with the built APK
3. Launch: `mobile_launch_app` with the package name
4. Screenshot: `mobile_take_screenshot` — verify the app launched
5. Navigate to every tab/section — screenshot each one
6. Verify:
   - App launches without crash
   - Every tab/section is reachable
   - Placeholder screens render with correct names
   - Seed data loads and list screens show entries
   - Shared components render correctly

**Do NOT proceed to feature building until verification passes on the emulator.** Fix issues immediately and re-verify. If the emulator is not available, stop and tell the user — do not silently skip testing.

## Section 3: Build Loop

**CRITICAL BUILD RULE: Every build phase ends with `/test-mobile-app`.** You MUST run the `/test-mobile-app` skill after completing each phase. Do NOT skip this step. Do NOT proceed to the next phase until critical/major bugs are fixed. The compile check (`assembleDebug`) alone tells you nothing — runtime crashes, layout bugs, and navigation failures are only caught on the emulator.

Work through `build-queue.json` phases in order (phase 0, then 1, then 2, etc.). For each phase, build ALL features in that phase before moving to the next.

### Build order within a feature

1. Wire up data repository calls
2. Build primary screen UI
3. Add create/add flow
3.5. Wire sub-screen results
   - For every screen reachable FROM this editor (pickers, sub-editors, dialogs),
     verify the result is passed back via savedStateHandle or equivalent
   - Common pattern: Editor -> Picker -> Sub-editor -> save -> result flows back to Editor
   - Specifically check: does the parent screen's state update when the sub-screen completes?
   - Example bugs this prevents: sub-editor saves but item doesn't appear in parent,
     picker confirms selection but config doesn't return to the calling editor
4. Add edit flow
5. Add delete with confirmation
   - Delete must be accessible from BOTH:
     a. Inside the editor (toolbar trash icon or button)
     b. From the list via long-press context menu (Edit/Delete options)
   - Shared list card components must support onLongClick parameter
   - All destructive actions show confirmation or provide visible feedback (snackbar)
6. Implement special behaviors (timers, calculations, auto-defaults)
7. Implement gesture interactions (long-press, swipe, drag-to-reorder)
8. Handle empty state
9. Handle loading state
10. Handle error state

### Code rules

- No hardcoded strings
- No inline styles — use the design system
- Every screen handles: loading, empty, populated, error
- Every list handles: empty, single item, many items, scroll
- Every form handles: validation, required fields, save
- Use shared components from scaffolding
- Follow SRP — each class has one reason to change

### Visual comparison gate

**After building each screen's UI (step 2), perform a visual comparison before proceeding:**

1. Take a screenshot of the built screen using mobile MCP
2. Open the reference screenshot for this screen from `research/screenshots/`
3. Compare side by side:
   - **Layout structure**: Are elements in the same positions? Same hierarchy?
   - **Spacing**: Does the density match? Are margins/padding similar?
   - **Colors**: Do card backgrounds, text colors, and accent colors match?
   - **Typography**: Are font sizes and weights similar?
   - **Component shapes**: Do corners, elevations, and borders match?
4. If differences are significant: adjust the UI and re-screenshot until it matches
5. If the reference screenshot doesn't exist: verify the screen is consistent with screens that DO have references

**This is not optional.** The goal is a clone, not a loose interpretation. The built UI should be recognizable as the same app to someone who uses the original.

### Code review gate

**MANDATORY: After coding each feature, self-review before testing on emulator.** This catches bugs that visual/emulator testing misses entirely.

#### Wiring checks
1. **Click handlers exist**: Every Button, FAB, IconButton, clickable card, list item tap, and menu item has an onClick/onPress/onTap that calls a function — not an empty body, not a TODO
2. **Handlers do something**: Each click handler either navigates, calls a repository/ViewModel method, shows a dialog, or changes state. Trace from the UI element to the actual effect
3. **Navigation targets exist**: Every navigation call references a route/screen that is implemented (not a placeholder). Arguments are passed correctly
4. **Forms save**: Every form's save/submit button calls the repository to persist data. Verify the flow: collect field values → validate → call repository → navigate back or show confirmation
5. **State observation**: Every state variable (loading, error, list data, form fields) is both set by the ViewModel/controller AND observed/collected in the UI. No orphan states
6. **No stubs**: Search for empty function bodies, TODO comments, and `pass`/`return`/`Unit` stubs in handlers. Every function body must have real logic. This includes "Coming Soon" screens, disabled buttons with no implementation behind them, and features that show a message instead of working. If a feature is in the build queue, it must work

#### Logic and correctness checks
7. **Data flow is complete**: Data written in create/edit flows is the same data read and displayed in list/detail screens. Field names and types match end-to-end (UI → ViewModel → Repository → DB → Repository → ViewModel → UI)
8. **Filtering and sorting**: If the feature has filters, search, or sort — verify the query/logic is actually applied to the displayed list, not just stored in state
9. **Delete cascades**: When an entity is deleted, verify related data is also cleaned up (e.g., deleting a category removes or re-assigns items in that category)
10. **Boundary conditions**: Empty strings, zero values, null/optional fields, maximum-length input — verify these don't cause crashes or silent failures
11. **Duplicate prevention**: If business logic requires uniqueness (e.g., category names), verify it's enforced
12. **Date/time handling**: Verify timezone consistency, correct formatting, and that date comparisons work as expected (especially "today" filters, date ranges, relative time displays)
13. **Callback/lambda captures**: Verify that click handlers inside lists/loops capture the correct item (not always the last item or a stale reference)
14. **Resource cleanup**: Timers, listeners, coroutine scopes, and subscriptions are cancelled in onDispose/onDestroy/onCleared

#### Quick scan
15. **Read through every file you wrote for this feature** — look for anything that seems wrong, incomplete, or inconsistent. If something looks off, it probably is

If any check fails, fix it immediately before proceeding to testing.

### Testing as you go

**MANDATORY: After building each feature (and passing the code review gate), install the updated APK and test on the emulator.** Do not batch features without testing — each feature must be verified before starting the next.

1. Build: `./gradlew assembleDebug` (or equivalent)
2. Install updated APK on emulator via `mobile_install_app`
3. Launch app via `mobile_launch_app`
4. Navigate to the feature's primary screen
5. Screenshot: verify UI renders (no crash, correct layout)
6. Visual comparison gate (see above)
7. **Interaction audit**: Call `mobile_list_elements_on_screen`. For EVERY interactive element (buttons, FABs, list items, text fields, switches, tabs, menu items, clickable cards): tap it, screenshot, verify something changed (navigation, dialog, state change, keyboard, selection). Press back/dismiss to return. Any element that produces no response is a bug — fix it before continuing
8. **User story coverage**: Test EVERY `user_stories` entry from this feature's `feature-map.json` spec — not just the "primary action". For each story, perform the described action and verify the expected outcome
9. Edit: modify an entry, verify persistence
10. Delete: remove an entry with confirmation, verify removal
11. Empty state: delete all entries, verify empty UI shows correctly with messaging and call-to-action
12. Navigate away and back: verify state persists

If a feature fails after 3 fix attempts, simplify the implementation — reduce scope to a working version rather than leaving a stub. A basic but functional implementation is always better than "coming soon". Every feature in the build queue must be usable when its build phase ends.

### Regression checks

After completing each build phase, run `/test-mobile-app` to execute a full QA pass. This skill auto-generates test flows from `feature-map.json`, delegates each to agents, and returns a consolidated bug report.

Fix all critical and major bugs before continuing to the next phase. Minor/cosmetic bugs (visual polish only — spacing, colors, animations) can be deferred to Section 4. Incomplete functionality, placeholder screens, "coming soon" text, and dead buttons are NOT minor — they are major bugs and must be fixed before proceeding.

## Section 4: Integration & Polish

### Step 1: Fix any deferred issues

Go back to any features that had problems. Reproduce, fix, verify.

### Step 2: Cross-feature integration

Test flows that span multiple features:
- Home/dashboard shows aggregated data from all features
- Adding data in one feature doesn't corrupt another
- Settings changes apply consistently everywhere
- Dark mode (if applicable) renders on every screen

For each flow: execute with MCP if available, fix issues.

### Step 3: Interaction fidelity pass

Go through each feature's `interactions` field from `feature-map.json` and implement:

**Screen transitions:**
- Card-to-fullscreen expand animation (e.g., tapping a note card expands it to the editor)
- Shared element transitions where applicable (title text, card background color)
- Slide/fade transitions for push/pop navigation
- Bottom sheet spring animations for modals

**Gesture interactions:**
- Long-press to enter selection mode (with haptic feedback if available)
- Multi-select: tap to toggle, action bar with bulk actions
- Drag-to-reorder with spring physics and visual feedback (item lifts, shadow increases, other items slide)
- Swipe gestures where the original app uses them (swipe-to-archive, swipe-to-delete)
- Pull-to-refresh where applicable

**Micro-interactions:**
- Checkbox check/uncheck animation
- FAB press feedback
- Color picker selection feedback
- Snackbar with undo for destructive actions

**For each interaction:**
1. Check the reference screenshots/video for the expected behavior
2. Implement it
3. Test on emulator via MCP
4. Compare feel with the original

### Step 4: UI polish

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

**Spacing & layout:** Consistent padding, no text clipping or overflow, touch targets minimum 44x44pt, lists scroll smoothly

**States & transitions:** Loading states aren't blank, empty states have messaging + call-to-action, errors are user-friendly

**Typography & color:** Font sizes consistent per element type, colors consistent (same color = same meaning), sufficient contrast

**Platform conventions:** Back navigation works, pull-to-refresh where expected, keyboard dismisses properly

**UI/UX improvement pass:**

After confirming visual fidelity with the original, review each screen for genuine improvements:
- Accessibility: ensure contrast ratios meet WCAG AA (4.5:1 for text, 3:1 for large text/UI)
- Touch targets: enlarge any below 44x44pt
- Visual hierarchy: ensure the most important content draws the eye first
- Consistency: fix any inconsistencies the original app had
- Modern patterns: if the original uses clearly dated patterns, consider updating — but only for clear wins

Rules for this pass:
- Do NOT change the color palette or brand identity
- Do NOT rearrange screen layouts unless the original has a clear usability problem
- Do NOT add decorative elements or visual flourish that aren't in the original
- Every change must have a concrete justification (accessibility, usability, consistency)
- When in doubt, keep the original's design

### Step 5: First-run experience

If onboarding exists in the feature map:
1. Clear all app data
2. Launch fresh
3. Complete onboarding
4. Add first entry in each feature
5. Verify everything works from empty state

### Step 6: Clean up

- Hide or remove seed data loader from default builds
- Verify no placeholder screens, "coming soon" messages, or stub functionality remain — every feature in the build queue must be fully functional
- Search codebase for: "coming soon", "placeholder", "not yet", "TODO", "FIXME", "stub" — fix or remove each instance
- Remove debug logging
- Resolve or document TODO comments

## Section 5: Verify

### Final build check

1. Clean build: `./gradlew clean assembleDebug` (or equivalent for the tech stack)
2. Install on emulator via `mobile_install_app`
3. Launch and screenshot to confirm app starts
4. Run `/test-mobile-app` for a comprehensive automated QA pass across all features. Fix any critical/major bugs found. This step is MANDATORY — do not skip it. **Zero tolerance for stubs**: if any feature shows "coming soon", placeholder content, or non-functional UI, it is a critical bug. Do not mark the build complete until every feature in `build-queue.json` is functional.

### Generate CLAUDE.md

Generate a `CLAUDE.md` at the project root so any future Claude Code session can immediately understand this project.

**If a CLAUDE.md already exists**, read it first and preserve any existing content — user-written instructions, project conventions, coding standards, or custom sections. Merge the sections below into the existing file. Do not overwrite anything the user already had.

Read these files for context:
- `config.json` — target app name, tech stack
- `feature-map.json` — all planned features, data models, screens
- `build-queue.json` — build phase plan
- `research/visual-design.json` — design system details

Write `CLAUDE.md` with these sections:

1. **Project Overview** — One paragraph: what app this clones, what it does, the tech stack
2. **Tech Stack** — Framework, key libraries, database, navigation, DI, state management
3. **Project Structure** — Actual directory tree of the project (use the real structure)
4. **Data Models** — Every entity with fields, types, and relationships
5. **Navigation Structure** — Tab/drawer layout, screen routes, navigation flows
6. **Design System** — Color palette (hex values), typography, spacing scale, corner radius, elevation, icon set
7. **Implemented Features** — All features with key screens and notable behaviors
8. **Testing** — How to build and run on emulator, framework-specific commands, mobile MCP testing
9. **Build & Run** — Prerequisites and exact commands to build, run, and test
10. **Known Issues** — Any remaining limitations or deferred items

The CLAUDE.md should read as documentation for a finished app, not a build log.

### Completion

```
Build complete.

- [N] features implemented across [N] build phases
- Tech stack: [stack]
- Deferred issues: [list if any, or "none"]

FINAL REVIEW (~10-20 min): Open the app and walk through it.
- Try each main feature
- Note anything off

If issues found, describe them:
  "Fix these issues: [list]. Test each with mobile MCP."

Next (optional): start a new session and run:
  /connect-backend-03
to add a real backend with auth and offline-first sync.
```
