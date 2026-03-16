# Phase 2: APK Decompilation & Analysis

## Goal

Extract data models, screen structure, API endpoints, navigation graph, and local storage schemas from the decompiled app code.

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

- `analysis/data-models.json`
- `analysis/screens.json`
- `analysis/api-endpoints.json`
- `analysis/local-storage.json`
- `analysis/navigation-graph.json`
- `analysis/third-party-sdks.json`
- `progress.json` updated

## Instructions

### Step 1: Data Models

**Where to look:**
- Packages: `model/`, `data/`, `entity/`, `domain/`, `dto/`, `vo/`
- Annotations: `@Entity`, `@Parcelize`, `@Serializable`, `@SerializedName`
- Kotlin data classes, Java POJOs

**Extract:**
```json
{
  "models": [
    {
      "name": "ClassName",
      "package": "com.example.app.data.model",
      "fields": [
        { "name": "fieldName", "type": "Type", "nullable": false }
      ],
      "relationships": [
        { "target": "OtherModel", "type": "many_to_one", "field": "foreignKeyField" }
      ],
      "annotations": ["@Entity"]
    }
  ]
}
```

### Step 2: Screens & Navigation

**Where to look:**
- `AndroidManifest.xml` for Activities
- `res/navigation/` for nav graphs
- Fragment/Compose Screen classes
- Classes with `Screen`, `Activity`, `Fragment`, `Page`, `View` in name

**Extract:**
```json
{
  "screens": [
    {
      "name": "ScreenClassName",
      "type": "fragment | activity | composable",
      "layout": "layout_resource_name",
      "navigation_id": "nav_destination_id",
      "parent": "ParentActivity",
      "tab": "tab_name_if_applicable",
      "navigates_to": ["other_destination_ids"]
    }
  ]
}
```

### Step 3: API Endpoints

**Where to look:**
- Retrofit interfaces (`@GET`, `@POST`, `@PUT`, `@DELETE`)
- URL string constants, base URL configs
- Patterns: `"/api/"`, `"https://"`, `"v1/"`, `"v2/"`
- OkHttp interceptors for auth patterns

**Extract:**
```json
{
  "base_url": "https://api.example.com/",
  "auth_type": "bearer_token | api_key | none",
  "endpoints": [
    {
      "method": "POST",
      "path": "/resource",
      "request_body": "RequestTypeName",
      "response_body": "ResponseTypeName"
    }
  ]
}
```

### Step 4: Local Storage

**Where to look:**
- Room: `@Database`, `@Dao`, `@Entity`
- SharedPreferences key constants
- DataStore definitions
- File storage utilities

**Extract:**
```json
{
  "databases": [
    {
      "name": "DatabaseClassName",
      "version": 1,
      "tables": [
        { "name": "table_name", "entity": "EntityClass", "indices": ["indexed_columns"] }
      ]
    }
  ],
  "preferences": [
    { "key": "pref_key_name", "type": "Type", "default": "value" }
  ]
}
```

### Step 5: Navigation Graph

```json
{
  "entry_point": "start_screen",
  "graphs": [
    {
      "name": "main_nav",
      "tabs": [
        {
          "name": "tab_name",
          "start": "start_destination",
          "destinations": ["screen_ids"]
        }
      ]
    },
    {
      "name": "onboarding",
      "flow": ["step1", "step2", "step3"]
    }
  ]
}
```

### Step 6: Third-Party SDKs

**Look for imports/manifest entries from:** Firebase, Segment, Amplitude, Mixpanel, Braze, LaunchDarkly, Datadog, Sentry, Stripe, RevenueCat, AppsFlyer, Adjust, and similar.

```json
{
  "sdks": [
    { "name": "SDK Name", "package": "com.sdk.package", "purpose": "analytics | payments | etc" }
  ]
}
```

### Handling Obfuscation

If ProGuard/R8 obfuscated the code:
- `res/values/strings.xml` reveals feature/screen names
- `res/layout/` XML shows screen structure
- `res/navigation/` graphs are usually unobfuscated
- `@SerializedName` annotations survive obfuscation
- Third-party SDK packages are rarely obfuscated

## Completion

```
Phase 2 complete.
- [N] data models, [N] fields total
- [N] screens, [N] navigation graphs
- [N] API endpoints
- [N] DB tables, [N] preference keys
- [N] third-party SDKs

Next: "Read .clone-kit/phases/03-feature-map.md and execute it"
```
