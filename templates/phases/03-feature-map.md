# Phase 3: Feature Map Generation

## Goal

Merge research and decompilation discoveries into a unified, dependency-ordered feature map and build queue. All feature specs should describe *what to build* in our own clean implementation — not replicate the original app's code or architecture.

## Inputs

- `research/feature-inventory.json` (Phase 1)
- `analysis/*.json` (Phase 2, if available)
- `config.json`

## Outputs

- `feature-map.json`
- `build-queue.json`
- `progress.json` updated

## Instructions

### Step 1: Merge and reconcile

Cross-reference research with decompilation discoveries:
- Found in both: highest confidence, decompilation confirms feature exists and clarifies scope
- Research only: include, note implementation details will be designed fresh
- Decompilation only: include, mark `discovered_via_decompilation` (hidden features not marketed publicly)
- Use clean, descriptive names for our implementation — don't carry over the original app's naming conventions
- Design our own data models and architecture informed by what we learned, not copied from the source

### Step 2: Generate unified feature map

Each entry must be self-contained - buildable from this entry alone:

```json
{
  "features": [
    {
      "id": "feature_snake_case_id",
      "name": "Feature Name",
      "category": "category",
      "tier": "free | plus | premium",
      "complexity": "low | medium | high",
      "description": "What it does from user perspective",

      "user_stories": [
        "As a user, I can [action] so that [benefit]"
      ],

      "data_model": {
        "entities": ["EntityName"],
        "fields": {
          "EntityName": [
            { "name": "field", "type": "type", "required": true }
          ]
        }
      },

      "screens": [
        {
          "name": "ScreenName",
          "ui_elements": ["element descriptions"],
          "states": ["state1", "state2", "empty", "loading", "error"]
        }
      ],

      "behaviors": [
        "Specific behavior or business rule"
      ],

      "dependencies": ["feature_ids_this_depends_on"],
      "dependents": ["feature_ids_that_depend_on_this"],
      "local_data_only": true
    }
  ]
}
```

### Step 3: Generate build queue

Group into sequential phases of 2-4 features each.

**Ordering rules:**
1. Infrastructure first (shared components, data layer, navigation)
2. Dependencies before dependents
3. Core features before secondary features
4. CRUD/tracking before reporting/analytics
5. Simple before complex
6. Free tier before paid tier
7. Features within a phase should be independent of each other

```json
{
  "phases": [
    {
      "phase": 0,
      "name": "Foundation",
      "description": "Data layer, shared components, navigation shell",
      "features": ["data_layer", "shared_components", "navigation_shell"],
      "estimated_complexity": "high",
      "human_review": false
    }
  ],
  "total_features": 0,
  "total_phases": 0
}
```

### Step 4: Validate

Before finishing, verify:
- No circular dependencies
- Every dependency appears in an earlier phase
- No phase exceeds 4 features
- `local_data_only: true` features don't reference API endpoints
- Excluded features from config.json are omitted

## Completion

```
Phase 3 complete.
- [N] features in [N] build phases
- Dependency graph validated

REVIEW (~5 min): Check build-queue.json
- Phase ordering sensible?
- Want to remove anything?

Next: "Read .clone-kit/phases/04-scaffold.md and execute it"
```
