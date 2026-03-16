# Phase 2: APK Decompilation & Feature Discovery

## Goal

Discover the target app's feature surface, screen structure, navigation patterns, data entities, and integration points by analyzing decompiled code. This phase is purely for **understanding what to build and how things work** — not for copying code, styles, or implementation details verbatim. We use these insights to inform our own clean implementation, which we can likely build better.

## Prerequisites

User must provide a decompiled APK. If they haven't done this:

```bash
# Download APK from APKPure/APKMirror, or pull from device:
adb shell pm list packages | grep -i [app_name]
adb shell pm path com.example.app
adb pull /data/app/com.example.app-xxx/base.apk ./target.apk

# Decompile:
jadx -d ./decompiled target.apk
```

If the user wants to skip this phase, proceed to Phase 3 with research data only.

## Inputs

- Decompiled APK directory (path from config.json or user)
- `config.json`

## Outputs

All outputs describe *what* the app does, not *how* to replicate its code:

- `analysis/data-models.json` — discovered entity types and their relationships
- `analysis/screens.json` — screen inventory and purpose
- `analysis/api-endpoints.json` — API surface area and patterns
- `analysis/local-storage.json` — local data strategy
- `analysis/navigation-graph.json` — user flow structure
- `analysis/third-party-sdks.json` — third-party capabilities used
- `progress.json` updated

## Important: Feature Discovery, Not Code Copying

The purpose of decompilation is to answer: **"What does this app do?"** — not "How is this app coded?"

- Discover entity types and relationships, but design your own data models
- Identify screens and navigation flows, but design your own UI
- Note API patterns and endpoints, but build your own API layer
- Understand storage strategies, but implement your own approach
- The original code may be poorly structured, over-engineered, or legacy — we can build it better

**Do NOT:** copy class names, field names, package structure, code patterns, or architectural decisions verbatim. Use the decompiled code as a reference to understand features and behaviors, then discard it.

## Instructions

### Step 1: Discover Data Entities

**Where to look:**
- Packages: `model/`, `data/`, `entity/`, `domain/`, `dto/`, `vo/`
- Annotations: `@Entity`, `@Parcelize`, `@Serializable`, `@SerializedName`
- Kotlin data classes, Java POJOs

**Discover and record what kinds of data the app works with — entity types, their fields, and relationships. Use descriptive names that make sense for our implementation, not the original class names.**

```json
{
  "models": [
    {
      "discovered_name": "OriginalClassName",
      "our_name": "CleanDescriptiveName",
      "purpose": "What this entity represents in the app",
      "fields": [
        { "name": "descriptive_field_name", "type": "Type", "nullable": false, "purpose": "what this field is for" }
      ],
      "relationships": [
        { "target": "OtherEntity", "type": "many_to_one", "purpose": "why these are related" }
      ]
    }
  ]
}
```

### Step 2: Discover Screens & Navigation

**Where to look:**
- `AndroidManifest.xml` for Activities
- `res/navigation/` for nav graphs
- Fragment/Compose Screen classes
- Classes with `Screen`, `Activity`, `Fragment`, `Page`, `View` in name

**Map out what screens exist and how users flow between them. Focus on the user experience, not the implementation.**

```json
{
  "screens": [
    {
      "purpose": "What this screen lets the user do",
      "type": "list | detail | form | dashboard | settings",
      "section": "Which app section this belongs to",
      "navigates_to": ["other screen purposes"],
      "key_elements": ["what the user sees and interacts with"]
    }
  ]
}
```

### Step 3: Discover API Surface

**Where to look:**
- Retrofit interfaces (`@GET`, `@POST`, `@PUT`, `@DELETE`)
- URL string constants, base URL configs
- Patterns: `"/api/"`, `"https://"`, `"v1/"`, `"v2/"`
- OkHttp interceptors for auth patterns

**Understand what resources the app works with remotely and what auth pattern it uses. We'll design our own API layer.**

```json
{
  "auth_pattern": "bearer_token | api_key | none",
  "resources": [
    {
      "resource": "descriptive resource name",
      "operations": ["create", "read", "update", "delete", "list"],
      "notes": "anything notable about how this resource is used"
    }
  ]
}
```

### Step 4: Discover Local Storage Strategy

**Where to look:**
- Room: `@Database`, `@Dao`, `@Entity`
- SharedPreferences key constants
- DataStore definitions
- File storage utilities

**Understand what data is stored locally, what's cached, and what preferences the app tracks.**

```json
{
  "storage_strategy": {
    "primary_db": true,
    "entity_count": 0,
    "caching_approach": "description of caching strategy",
    "user_preferences": [
      { "category": "what kind of preference", "examples": ["specific settings"] }
    ]
  }
}
```

### Step 5: Discover Navigation Graph

**Map the high-level user flows — how sections connect, what the entry points are, and what onboarding looks like.**

```json
{
  "entry_point": "what the user sees first",
  "main_sections": [
    {
      "name": "section purpose",
      "screens": ["screen purposes in flow order"]
    }
  ],
  "onboarding_flow": ["step descriptions"],
  "modal_flows": ["flows that overlay the main navigation"]
}
```

### Step 6: Discover Third-Party Capabilities

**Look for imports/manifest entries from:** Firebase, Segment, Amplitude, Mixpanel, Braze, LaunchDarkly, Datadog, Sentry, Stripe, RevenueCat, AppsFlyer, Adjust, and similar.

**Identify what capabilities the app gets from third parties so we can decide which we need (and potentially choose better alternatives).**

```json
{
  "capabilities": [
    { "capability": "analytics | payments | crash_reporting | etc", "sdk_used": "SDK Name", "our_approach": "what we might use instead or whether we need this" }
  ]
}
```

### Handling Obfuscation

If ProGuard/R8 obfuscated the code, focus on the unobfuscated surfaces to understand features:
- `res/values/strings.xml` reveals feature/screen names and user-facing text
- `res/layout/` XML shows screen structure and UI elements
- `res/navigation/` graphs are usually unobfuscated — great for understanding user flows
- `@SerializedName` annotations survive obfuscation — reveals real data field names
- Third-party SDK packages are rarely obfuscated — reveals what capabilities are used

Remember: obfuscation actually makes feature discovery easier in some ways, because it forces you to focus on *what* the app does (resource files, manifest, navigation) rather than getting lost in implementation details.

## Completion

```
Phase 2 (Feature Discovery) complete.
- [N] data entities discovered
- [N] screens and [N] navigation flows mapped
- [N] API resources identified
- Local storage strategy documented
- [N] third-party capabilities cataloged

These discoveries will inform our own clean implementation in later phases.

Next: "Read .clone-kit/phases/03-feature-map.md and execute it"
```
