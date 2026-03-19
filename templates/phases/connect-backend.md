# Connect Backend Phase: Add Real Backend to Local App

Wire a backend into the working local app. The local DB remains the source of truth — the backend syncs in the background.

## Section 1: Read Context

Before writing any code, read and internalize ALL of these:

1. `config.json` — tech stack, backend provider, auth methods, sync strategy
2. `feature-map.json` — every entity, screen, and behavior
3. Existing app code — understand the current data models, repositories, and navigation

Map out:
- Every data entity and its fields
- Every repository/DAO and its methods
- The navigation graph (which screens exist, which are auth-guarded)
- The current data flow (UI → repository → local DB)

## Section 2: API Layer Setup

### Step 1: Add network client

Based on tech stack in `config.json`:

- **kmp-compose**: Ktor client with content negotiation (JSON), logging interceptor
- **react-native-expo**: fetch wrapper or axios, with interceptors
- **flutter**: http or dio package, with interceptors
- **android-native**: Retrofit with OkHttp, Moshi/Gson converter
- **ios-native**: URLSession wrapper or Alamofire

### Step 2: Configure for backend provider

Based on `backend_config.provider`:

- **Supabase**: Install SDK (`io.github.jan-tennert.supabase` / `@supabase/supabase-js` / `supabase_flutter`), configure with project URL and anon key
- **Firebase**: Install Firebase SDK, add `google-services.json` / `GoogleService-Info.plist`, configure Firestore/RTDB + Auth
- **Custom REST**: Configure base URL, auth header injection, standard CRUD endpoint patterns
- **GraphQL**: Install GraphQL client (Apollo/graphql-request/graphql_flutter), configure endpoint and auth headers

### Step 3: API key management

- Store keys in a local config file that's gitignored (e.g., `local.properties`, `.env`, `env.dart`)
- Add the config file to `.gitignore`
- Create a `.env.example` or equivalent with placeholder values
- Never hardcode keys in source

## Section 3: Auth Implementation

### Step 1: Auth service

Create an auth service/manager that handles:
- Sign up (email/password, or provider-specific)
- Sign in
- Sign out
- Password reset / forgot password
- Token storage (secure storage — Keychain/EncryptedSharedPrefs/SecureStore)
- Session refresh (auto-refresh tokens before expiry)
- Auth state observation (stream/flow/listener for login state changes)

### Step 2: OAuth providers (if configured)

For each OAuth method in `backend_config.auth_methods`:
- **Google OAuth**: Configure Google Sign-In SDK, add client ID
- **Apple Sign-In**: Configure Sign in with Apple capability
- **Magic link**: Deep link / universal link handling for callback

### Step 3: Auth screens

Create or update screens:
- **Login screen**: email/password fields, OAuth buttons, "forgot password" link, "sign up" link
- **Sign up screen**: email/password/confirm, OAuth buttons, "already have account" link
- **Forgot password screen**: email field, submit, success message

Match the app's existing design system (colors, typography, spacing).

### Step 4: Auth-guarded navigation

- Wrap the main navigation in an auth check
- If not authenticated → show login screen
- If authenticated → show main app
- Handle loading state while checking auth (splash/loading screen)
- Persist auth state so the app doesn't require login on every launch

## Section 4: Backend Data Mapping

For each entity in `feature-map.json`:

### Step 1: Create API DTOs

- Define API request/response models (may differ from local DB models)
- Create mappers: API DTO ↔ local model
- Handle field name differences (snake_case API vs camelCase local, etc.)

### Step 2: Create API service per entity

Each service provides:
- `fetchAll()` — GET list
- `fetchById(id)` — GET single
- `create(entity)` — POST
- `update(entity)` — PUT/PATCH
- `delete(id)` — DELETE

Adapt to backend provider:
- **Supabase**: Use SDK's `from("table").select()` / `.insert()` / `.update()` / `.delete()`
- **Firebase**: Firestore collection references with `get()` / `add()` / `set()` / `delete()`
- **REST**: Standard HTTP methods to `/api/entity` endpoints
- **GraphQL**: Queries and mutations per entity

## Section 5: Offline-First Sync

This is the core architecture. The local DB is always the source of truth.

### Step 1: Repository pattern

Refactor each repository to:
1. **Reads**: Always read from local DB (instant, works offline)
2. **Writes**: Write to local DB immediately, then queue a sync operation
3. **Sync**: Background process pushes local changes to server and pulls remote changes

### Step 2: Sync queue

Create a sync manager that:
- Maintains a queue of pending operations (create/update/delete + entity + data)
- Persists the queue to local DB (survives app restart)
- Processes queue when online
- Retries failed operations with exponential backoff (1s, 2s, 4s, 8s, max 60s)
- Deduplicates: if the same entity is updated multiple times while offline, send only the latest

### Step 3: Conflict resolution

Default strategy: **last-write-wins** using timestamps.

