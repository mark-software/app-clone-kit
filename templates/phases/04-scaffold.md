# Phase 4: Architecture & Scaffold

## Goal

Set up the full project skeleton - data layer, shared components, navigation, placeholder screens - and verify it runs on emulator.

## Inputs

- `feature-map.json`
- `build-queue.json`
- `config.json` (tech stack)
- `research/visual-design.json` (visual design analysis from Phase 1)
- `research/screenshots/` (reference screenshots from Phase 1)
- `analysis/design-tokens.json` (extracted design tokens from Phase 2, if available)

## Outputs

- Working app that launches on emulator
- All data models and local DB tables
- Shared UI components
- Navigation shell with placeholders for every screen
- Seed data utility
- `progress.json` updated

## Instructions

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

### Step 6: Verify on emulator

Using mobile MCP (if available) or manual build:

1. App launches without crash
2. Every tab/section is reachable
3. Placeholder screens render with correct names
4. Seed data loads and list screens show entries
5. Shared components render correctly

**Do NOT proceed until verification passes.**

Fix issues immediately, re-verify, then continue.

## Completion

```
Phase 4 complete.
- [tech stack] project initialized
- [N] data models with CRUD
- [N] shared components
- [N] navigation routes
- Seed data: [N] entries across [N] types
- Emulator verification: PASSED

Next: Run ./.clone-kit/pipeline.sh or manually:
"Read .clone-kit/phases/05-build-loop.md and execute build phase 0"
```
