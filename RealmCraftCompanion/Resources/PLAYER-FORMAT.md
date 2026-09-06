# Player reader and enchantment evidence

The Companion reads player_data locally in native Swift. Codex, OpenAI, an API key, a game APK and a Python runtime are not required at runtime. ADB is only required to read a Quest. Local backups work offline.

Supported layout: player version 2 with length-checked entity payload, structured 36-slot inventory and 4-slot armor containers. Item IDs must agree, quantities and slots must be valid, and records must have their expected footers. The reader locates fields relative to structural markers, not the player's coordinates, inventory length, world ID or level. Unknown layouts fail visibly; optional unrecognized level fields remain unavailable.

Within the observed item-attribute component, component 59 contains a big-endian UInt32 count followed by count entries of UInt16 enchantment ID and UInt32 stored level. Zero levels, duplicate enchantment IDs, excessive counts and incomplete records are rejected. Unknown IDs and unusual positive levels are retained in the UI/export. DurabilityComponent 24 version 1 stores remaining durability (BE Int32, component offset +3) and AnvilUses (BE Int32, +7). Both must be nonnegative. Zero durability is retained, absence remains nil. MaxDurability is not stored in player_data.

## Durability reference catalog (1.6.1)

The native DurabilityCatalog contains 61 reference maxima from this game's ArmorProperties and ToolProperties constructor arguments, matched through the corresponding armor/tool type and material enums to Item symbols. This is not a Minecraft wiki lookup. Confirmed examples: diamond tools 1561, iron tools 250, bow 384, diamond helmet/chestplate/leggings/boots 363/528/495/429. The native DurabilityComponent constructor initializes remaining and maximum to the same value; Serialize writes remaining then anvil uses. Development evidence: metadata v107, native Serialize VA 0x2f93a6c, one-argument constructor VA 0x2f93910, ArmorProperties constructor VA 0x2f951e0, ToolProperties constructors VA 0x2f95388 and 0x2f953a0. Full per-item call addresses and binary hash are retained in the private analysis evidence, outside distributed source.

UI shows exact remaining / reference maximum and a percentage only when the reference is known and remaining lies in 0...maximum. Values above the reference are preserved without a misleading bar. A warning marks <=20%; this is a Companion display threshold, not a game rule. Unbreaking is an enchantment and does not multiply maximum durability or predict remaining actions.

JSON exports include optional durability and durabilityMaximum; missing values stay absent. Older JSON without these keys still decodes. Future game definitions can change while IDs stay stable; catalog compatibility is limited to the analyzed game definitions, not a guarantee for arbitrary future versions. Other players/worlds using this layout require no Codex, Python, APK or online lookup. Health and hunger remain unsupported.

EnchantmentNames.json was extracted from the enum TM.VoxelEngine.Entities.Components.Enchanting.EnchantmentId in the locally supplied RealmCraft metadata v107. Numeric values were read from enum field defaults, not copied from Minecraft. The local metadata SHA-256 and field/default offsets are recorded in the private analysis evidence outside the distributed app. The app distributes only the small factual name mapping and its own parser, never the game binaries or personal saves. German names are Companion translations.

Metadata structure reference used during development: [Cpp2IL field defaults](https://github.com/SamboyCoding/Cpp2IL/blob/development/LibCpp2IL/Metadata/Il2CppFieldDefaultValue.cs), [field definitions](https://github.com/SamboyCoding/Cpp2IL/blob/development/LibCpp2IL/Metadata/Il2CppFieldDefinition.cs), [type definitions](https://github.com/SamboyCoding/Cpp2IL/blob/development/LibCpp2IL/Metadata/Il2CppTypeDefinition.cs). These are development references, not runtime dependencies.

Compatibility is with the validated save layout and ID mapping, not a promise that every future RealmCraft version uses the same format. Synthetic tests vary inventories, armor, slots, counts, IDs and levels independently of the user's save; private regression files are not distributed. The schematic avatar uses equipped armor materials and does not reconstruct a personal skin.

Local player reads validate the actual bytes displayed against the player_data entry in manifest.json. This is not a full-world verification. Restore/export continue to validate the complete world with the existing engine.


## Repair forecasts and warnings (1.6.4)

Warnings use strict comparisons: fraction <0.20 critical/red, otherwise <0.50 caution/orange. Exactly 20% is caution and exactly 50% is normal. Unknown or out-of-range fractions are not classified. The displayed integer percentage is truncated, so a below-threshold value cannot round up to the threshold beside a warning.

Native Anvil.TryApplyMaterialRepair (token 0x06000523, VA 0x2e48ad0) computes positive MaxDurability / 4 using integer division and adds min(missing, perMaterial) per consumed material. Forecast to full is ceil(missing / floor(maximum / 4)); e.g. 408/1561 needs 3, while 0/1561 needs 5 because 4*390 leaves one point. Item material suggestions use equipment families and are NOT claimed as a decoded repair-recipe table. ValidateRepairMaterials (VA 0x2e496cc) consults a separate recipe cache that has not been decoded. The UI therefore explicitly asks the user to verify the suggested material in the anvil.

For equipment without a material suggestion, Anvil.TryApplyDurabilityCombine (VA 0x2e48c90) combines identical items, adds floor(float32(maximum)*float32(0.12)), and caps at maximum. The UI suggests one identical donor with at least max(1, missing-bonus) remaining durability and explicitly says the donor is consumed. The float32 constant is stored at VA 0x10ece20. Both paths need an anvil and XP levels; level costs/prior-work restrictions are not predicted, and the UI requires checking the actual cost. No claim of material availability in inventory/chests, anvil availability, or guaranteed future-version compatibility is made.

Tests: compile PlayerModels.swift, DurabilityCatalog.swift, RepairForecast.swift and Tests/RepairForecastTests.swift together. Covers exact warning boundaries, integer rounding, donors and unavailable forecasts. The feature uses native Swift only; binary analysis libraries are development tools, not application dependencies.
