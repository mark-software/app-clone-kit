# app-clone-kit

Clone any existing app using AI-powered automation. Three commands: research, build locally, connect backend.

**app-clone-kit** discovers an existing app's features through web research and optional APK decompilation, generates a dependency-ordered build plan, builds your own clean local-first implementation, and optionally connects a real backend with auth and offline-first sync. Your total hands-on time: ~30 minutes.

> **Philosophy:** Decompilation is for *feature discovery* — understanding what an app does and how it works. We don't copy code, styles, or implementation details verbatim. We use that understanding to build something better with clean, modern architecture.

## Quick Start

```bash
# Install into your project
curl -fsSL https://raw.githubusercontent.com/mark-software/app-clone-kit/main/bin/remote-install.sh | bash

# Start Claude Code
claude
> /research-app-01 SleepyPanda      # Research + plan
> /build-app-locally-02              # Build locally (new session)
> /connect-backend-03                # Add backend + auth (optional, new session)
```

That's it. Claude researches the app, asks you 5 preference questions, builds a plan, builds your app locally, and optionally connects a real backend.

## What It Does

**Phase 1 - Research:** Claude searches the Play Store, App Store, help centers, review sites, and forums to build a comprehensive feature inventory. Reference screenshots are gathered for UI fidelity. You never open the target app.

**Phase 2 - Decompile (optional):** If you provide an APK, jadx decompiles it and Claude discovers the app's feature surface — what screens exist, how navigation flows, what data entities are involved, what API patterns and design tokens are used. This is purely for understanding *what to build*, not how to copy it.

**Phase 3 - Feature Map:** Research and decompilation data merge into a dependency-ordered build queue. Features are grouped into phases of 2-4, with foundations first and reporting last.

**Build Phase:** Everything happens in one session — project initialization, all data models, shared components, navigation shell, then feature-by-feature implementation with testing between each step, followed by integration testing, visual fidelity checks, and polish. The app is fully functional with local data at this point.

**Connect Backend (optional):** Adds a real backend (Supabase, Firebase, custom REST, GraphQL) with authentication and offline-first sync. The local DB stays the source of truth — data syncs to the server in the background.

## Installation

### One-line install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/mark-software/app-clone-kit/main/bin/remote-install.sh | bash
```

This copies the slash command and phase files into your project:

```
.clone-kit/
└── phases/
    ├── 01-research.md
    ├── 02-decompile.md
    ├── 03-feature-map.md
    ├── build.md               # Build instructions
    └── connect-backend.md     # Backend connection instructions

.claude/
└── commands/
    ├── research-app-01.md          # /research-app-01 slash command
    ├── build-app-locally-02.md     # /build-app-locally-02 slash command
    └── connect-backend-03.md       # /connect-backend-03 slash command
