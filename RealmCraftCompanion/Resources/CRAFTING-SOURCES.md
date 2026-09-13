# Crafting catalog · development candidate 1.7.40

The offline workspace contains 1,206 existing Companion name-catalog entries and 821 comparison recipe variants for 588 outputs. Another 15 ingredients retain their Minecraft names without a Companion numeric-ID mapping. The name register includes unverified comparison entries and block states; neither its size nor a matching name establishes the complete RealmCraft item set. No recipe is marked as verified in RealmCraft VR.

## Obtaining guides · 1.7.51

`CraftingAcquisition.json` is the authoritative authored bilingual resource, loaded beside the generated recipe catalog. Its 22 guides explicitly map to 170 entries. Stable guide/step/source IDs preserve translation identities. Prerequisite links, paired prose, unique coverage and HTTPS attribution are validated on load. A recipe-less entry with a guide is shown as explained; the remaining 458 entries stay open. The existing 821 recipe variants and their ingredient arithmetic are unchanged.

Guides distinguish acquisition from grid recipes: fill a bucket, milk a cow, collect a live fish, cool lava, harden powder, harvest or strip wood, collect leaf/sapling drops, plant a pot, gather creature loot or use an offered Creative item. The lava guide includes source-versus-flow targeting, use-versus-attack, spare inventory space, empty-container reuse, fire risk and the RealmCraft wiki's Creative exception. No controller button, infinite-lava farm, guaranteed random yield or complete Quest content list is invented.

Each guide records its source and field scope. Official Mojang articles establish Minecraft comparisons. Original Java 1.16.5 loot tables from the same checksum-pinned archive establish the specified ordinary drops and leaf-tool conditions, not RealmCraft tool tiers. RealmCraft wiki evidence for Creative buckets, obsidian and spawn eggs is labeled separately; indexed retrieval is not a device test. Copy/export preserves sources and caveats. The original client-JAR link is explicitly labeled as a download.

The local filter popover lives beside item search. Category, station and one coverage choice combine; reset inside the popover preserves the query, while list reset clears both. Obtaining routes also appear in deterministic conversation retrieval. They do not manufacture crafting recipes, fixed yields or recursive material-plan transitions. See the release backlog for remaining evidence and platform acceptance.

## Sources and field scope

