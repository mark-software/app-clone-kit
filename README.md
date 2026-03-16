# app-clone-kit

Clone any existing app using AI-powered automation. One command to install, one slash command to start.

**app-clone-kit** reverse-engineers an existing app's features through web research and optional APK decompilation, generates a dependency-ordered build plan, then executes it phase-by-phase with automated testing between each step. Your total hands-on time: ~25 minutes.

## Quick Start

```bash
# Install into your project
npx app-clone-kit init

# Start Claude Code and clone an app
claude
> /clone SleepyPanda
```

That's it. Claude researches the app, asks you 4 preference questions, builds a plan, and tells you when to run the automated build pipeline.

## What It Does

**Phase 1 - Research:** Claude searches the Play Store, App Store, help centers, review sites, and forums to build a comprehensive feature inventory. You never open the target app.

**Phase 2 - Decompile (optional):** If you provide an APK, jadx decompiles it and Claude extracts the real data models, screen structure, navigation graph, and API endpoints.

**Phase 3 - Feature Map:** Research and decompilation data merge into a dependency-ordered build queue. Features are grouped into phases of 2-4, with foundations first and reporting last.

**Phase 4 - Scaffold:** Project initialization, all data models, shared components, navigation shell, seed data. Verified on emulator before proceeding.

**Phase 5 - Build Loop:** Each feature is built, tested via mobile MCP, and verified before the next one starts. Regressions are caught between phases. One Claude Code session per build phase.

**Phase 6 - Integration:** Deferred issues fixed, cross-feature flows tested, UI polished, final walkthrough.

## Installation

### One-line install (recommended)

```bash
npx app-clone-kit init
```

This copies the slash command and phase files into your project:

```
.clone-kit/
├── phases/
│   ├── 01-research.md
│   ├── 02-decompile.md
│   ├── 03-feature-map.md
│   ├── 04-scaffold.md
│   ├── 05-build-loop.md
│   └── 06-integration.md
└── pipeline.sh

.claude/
└── commands/
    └── clone.md           # /clone slash command
```

### Manual install

```bash
git clone https://github.com/youruser/app-clone-kit.git /tmp/app-clone-kit
cd your-project
/tmp/app-clone-kit/bin/install.sh
```

### Global install (available in all projects)

```bash
npx app-clone-kit init --global
```

Installs the `/clone` command to `~/.claude/commands/` so it's available everywhere. Phase files are copied per-project on first run.

## Usage

### Interactive (Claude does the research)

```bash
claude
> /clone SleepyPanda
```

Claude will:
1. Research the app - package name, URLs, features, help docs (you provide nothing)
2. Ask you 4 questions - tech stack, platform, tier, APK availability
3. Run research and build the feature map
4. Show you a summary to skim (~5 min)
5. Hand off to the build pipeline

### Automated build

```bash
./clone-kit/pipeline.sh              # Run or resume
./clone-kit/pipeline.sh status       # Check progress
./clone-kit/pipeline.sh phase 3      # Run specific build phase
./clone-kit/pipeline.sh reset        # Reset build progress (keeps research)
```

The pipeline runs one Claude Code session per build phase. Sessions are autonomous - start one and walk away. Progress is tracked in `progress.json` so you can resume after any interruption.

## Your Time Commitment

| When | What | Time |
|------|------|------|
| Start | Answer 4 preference questions | 2 min |
| After Phase 1 | Skim feature inventory | 5 min |
| After Phase 3 | Skim build queue | 5 min |
| After Phase 6 | Walk through the finished app | 10-20 min |
| **Total** | | **~25 min** |

## Prerequisites

**Required:**
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- Node.js 18+

**Recommended:**
- Mobile MCP for automated testing: `claude mcp add mobile-mcp -- npx -y @mobilenext/mobile-mcp@latest`
- Android emulator or iOS simulator running

**Optional:**
- [jadx](https://github.com/skylot/jadx) for APK decompilation: `brew install jadx`

## How It Works

The key insight is **decomposition + isolation + testing gates**.

Complex apps fail when built in one shot because bugs compound across features. app-clone-kit breaks the problem into small, independently-testable units:

1. **Feature discovery** is automated via web research (and optionally APK reverse engineering)
2. **Dependency ordering** ensures nothing is built before its prerequisites
3. **Each feature is built and tested in isolation** before the next one starts
4. **Fresh Claude Code sessions per build phase** prevent context bloat
5. **Regression tests** after each phase catch cross-feature breakage early
6. **Local-first architecture** means every feature works with local data - no backend complexity during build

## Project Structure (after running)

```
your-project/
├── .claude/commands/clone.md    # /clone slash command
├── .clone-kit/
│   ├── phases/                  # Phase instruction files
│   │   ├── 01-research.md
│   │   ├── 02-decompile.md
│   │   ├── 03-feature-map.md
│   │   ├── 04-scaffold.md
│   │   ├── 05-build-loop.md
│   │   └── 06-integration.md
│   └── pipeline.sh             # Build runner script
├── config.json                  # Generated by /clone
├── progress.json                # Auto-tracked state
├── research/                    # Phase 1 output
├── analysis/                    # Phase 2 output (if APK)
├── feature-map.json             # Phase 3 output
├── build-queue.json             # Phase 3 output
├── test-results.json            # Phase 5 output
├── screenshots/                 # MCP test screenshots
└── src/                         # Your app
```

## Configuration

`config.json` is generated by the `/clone` command. You can also create it manually:

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
    "tech_stack": "react-native-expo",
    "language": "typescript",
    "local_first": true,
    "platform_target": "android",
    "excluded_features": [],
    "tier_to_clone": "free"
  }
}
```

### Supported tech stacks

- `react-native-expo` (TypeScript) - default
- `flutter` (Dart)
- `android-native` (Kotlin)
- `ios-native` (Swift)

## Troubleshooting

**Pipeline stopped mid-build:** Just run `./clone-kit/pipeline.sh` again. It resumes from the last completed phase.

**Feature X failing after 3 retries:** The build loop defers it to Phase 6 (integration). Check `test-results.json` for details.

**Context getting bloated:** Each build phase runs as a separate `claude -p` session. If a single phase is too large, the phase instructions tell Claude to use subagents via the Task tool.

**Want to change tech stack:** Re-run from Phase 4. Research and feature map data (Phases 1-3) are stack-agnostic and reusable. Run `./clone-kit/pipeline.sh reset` then `./clone-kit/pipeline.sh`.

**No mobile MCP / emulator:** The pipeline still works - it falls back to build-only verification (no crashes, no lint errors) instead of visual MCP testing. Results won't be as thorough.

## Contributing

PRs welcome. The main areas to improve:

- **Phase templates** (`templates/phases/`) - better prompts, more edge case handling
- **Tech stack support** - framework-specific scaffold instructions
- **Testing protocols** - more thorough MCP test sequences
- **Multi-agent support** - adapting the slash command for Copilot, Cursor, Gemini CLI

## License

MIT
