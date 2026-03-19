# /build-app - Build the app from existing research

## Prerequisites

Before building, verify these files exist:
- `config.json` — if missing, tell the user: "No research found. Run `/research-app <app name>` first."
- `feature-map.json` — if missing, same message.
- `build-queue.json` — if missing, same message.

If any are missing, stop. Do not proceed.

## Build

Read `.clone-kit/phases/build.md` and execute it.
