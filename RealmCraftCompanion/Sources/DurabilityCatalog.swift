import Foundation

// Reference maxima extracted from this game's ArmorProperties / ToolProperties constructors.
// Evidence and compatibility limits: Resources/PLAYER-FORMAT.md.
// Unknown IDs stay unknown; never substitute values from another game.
enum DurabilityCatalog {
    static let maxima: [Int: Int] = [
        3000: 59, // WoodenPickaxe
        3001: 131, // StonePickaxe
        3002: 250, // IronPickaxe
        3003: 32, // GoldenPickaxe
        3004: 1561, // DiamondPickaxe
        3005: 2031, // NetheritePickaxe
        3006: 59, // WoodenAxe
        3007: 131, // StoneAxe
        3008: 250, // IronAxe
        3009: 32, // GoldenAxe
        3010: 1561, // DiamondAxe
        3011: 2031, // NetheriteAxe
        3012: 59, // WoodenHoe
        3013: 131, // StoneHoe
        3014: 250, // IronHoe
        3015: 32, // GoldenHoe
        3016: 1561, // DiamondHoe
        3017: 2031, // NetheriteHoe
        3018: 59, // WoodenShovel
        3019: 131, // StoneShovel
        3020: 250, // IronShovel
        3021: 32, // GoldenShovel
        3022: 1561, // DiamondShovel
        3023: 2031, // NetheriteShovel
        3024: 59, // WoodenSword
        3025: 131, // StoneSword
        3026: 250, // IronSword
        3027: 32, // GoldenSword
        3028: 1561, // DiamondSword
        3029: 2031, // NetheriteSword
        3030: 238, // Shears
        3031: 55, // LeatherCap
        3032: 80, // LeatherTunic
        3033: 75, // LeatherPants
        3034: 65, // LeatherBoots
        3035: 165, // ChainmailHelmet
        3036: 240, // ChainmailChestplate
        3037: 225, // ChainmailLeggings
        3038: 195, // ChainmailBoots
        3039: 165, // IronHelmet
        3040: 240, // IronChestplate
        3041: 225, // IronLeggings
        3042: 195, // IronBoots
        3043: 77, // GoldenHelmet
        3044: 112, // GoldenChestplate
        3045: 105, // GoldenLeggings
        3046: 91, // GoldenBoots
        3047: 363, // DiamondHelmet
        3048: 528, // DiamondChestplate
        3049: 495, // DiamondLeggings
        3050: 429, // DiamondBoots
        3051: 407, // NetheriteHelmet
        3052: 592, // NetheriteChestplate
        3053: 555, // NetheriteLeggings
        3054: 481, // NetheriteBoots
        3055: 275, // TurtleShell
        3067: 64, // FlintAndSteel
        3069: 384, // Bow
        3260: 64, // FishingRod
        3261: 25, // CarrotOnStick
        3300: 336, // Shield
    ]
}
