# CLAUDE.md — app-clone-kit

## What This Project Is

app-clone-kit is a CLI tool that clones existing apps using AI-powered automation. Users install it into their project, run `/clone AppName` in Claude Code, and it researches the target app, builds a feature map, then constructs a clean implementation phase-by-phase with automated testing between steps.

This repo is the **toolkit itself** (templates, installer scripts, pipeline runner) — not the generated app. The generated app lives in the user's project directory after installation.

## Project Structure

```
app-clone-kit/
├── bin/
│   ├── cli.sh              # CLI entry point (package.json "bin")
│   ├── install.sh           # Local installer — copies templates into target project
│   └── remote-install.sh    # Curl-pipe-bash installer — clones repo, runs install.sh
├── templates/
│   ├── commands/
│   │   └── clone.md         # The /clone slash command (installed to .claude/commands/)
│   ├── phases/
│   │   ├── 01-research.md   # Web research & feature inventory
│   │   ├── 02-decompile.md  # APK decompilation for feature discovery (optional)
│   │   ├── 03-feature-map.md # Dependency-ordered feature map + build queue
│   │   ├── 04-scaffold.md   # Project init, data layer, navigation shell
│   │   ├── 05-build-loop.md # Iterative build: implement, test, fix per feature
│   │   └── 06-integration.md # Cross-feature testing, UI polish, final walkthrough
│   ├── pipeline.sh          # Build runner — orchestrates phases 4-6 as separate Claude sessions
│   └── skills/
│       └── test-mobile-app/
│           └── SKILL.md     # /test-mobile-app skill for automated QA via mobile MCP
├── package.json             # v0.1.0, no runtime deps, no build step
├── README.md
├── LICENSE                  # MIT
└── .gitignore
```

## How It Works (Architecture)

The system has two stages:

### Stage 1: Research & Planning (interactive, single Claude session)
- User runs `/clone AppName` in Claude Code
- `templates/commands/clone.md` orchestrates phases 1-3
- Phase 1: Web research → `research/feature-inventory.json`, `research/visual-design.json`, `research/screenshots/`
- Phase 2 (optional): APK decompilation → `analysis/*.json` (data models, screens, API surface, design tokens)
- Phase 3: Merge into `feature-map.json` + `build-queue.json`

### Stage 2: Build (automated, one Claude session per build phase)
- User runs `.clone-kit/pipeline.sh`
- `templates/pipeline.sh` orchestrates phases 4-6
- Phase 4: Scaffold project (tech stack init, all data models, navigation, shared components)
- Phase 5: Build loop (implement each feature, test with mobile MCP, regression test)
- Phase 6: Integration (fix deferred issues, cross-feature testing, UI polish)
- Progress tracked in `progress.json`, test results in `test-results.json`

### Key Design Decisions
- **Separate Claude sessions per build phase** — prevents context bloat
- **Feature discovery, not code copying** — decompilation is for understanding what to build
- **Visual design matching** — extracts design tokens and screenshots to replicate the look
- **Local-first architecture** — all features work with local data during build
- **Dependency ordering** — features built in phases, foundations first
- **Testing gates** — mobile MCP verification between phases catches regressions early

## Installation Flow

When a user installs app-clone-kit into their project:

1. `remote-install.sh` → shallow clones this repo to `/tmp`, runs `install.sh`
2. `install.sh` copies into the user's project:
   - `/clone` command → `.claude/commands/clone.md`
   - Phase files → `.clone-kit/phases/`
   - Pipeline script → `.clone-kit/pipeline.sh`
   - Skills → `.claude/skills/`
   - Updates `.gitignore` for generated artifacts
3. Optionally installs mobile MCP: `claude mcp add mobile-mcp -- npx -y @mobilenext/mobile-mcp@latest`
4. Supports `--global` flag to install `/clone` to `~/.claude/commands/` instead

## Supported Tech Stacks

- `kmp-compose` (Kotlin, default) — Compose Multiplatform with SQLDelight, Koin, Ktor
- `react-native-expo` (TypeScript) — Expo with expo-router, expo-sqlite
- `flutter` (Dart) — sqflite, provider
- `android-native` (Kotlin) — Room, Navigation Component, Hilt
- `ios-native` (Swift) — SwiftData/CoreData, SwiftUI

## Key Files to Know When Making Changes

- **`templates/commands/clone.md`** — The main user-facing experience. Controls the /clone slash command workflow (research → questions → plan → handoff).
- **`templates/phases/*.md`** — The phase instruction files. Each is a self-contained prompt that Claude follows in a separate session.
- **`templates/pipeline.sh`** — The bash build runner. Manages session orchestration, progress tracking, resume logic.
- **`bin/install.sh`** — The installer. If you add new template files, update this to copy them.
- **`templates/skills/test-mobile-app/SKILL.md`** — The QA testing skill. Auto-generates test plans from `feature-map.json`.

## Generated Artifacts (in user's project, not this repo)

| File | Created by | Purpose |
|------|-----------|---------|
| `config.json` | Phase 1 (clone.md) | Target app info + user preferences |
| `research/feature-inventory.json` | Phase 1 | Discovered features with confidence levels |
| `research/visual-design.json` | Phase 1 | Color scheme, typography, layout patterns |
| `research/screenshots/` | Phase 1 | Reference screenshots from app stores/web |
| `analysis/*.json` | Phase 2 | Data models, screens, API surface, design tokens |
| `feature-map.json` | Phase 3 | Unified feature specs with screens, data, behaviors |
| `build-queue.json` | Phase 3 | Dependency-ordered build phases (2-4 features each) |
| `progress.json` | Phases 4-6 | Pipeline state, resume support |
| `test-results.json` | Phase 5-6 | Per-feature test results and deferred issues |
| `screenshots/` | Phase 5-6 | MCP test screenshots |

## Development Notes

- **No build step** — this is a pure shell/markdown project. No compilation, no transpilation.
- **No runtime dependencies** — `package.json` has no `dependencies` or `devDependencies`.
- **No tests** — the project is template files and shell scripts. Testing happens in the user's generated app.
- **Pipeline requires Python 3** — `pipeline.sh` uses `python3 -c` for JSON manipulation.
- **Pipeline requires Claude Code CLI** — `claude -p` is used to run headless Claude sessions.

## Common Tasks

### Adding a new phase template
1. Create `templates/phases/NN-name.md` with Goal, Inputs, Outputs, Instructions, Completion sections
2. Update `bin/install.sh` to copy it (the glob `"$TEMPLATE_DIR/phases/"*.md` handles this automatically)
3. Update `templates/pipeline.sh` if it needs orchestration
4. Update `README.md` with the new phase

### Modifying the /clone workflow
Edit `templates/commands/clone.md`. The workflow steps are numbered and sequential. Keep status messages to 1-3 lines. Research aggressively — never ask the user for information that can be found via web search.

### Adding a new tech stack
1. Add initialization instructions to `templates/phases/04-scaffold.md` Step 1
2. Add framework detection to `templates/skills/test-mobile-app/SKILL.md` Phase 1 table
3. Update `README.md` supported stacks list
4. Update the config.json tech_stack options in `templates/commands/clone.md` Step 3

### Adding a new skill
1. Create `templates/skills/<skill-name>/SKILL.md` with frontmatter (name, description, version)
2. The installer already globs `templates/skills/*/` and copies them to `.claude/skills/`