- Each entity gets an `updatedAt` timestamp (local and remote)
- On sync, compare timestamps — newer write wins
- If the server has a newer version, update local
- If local has a newer version, push to server
- Log conflicts for debugging (don't surface to user unless data loss occurs)

### Step 4: Connectivity monitoring

- Listen for network state changes
- When online: process sync queue, then pull latest from server
- When offline: all operations work normally against local DB
- Expose connection state to UI (for sync indicators)

### Step 5: Background sync

- Periodic sync interval (configurable, default 5 minutes when app is active)
- Immediate sync on significant writes (create, delete)
- Pull-to-refresh triggers immediate sync
- Sync on app foreground (if last sync was > 1 minute ago)

## Section 6: Migration

Replace direct database access patterns with the new repository layer:

1. **Find all direct DB calls** in screens/ViewModels/controllers
2. **Route through repository** instead — the repository handles local + remote
3. **Remove seed data dependency** — first sync from server populates data (keep seed data as fallback for offline-first launch)
4. **Update data observation** — screens still observe local DB (Flow/StateFlow/Stream/LiveData), repository handles sync in the background
5. **Add user scoping** — filter data by authenticated user ID (each user sees only their data)

## Section 7: Testing

Test each integration point:

### Auth flow
1. Sign up with email/password — account created, user lands in main app
2. Sign out — returns to login screen
3. Sign in — returns to main app with user's data
4. Password reset — email sent (verify no crash, correct feedback message)
5. OAuth sign in (if configured) — opens provider, returns to app authenticated
6. Kill app and reopen — still authenticated (session persisted)

### CRUD sync
For each entity:
1. Create locally → verify it appears on server
2. Edit locally → verify server updates
3. Delete locally → verify server reflects deletion
4. Create on server (via dashboard/API) → pull-to-refresh → verify it appears locally

### Offline mode
1. Enable airplane mode
2. Create/edit/delete entries — all operations work normally
3. Disable airplane mode
4. Verify pending changes sync to server
5. Verify no data loss or duplication

### Conflict handling
1. Edit an entity locally (airplane mode)
2. Edit same entity on server
3. Go online — verify last-write-wins resolves correctly

If a test fails after 3 fix attempts, note it and move on. Fix during polish.

## Section 8: Polish

### Loading states
- Network operations show loading indicators (not blocking — the UI stays interactive)
- First sync shows a progress indicator if it takes > 1 second
- Don't show loading for local reads (they're instant)

### Error states
- Network errors: show non-blocking error message (toast/snackbar), retry button
- Auth errors (expired token): auto-refresh, if that fails → redirect to login
- Server errors (5xx): "Something went wrong, try again" with retry
- Never show raw error messages or stack traces to the user

### Sync indicators
- Subtle sync status in the UI (e.g., small icon in toolbar, or in settings)
- "Last synced: X minutes ago" somewhere accessible
- Pending changes count (if offline with queued operations)
- Pull-to-refresh on list screens triggers sync

### Security
- API keys in gitignored config only
- Auth tokens in secure storage (Keychain / EncryptedSharedPrefs / SecureStore)
- No sensitive data in logs
- HTTPS only (enforce in network client config)

## Section 9: Update CLAUDE.md

The app now has a backend, auth, and offline-first sync. Update `CLAUDE.md` so future Claude Code sessions know about this architecture.

**Read the existing `CLAUDE.md` first.** Preserve everything — user-written instructions, project conventions, all sections from the build phase. Merge the sections below into the existing file. Do not overwrite anything already there.

Read these files for context:
- `config.json` — `backend_config` (provider, auth methods, sync strategy)
- The auth service, sync manager, and API layer code you just wrote

Add or update these sections in `CLAUDE.md`:

1. **Backend & API** — Provider name, base URL pattern, API key management approach (where keys live, how they're loaded), network client library
2. **Authentication** — Auth methods (email/password, OAuth providers), auth service location, token storage approach (Keychain/EncryptedSharedPrefs/SecureStore), session refresh strategy
3. **Offline-First Sync** — Architecture overview (local DB is source of truth, background sync to server), sync queue location and persistence, conflict resolution strategy (last-write-wins with timestamps), connectivity monitoring approach, sync triggers (periodic, on-write, pull-to-refresh, app foreground)
4. **Environment Setup** — Required API keys and where to set them, `.env.example` reference, provider dashboard links for key management
5. **Known Issues** — Append any backend-related deferred issues to the existing Known Issues section

The updated `CLAUDE.md` should read as documentation for a complete app with a live backend, not a migration log.

## Completion

```
Backend connected.

- Provider: [provider]
- Auth: [methods]
- Sync: offline-first (local DB → background sync)
- Entities synced: [count]
- Deferred issues: [list if any, or "none"]

Test it: sign up, add some data, enable airplane mode, make changes,
go back online — everything should sync.
```
