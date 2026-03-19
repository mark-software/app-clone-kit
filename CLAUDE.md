# CLAUDE.md — app-clone-kit

## What This Project Is

app-clone-kit is a CLI tool that clones existing apps using AI-powered automation. Users install it into their project, run `/research-app-01 AppName` in Claude Code, and it researches the target app, builds a feature map, constructs a clean local-first implementation, and optionally connects a real backend with auth and offline-first sync.

This repo is the **toolkit itself** (templates, installer scripts) — not the generated app. The generated app lives in the user's project directory after installation.

## Project Structure

```
app-clone-kit/
├── bin/
│   ├── cli.sh              # CLI entry point (package.json "bin")
│   ├── install.sh           # Local installer — copies templates into target project
│   └── remote-install.sh    # Curl-pipe-bash installer — clones repo, runs install.sh
├── templates/
│   ├── commands/
│   │   ├── research-app-01.md        # /research-app-01 slash command
│   │   ├── build-app-locally-02.md   # /build-app-locally-02 slash command
│   │   └── connect-backend-03.md     # /connect-backend-03 slash command
│   ├── phases/
│   │   ├── 01-research.md            # Web research & feature inventory
│   │   ├── 02-decompile.md           # APK decompilation for feature discovery (optional)
│   │   ├── 03-feature-map.md         # Dependency-ordered feature map + build queue
│   │   ├── build.md                  # Consolidated build instructions (scaffold, build loop, integration)
│   │   └── connect-backend.md        # Backend connection, auth, offline-first sync
│   └── skills/
│       └── test-mobile-app/
│           └── SKILL.md     # /test-mobile-app skill for automated QA via mobile MCP
├── package.json             # v0.1.0, no runtime deps, no build step
├── README.md
├── LICENSE                  # MIT
└── .gitignore
```

## How It Works (Architecture)

The system has three stages:

### Stage 1: Research & Planning (interactive, single Claude session)
- User runs `/research-app-01 AppName` in Claude Code
- `templates/commands/research-app-01.md` orchestrates phases 1-3
- Phase 1: Web research → `research/feature-inventory.json`, `research/visual-design.json`, `research/screenshots/`
- Phase 2 (optional): APK decompilation → `analysis/*.json` (data models, screens, API surface, design tokens)
- Phase 3: Merge into `feature-map.json` + `build-queue.json`

### Stage 2: Local Build (single Claude session)
- User runs `/build-app-locally-02` in a new Claude Code session
- `templates/commands/build-app-locally-02.md` loads `templates/phases/build.md`
- Scaffold: Project init, all data models, navigation shell, shared components
- Build loop: Implement each feature, test with mobile MCP, regression test
- Integration: Fix deferred issues, cross-feature testing, UI polish
- Progress tracked in `progress.json`, test results in `test-results.json`

### Stage 3: Backend Connection (optional, single Claude session)
- User runs `/connect-backend-03` in a new Claude Code session
- `templates/commands/connect-backend-03.md` loads `templates/phases/connect-backend.md`
- API layer: Network client, backend provider SDK, API key management
- Auth: Login/signup screens, OAuth, session management, guarded navigation
- Offline-first sync: Repository pattern, sync queue, conflict resolution, connectivity monitoring
- Backend config stored in `config.json` under `backend_config`

### Key Design Decisions
- **Single session with 1M context** — keeps all research, analysis, and code in one place with no context loss
- **Feature discovery, not code copying** — decompilation is for understanding what to build
- **Visual design matching** — extracts design tokens and screenshots to replicate the look
- **Local-first architecture** — all features work with local data during build
- **Dependency ordering** — features built in phases, foundations first
- **Testing gates** — mobile MCP verification between features catches regressions early

## Installation Flow

When a user installs app-clone-kit into their project:

