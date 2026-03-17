# Phase 1: Research & Discovery

## Goal

Build a comprehensive feature inventory of the target app using only public sources. No manual app walkthrough required. The goal is to understand *what* the app does so we can build our own clean implementation — likely better than the original.

## Inputs

- `config.json` - target app name, URLs, configuration

## Outputs

- `research/feature-inventory.json`
- `research/visual-design.json`
- `research/screenshots/` (gathered reference screenshots)
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

### Step 3: Gather visual references

Autonomously gather screenshots of the app's UI — do NOT ask the user unless you can't find enough.

**Where to find screenshots:**
1. Play Store and App Store listing pages — download all screenshot images (typically 5-8 per listing)
2. Web search for "[app name] screenshots", "[app name] app review" — download screenshots from review articles, tech blogs, Product Hunt pages
3. YouTube search for "[app name] tutorial" or "[app name] review" — grab thumbnails that show the app UI
4. The app's marketing website — download any product screenshots or UI mockups

Save all gathered screenshots to `research/screenshots/`.

**If fewer than 3 screenshots were found:** Ask the user: "I could only find [N] screenshots of [app name]. Do you have any screenshots you can provide? (folder path) This will significantly improve UI fidelity." Save user-provided screenshots to `research/screenshots/user-provided/`.

**If no screenshots at all:** Ask the user for screenshots. If they don't have any, proceed with best-effort design based on app store descriptions and feature analysis — note this limitation in `progress.json`.

**Analyze screenshots and create `research/visual-design.json`:**

```json
{
  "color_scheme": {
    "primary": "#hex",
    "secondary": "#hex",
    "background": "#hex",
    "surface": "#hex",
    "text_primary": "#hex",
    "text_secondary": "#hex",
    "accent": "#hex"
  },
  "typography_style": "modern-sans | classic-serif | rounded | geometric | etc",
  "layout_patterns": ["bottom-nav-tabs", "cards-in-list", "fab-for-add"],
  "spacing_density": "compact | comfortable | spacious",
  "corner_style": "sharp | slightly-rounded | very-rounded | pill",
  "elevation_style": "flat | subtle-shadow | prominent-shadow | material",
  "icon_style": "outlined | filled | rounded | custom",
  "overall_feel": "brief description of the visual identity",
  "screenshots_catalog": [
    { "file": "path", "screen": "what screen this shows", "notes": "key visual elements" }
  ]
}
```

### Step 4: Generate sources log

Create `research/sources.md` listing every URL consulted with a one-line summary of what was learned from each.

### Step 5: Update progress

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
- Gathered [N] reference screenshots
- Consulted [N] sources
- [N] high confidence, [N] medium, [N] low

REVIEW (~5 min): Skim research/feature-inventory.json
- Add features you know about from personal use
- Remove features you don't want
- Flag anything wrong

When ready: "Read .clone-kit/phases/02-decompile.md and execute it"
(Or skip to Phase 3 if no APK available)
```