```

### Manual install

```bash
git clone https://github.com/mark-software/app-clone-kit.git /tmp/app-clone-kit
cd your-project
/tmp/app-clone-kit/bin/install.sh
```

### Global install (available in all projects)

```bash
curl -fsSL https://raw.githubusercontent.com/mark-software/app-clone-kit/main/bin/remote-install.sh | bash -s -- --global
```

Installs the commands to `~/.claude/commands/` so they're available everywhere. Phase files are copied per-project on first run.

## Usage

### Interactive (Claude does the research)

```bash
claude
> /research-app-01 SleepyPanda
```

Claude will:
1. Research the app - package name, URLs, features, screenshots, help docs (you provide nothing)
2. Ask you 5 questions - tech stack, platform, tier, APK availability, optional screenshots
3. Run research and build the feature map
4. Show you a summary to skim (~5 min)
5. Tell you to run `/build-app-locally-02`

### Build locally (after research is done)

```bash
claude
> /build-app-locally-02
```

Builds the entire app locally in a single session using the research output. Everything works with local data — no backend needed. Run this after `/research-app-01`, or re-run it to rebuild from scratch — research data is preserved.

### Connect backend (optional, after local build)

```bash
claude
> /connect-backend-03
```

Adds a real backend to your working local app. Asks 4 questions (provider, connection details, auth method, sync strategy), then wires up auth, API services, and offline-first sync. The local DB stays the source of truth.

## Your Time Commitment

| When | What | Time |
|------|------|------|
| Start | Answer 5 preference questions | 2 min |
| After Phase 1 | Skim feature inventory | 5 min |
| After Phase 3 | Skim build queue | 5 min |
| After local build | Walk through the finished app | 10-20 min |
| Backend (optional) | Answer 4 backend questions | 2 min |
| **Total** | | **~30 min** |

## Prerequisites

**Required:**
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- Git

**Recommended:**
- Mobile MCP for automated testing (auto-installed during setup, or: `claude mcp add mobile-mcp -- npx -y @mobilenext/mobile-mcp@latest`)
- Android emulator or iOS simulator running

**Optional:**
- [jadx](https://github.com/skylot/jadx) for APK decompilation (feature discovery only): `brew install jadx`

## How It Works

The key insight is **decomposition + full context + testing gates**.

Complex apps fail when built without a plan. app-clone-kit breaks the problem into small, independently-testable units while keeping full context in a single session:

1. **Feature discovery** is automated via web research (and optionally APK decompilation for deeper understanding)
2. **Dependency ordering** ensures nothing is built before its prerequisites
3. **Each feature is built and tested** before the next one starts
4. **Single session with 1M context** keeps all research, analysis, and code in one place — no context loss between sessions
5. **Visual fidelity checks** compare built screens against reference screenshots from the original app
6. **Regression checks** after each build phase catch cross-feature breakage early
7. **Local-first architecture** means every feature works with local data — backend is an optional add-on, not a build dependency

## Project Structure (after running)

```
your-project/
├── CLAUDE.md                    # Generated project documentation
├── .claude/commands/
│   ├── research-app-01.md       # /research-app-01 slash command
│   ├── build-app-locally-02.md  # /build-app-locally-02 slash command
│   └── connect-backend-03.md   # /connect-backend-03 slash command
├── .clone-kit/
│   └── phases/                  # Phase instruction files
│       ├── 01-research.md
│       ├── 02-decompile.md
│       ├── 03-feature-map.md
│       ├── build.md             # Build instructions
│       └── connect-backend.md   # Backend connection instructions
├── config.json                  # Generated by /research-app
├── research/                    # Phase 1 output (+ screenshots)
├── analysis/                    # Phase 2 output (if APK)
├── feature-map.json             # Phase 3 output
├── build-queue.json             # Phase 3 output
├── screenshots/                 # Test screenshots
└── src/                         # Your app
```

## Configuration

`config.json` is generated by the `/research-app-01` command. You can also create it manually:

```json
{
  "target_app": {
    "name": "SleepyPanda",
    "package_name": "com.sleepypanda.app",
    "play_store_url": "https://play.google.com/store/apps/details?id=com.sleepypanda.app",
    "website": "https://sleepypanda.example.com",
    "help_center": "https://sleepypanda.example.com/help"
  },
  "clone_config": {
    "tech_stack": "kmp-compose",
    "language": "kotlin",
    "local_first": true,
    "platform_target": "android",
    "excluded_features": [],
    "tier_to_clone": "free"
  }
}
```

### Supported tech stacks

- `kmp-compose` (Kotlin) - default
- `react-native-expo` (TypeScript)
- `flutter` (Dart)
- `android-native` (Kotlin)
- `ios-native` (Swift)

## Troubleshooting

**Build stopped mid-session:** Start a new Claude Code session and run `/build-app-locally-02`. It reads the existing research and builds from scratch.

**Feature X failing after 3 retries:** The build defers it to the integration section. Issues are fixed during the polish pass at the end.

**Want to change tech stack:** Delete the generated source code, then run `/build-app-locally-02`. Research and feature map data (Phases 1-3) are stack-agnostic and reusable.

**No mobile MCP / emulator:** The build still works — it falls back to build-only verification (no crashes, no lint errors) instead of visual MCP testing. Results won't be as thorough.

## Contributing

PRs welcome. The main areas to improve:

- **Phase templates** (`templates/phases/`) - better prompts, more edge case handling
- **Tech stack support** - framework-specific scaffold instructions
- **Testing protocols** - more thorough MCP test sequences
- **Multi-agent support** - adapting the slash command for Copilot, Cursor, Gemini CLI

## License

MIT
