# Phase 1: Research & Discovery

## Goal

Build a comprehensive feature inventory of the target app using only public sources. No manual app walkthrough required. The goal is to understand *what* the app does so we can build our own clean implementation — likely better than the original.

## Inputs

- `config.json` - target app name, URLs, configuration

## Outputs

- `research/feature-inventory.json`
- `research/sources.md`
- `progress.json` updated

## Instructions

### Step 1: Gather from all source types

Search and read the following in priority order:

**Priority 1 - Official listings:**
- Play Store and App Store full descriptions and feature bullets
- App's marketing website - every feature page, pricing page, comparison page
- App's help center / knowledge base (Zendesk, Intercom, /help, /support, /faq)

**Priority 2 - Third-party analysis:**
- "best [category] apps" comparison articles that include this app
- Tech review writeups (TechCrunch, Product Hunt, etc.)
- YouTube video titles/descriptions for "[app name] tutorial" and "[app name] review"

**Priority 3 - User-generated:**
- Play Store and App Store reviews mentioning specific features
- Reddit threads about the app
- Niche community discussions

### Step 2: Structure the inventory

For every feature discovered:

```json
{
  "features": [
    {
      "id": "unique_snake_case_id",
      "name": "Human-Readable Feature Name",
      "category": "category_name",
      "description": "What this feature does from the user's perspective",
      "sub_features": [
        "Specific capability within this feature",
        "Another capability"
      ],
      "tier": "free | plus | premium",
      "data_involved": ["entity_names", "this_feature_reads_or_writes"],
      "related_features": ["other_feature_ids", "that_interact_with_this"],
      "source": "where_this_was_discovered",
      "confidence": "high | medium | low"
    }
  ]
}
```

**Confidence levels:**
- `high` - explicitly described in official docs or app listing
- `medium` - mentioned in reviews or third-party articles
- `low` - inferred from screenshots or indirect mentions

### Step 3: Generate sources log

Create `research/sources.md` listing every URL consulted with a one-line summary of what was learned from each.

### Step 4: Update progress

Write to `progress.json`:
```json
{
  "current_step": "phase_1",
  "phase_1_status": "complete",
  "phase_1_features_discovered": 0,
  "phase_1_sources_consulted": 0,
  "phase_1_timestamp": ""
}
```

## Completion

Report to user:

```
Phase 1 complete.
- Discovered [N] features across [N] categories
- Consulted [N] sources
- [N] high confidence, [N] medium, [N] low

REVIEW (~5 min): Skim research/feature-inventory.json
- Add features you know about from personal use
- Remove features you don't want
- Flag anything wrong

When ready: "Read .clone-kit/phases/02-decompile.md and execute it"
(Or skip to Phase 3 if no APK available)
```