1. `remote-install.sh` → shallow clones this repo to `/tmp`, runs `install.sh`
2. `install.sh` copies into the user's project:
   - `/research-app-01`, `/build-app-locally-02`, and `/connect-backend-03` commands → `.claude/commands/`
   - Phase files (01, 02, 03, build.md, connect-backend.md) → `.clone-kit/phases/`
   - Skills → `.claude/skills/`
   - Updates `.gitignore` for generated artifacts
3. Optionally installs mobile MCP: `claude mcp add mobile-mcp -- npx -y @mobilenext/mobile-mcp@latest`
4. Supports `--global` flag to install commands to `~/.claude/commands/` instead

## Supported Tech Stacks

- `kmp-compose` (Kotlin, default) — Compose Multiplatform with SQLDelight, Koin, Ktor
- `react-native-expo` (TypeScript) — Expo with expo-router, expo-sqlite
- `flutter` (Dart) — sqflite, provider
- `android-native` (Kotlin) — Room, Navigation Component, Hilt
- `ios-native` (Swift) — SwiftData/CoreData, SwiftUI

## Key Files to Know When Making Changes

- **`templates/commands/research-app-01.md`** — The research experience. Controls the /research-app-01 workflow (research → questions → plan → handoff to /build-app-locally-02).
- **`templates/commands/build-app-locally-02.md`** — The local build experience. Loads build.md and runs the full build in a single session.
- **`templates/commands/connect-backend-03.md`** — The backend connection experience. Loads connect-backend.md and wires up auth + offline-first sync.
- **`templates/phases/*.md`** — The phase instruction files. Research phases (01-03) are orchestrated by research-app-01.md; build.md is loaded by build-app-locally-02.md; connect-backend.md is loaded by connect-backend-03.md.
- **`bin/install.sh`** — The installer. If you add new template files, update this to copy them.
- **`templates/skills/test-mobile-app/SKILL.md`** — The QA testing skill. Auto-generates test plans from `feature-map.json`.

## Generated Artifacts (in user's project, not this repo)

| File | Created by | Purpose |
|------|-----------|---------|
| `config.json` | /research-app-01, /connect-backend-03 | Target app info, user preferences, backend config |
| `research/feature-inventory.json` | Phase 1 | Discovered features with confidence levels |
| `research/visual-design.json` | Phase 1 | Color scheme, typography, layout patterns |
| `research/screenshots/` | Phase 1 | Reference screenshots from app stores/web |
| `analysis/*.json` | Phase 2 | Data models, screens, API surface, design tokens |
| `feature-map.json` | Phase 3 | Unified feature specs with screens, data, behaviors |
| `build-queue.json` | Phase 3 | Dependency-ordered build phases (2-4 features each) |
| `progress.json` | Build phase | Build state, resume support |
| `test-results.json` | Build phase | Per-feature test results and deferred issues |
| `screenshots/` | Build phase | MCP test screenshots |

## Development Notes

- **No build step** — this is a pure shell/markdown project. No compilation, no transpilation.
- **No runtime dependencies** — `package.json` has no `dependencies` or `devDependencies`.
- **No tests** — the project is template files and shell scripts. Testing happens in the user's generated app.

## Common Tasks

### Adding a new phase template
1. Create `templates/phases/NN-name.md` with Goal, Inputs, Outputs, Instructions, Completion sections
2. Update `bin/install.sh` to copy it
3. Update `README.md` with the new phase

### Modifying the /research-app-01 workflow
Edit `templates/commands/research-app-01.md`. The workflow steps are numbered and sequential. Keep status messages to 1-3 lines. Research aggressively — never ask the user for information that can be found via web search.

### Adding a new tech stack
1. Add initialization instructions to `templates/phases/build.md` scaffold section
2. Add framework detection to `templates/skills/test-mobile-app/SKILL.md` Phase 1 table
3. Update `README.md` supported stacks list
4. Update the config.json tech_stack options in `templates/commands/research-app-01.md` Step 3

### Adding a new skill
1. Create `templates/skills/<skill-name>/SKILL.md` with frontmatter (name, description, version)
2. The installer already globs `templates/skills/*/` and copies them to `.claude/skills/`