- **Minecraft Java 1.16.5 original recipe data:** [Mojang client archive](https://piston-data.mojang.com/v1/objects/37fd3c903861eeff3bc24b71eed48f828b5269c8/client.jar), SHA-1 `37fd3c903861eeff3bc24b71eed48f828b5269c8`. The importer verifies the archive before reading it. Each normalized recipe records its original `data/minecraft/recipes/*.json` path and SHA-256. Tags expand recursively from the same archive. Only numerical recipe facts, item identifiers and arrangements are normalized; no game executable, artwork, sounds, textures or source archive are bundled.
- **[RealmCraft Game Wiki · Crafting](https://realmcraftgame.fandom.com/wiki/Crafting)**, checked 2026-09-11 through the indexed page: describes inventory 2 × 2, crafting-table 3 × 3, recipe selection, automatic ingredient arrangement and the craft button. This supports the general wiki-interface instructions, not Quest controller input or every reference recipe.
- **[RealmCraft Game Wiki · Crafting table](https://realmcraftgame.fandom.com/wiki/Crafting_table)**, checked 2026-09-11 through the indexed page: explicitly lists four planks and inventory crafting. The UI attaches this evidence to those fields only.
- **[RealmCraft Game Wiki · Enchantment Table](https://realmcraftgame.fandom.com/wiki/Enchantment_Table)**, checked 2026-09-11 through the indexed page: lists two diamonds, four obsidian and one book. This does not independently verify the grid, output quantity, station behavior or a Quest version.

The wiki attributes community content under CC BY-SA. These are short original summaries with attribution, not copied article text or illustrations. General background: [Mojang · How to craft](https://www.minecraft.net/en-us/article/how-craft).

## Interpretation

Every recipe displays a Minecraft-comparison notice, including recipes with additional field-scoped RealmCraft wiki evidence. Reference stations such as a stonecutter, smoker or smithing table must not be read as confirmed RealmCraft features. The smithing instructions explicitly describe the older Java 1.16.5 procedure without a template.

Exact English names, plus a small explicit alias map, connect source items to the existing name catalog. This is a comparison lookup only. Crop block `carrots` is deliberately not mapped to ingredient `carrot`; unknown ingredient mappings remain unknown. Materials within an ingredient group are alternatives. Counts refer to the group total, not every option. The grid is always one batch; requested quantity scales direct ingredients by ceiling(requested / yield), with a displayed surplus. Ingredient and reverse-use navigation do not recursively expand a shopping list or compare personal inventory. Smelting fuel is additional and has no invented RealmCraft amount.

The 859 original source recipes include 38 that were not imported: 13 dynamic recipes and 25 recipes whose outputs are absent from the existing catalog. Their paths and reasons remain in `omittedSourceRecipes`. Brewing chains are not part of this source dataset. Of 618 name-catalog entries without an imported recipe, 160 now have an obtaining guide and 458 remain **open**, not asserted uncraftable. Special recipes, RealmCraft-exclusive content, platform/version verification and Android/web parity remain backlog items.

## Reproduce and validate

### Material-plan follow-up · 1.7.43

The separate material plan combines up to 50 targets and optionally expands intermediate recipes. One selected route per item and one selected option per ingredient group avoid invented substitutions; mixing alternatives within one group is not implemented. Shared demand is aggregated before batch rounding. Explicit supply stops and entries without recipes remain “not further expanded,” not asserted raw materials. Cycles, missing choices, catalog changes and bounded-complexity/quantity failures withhold final totals. Neither stock, fuel quantities nor construction of processing stations is included.

The macOS plan is saved separately from world data with a semantic catalog fingerprint, atomic writes, a dedicated lock and optimistic conflict checking. Copy/text export retains target amounts, chosen inputs, production/surplus, original recipe paths and hashes, reference version and the unverified-RealmCraft notice. Conversation lookup now reuses the same index, offers explicit numbered variants and quantity followups, and reads saved plans. This adds calculation, retrieval and local organization only, not new recipe evidence or a conversation stock adapter.

Android 0.10.0 reuses the exact catalog asset with a bounded JavaScript calculation port and native optional speech controls. Its local plan has the same calculation semantics but independent device-local storage; plans are not automatically synchronized across platforms. Its APK and device acceptance are tracked separately.

```sh
swiftc -parse-as-library Sources/CraftingCatalog.swift Sources/PlanningStore.swift Sources/CraftingPlan.swift Tests/CraftingPlanTests.swift -o /tmp/realmcraft-crafting-plan-tests
/tmp/realmcraft-crafting-plan-tests Resources/CraftingCatalog.json
```

### Catalog reproduction

Use a separately obtained matching official client archive; the tool does not download anything:

```sh
python3 Tools/build_crafting_catalog.py /path/to/client.jar Resources/CraftingCatalog.json
swiftc -parse-as-library Sources/CraftingCatalog.swift Tests/CraftingCatalogTests.swift -o /tmp/realmcraft-crafting-tests
/tmp/realmcraft-crafting-tests Resources/CraftingCatalog.json
```

The model validates output/ingredient links, bilingual names, unique IDs, positive bounded quantities, legal grid indices and agreement between grid cells and ingredient totals. Tests cover batch rounding, alternative ingredients, station classification, crop/item separation, multi-language search, combined filters, reverse uses, missing recipes, copy provenance and malformed-grid rejection. These checks establish software/data consistency, not successful crafting in the game. Existing conversation/material-check behavior continues to use its ten-recipe resource.

The page needs no savegame, device, API key or network connection. External sources open only through explicit links; the Mojang link is labeled as a client-JAR download.

## Personal verification and agent exports · 1.7.54

Every recipe variant and obtaining item can be saved or copied as complete Markdown. Selected instructions also join the existing AI context in Markdown and JSON. Single recipes use the displayed desired quantity; combined exports use one batch per recipe. Obtaining instructions retain prerequisites, special cases and scoped sources without invented crafting arithmetic.

Personal verification is local user data, not a shipped catalog assertion. Its content fingerprint includes both language versions, the exact item/variant and recipe provenance. Changed instructions require renewed confirmation. Platform and game version are not recorded. Family members remain separate, and source caveats are preserved. Export selection is independent, with an action to add all currently personally verified instructions. Corrupt preference files and missing selected targets produce visible errors rather than an empty replacement or silent truncation.
