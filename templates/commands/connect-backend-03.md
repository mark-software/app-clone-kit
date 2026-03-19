# /connect-backend-03 - Connect a backend to your locally-built app

## Prerequisites

Before connecting a backend, verify these files exist:
- `config.json` — if missing, tell the user: "No research found. Run `/research-app-01 <app name>` first."
- `feature-map.json` — if missing, same message.

Also verify the app builds and runs locally:
- Check for a project directory with source code (e.g., `src/`, `app/`, `composeApp/`, `lib/`)
- Attempt a build (`./gradlew assembleDebug`, `npx expo start`, `flutter build`, or equivalent based on `config.json` tech stack)
- If the app doesn't build, tell the user: "Your app needs to build locally first. Run `/build-app-locally-02` to build it."

If any check fails, stop. Do not proceed.

## Backend Configuration

Ask everything in a single message:

"App builds locally — ready to connect a backend.

4 quick questions:

1. Backend provider? (Supabase [default], Firebase, custom REST API, GraphQL endpoint, other)
2. Connection details? (project URL, API keys, or base URL — I'll store these in config.json)
3. Auth method? (email/password [default], Google OAuth, Apple Sign-In, magic link, or combo — e.g. 'email + Google')
4. Sync strategy? Offline-first is the default — local DB stays the source of truth, background sync to the server. Change this? (yes/no)

After this I work autonomously."

Save answers to `config.json` under `backend_config`:

```json
"backend_config": {
  "provider": "supabase",
  "project_url": "...",
  "api_key": "...",
  "auth_methods": ["email_password", "google_oauth"],
  "sync_strategy": "offline_first"
}
```

## Connect

Read `.clone-kit/phases/connect-backend.md` and execute it.
