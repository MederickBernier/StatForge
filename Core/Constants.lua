-- StatForge/Core/Constants.lua
-- Slot IDs, stat key enums, display names. No dependencies.

StatForge = StatForge or {}

-- Inventory slot IDs (INVSLOT_* globals mirror these values)
StatForge.SLOT_IDS = {
    head      = 1,
    neck      = 2,
    shoulder  = 3,
    back      = 4,
    chest     = 5,
    waist     = 6,
    legs      = 7,
    feet      = 8,
    wrist     = 9,
    hands     = 10,
    finger1   = 11,
    finger2   = 12,
    trinket1  = 13,
    trinket2  = 14,
    mainhand  = 16,
    offhand   = 17,
}

-- Ordered slot list for UI iteration
StatForge.SLOT_ORDER = {
    "head", "neck", "shoulder", "back", "chest",
    "waist", "legs", "feet", "wrist", "hands",
    "finger1", "finger2", "trinket1", "trinket2",
    "mainhand", "offhand",
}

-- Human-readable slot labels
StatForge.SLOT_NAMES = {
    head     = "Head",
    neck     = "Neck",
    shoulder = "Shoulder",
    back     = "Back",
    chest    = "Chest",
    waist    = "Waist",
    legs     = "Legs",
    feet     = "Feet",
    wrist    = "Wrist",
    hands    = "Hands",
    finger1  = "Ring 1",
    finger2  = "Ring 2",
    trinket1 = "Trinket 1",
    trinket2 = "Trinket 2",
    mainhand = "Main Hand",
    offhand  = "Off Hand",
}

-- Inventory type IDs used to map bag items to gear slots
-- InvType string -> list of slotKeys that accept this type
StatForge.INVTYPE_TO_SLOTS = {
    INVTYPE_HEAD        = { "head" },
    INVTYPE_NECK        = { "neck" },
    INVTYPE_SHOULDER    = { "shoulder" },
    INVTYPE_CLOAK       = { "back" },
    INVTYPE_CHEST       = { "chest" },
    INVTYPE_ROBE        = { "chest" },
    INVTYPE_WAIST       = { "waist" },
    INVTYPE_LEGS        = { "legs" },
    INVTYPE_FEET        = { "feet" },
    INVTYPE_WRIST       = { "wrist" },
    INVTYPE_HAND        = { "hands" },
    INVTYPE_FINGER      = { "finger1", "finger2" },
    INVTYPE_TRINKET     = { "trinket1", "trinket2" },
    INVTYPE_WEAPON      = { "mainhand", "offhand" },
    INVTYPE_2HWEAPON    = { "mainhand" },
    INVTYPE_WEAPONMAINHAND = { "mainhand" },
    INVTYPE_WEAPONOFFHAND  = { "offhand" },
    INVTYPE_SHIELD      = { "offhand" },
    INVTYPE_HOLDABLE    = { "offhand" },
    INVTYPE_RANGED      = { "mainhand" },
    INVTYPE_RANGEDRIGHT = { "mainhand" },
}

-- Canonical stat keys as returned by GetItemStats()
-- These are the global string keys WoW uses in the stat table
StatForge.STAT_KEYS = {
    "ITEM_MOD_STRENGTH_SHORT",
    "ITEM_MOD_AGILITY_SHORT",
    "ITEM_MOD_INTELLECT_SHORT",
    "ITEM_MOD_STAMINA_SHORT",
    "ITEM_MOD_CRIT_RATING_SHORT",
    "ITEM_MOD_HASTE_RATING_SHORT",
    "ITEM_MOD_MASTERY_RATING_SHORT",
    "ITEM_MOD_VERSATILITY",
    "ITEM_MOD_ATTACK_POWER_SHORT",
    "ITEM_MOD_SPELL_POWER_SHORT",
    "ITEM_MOD_DODGE_RATING_SHORT",
    "ITEM_MOD_PARRY_RATING_SHORT",
    "ITEM_MOD_LEECH_RATING_SHORT",
    "ITEM_MOD_AVOIDANCE_RATING_SHORT",
    "ITEM_MOD_SPEED_SHORT",
}

-- Short display labels for each stat key
StatForge.STAT_DISPLAY = {
    ITEM_MOD_STRENGTH_SHORT         = "Strength",
    ITEM_MOD_AGILITY_SHORT          = "Agility",
    ITEM_MOD_INTELLECT_SHORT        = "Intellect",
    ITEM_MOD_STAMINA_SHORT          = "Stamina",
    ITEM_MOD_CRIT_RATING_SHORT      = "Crit",
    ITEM_MOD_HASTE_RATING_SHORT     = "Haste",
    ITEM_MOD_MASTERY_RATING_SHORT   = "Mastery",
    ITEM_MOD_VERSATILITY            = "Versatility",
    ITEM_MOD_ATTACK_POWER_SHORT     = "Attack Power",
    ITEM_MOD_SPELL_POWER_SHORT      = "Spell Power",
    ITEM_MOD_DODGE_RATING_SHORT     = "Dodge",
    ITEM_MOD_PARRY_RATING_SHORT     = "Parry",
    ITEM_MOD_LEECH_RATING_SHORT     = "Leech",
    ITEM_MOD_AVOIDANCE_RATING_SHORT = "Avoidance",
    ITEM_MOD_SPEED_SHORT            = "Speed",
}

-- Internal short keys used in spec priority lists and state serialization
-- Maps internal key -> GetItemStats() key
StatForge.STAT_KEY_MAP = {
    strength    = "ITEM_MOD_STRENGTH_SHORT",
    agility     = "ITEM_MOD_AGILITY_SHORT",
    intellect   = "ITEM_MOD_INTELLECT_SHORT",
    stamina     = "ITEM_MOD_STAMINA_SHORT",
    crit        = "ITEM_MOD_CRIT_RATING_SHORT",
    haste       = "ITEM_MOD_HASTE_RATING_SHORT",
    mastery     = "ITEM_MOD_MASTERY_RATING_SHORT",
    versatility = "ITEM_MOD_VERSATILITY",
    attackpower = "ITEM_MOD_ATTACK_POWER_SHORT",
    spellpower  = "ITEM_MOD_SPELL_POWER_SHORT",
    dodge       = "ITEM_MOD_DODGE_RATING_SHORT",
    parry       = "ITEM_MOD_PARRY_RATING_SHORT",
    leech       = "ITEM_MOD_LEECH_RATING_SHORT",
    avoidance   = "ITEM_MOD_AVOIDANCE_RATING_SHORT",
    speed       = "ITEM_MOD_SPEED_SHORT",
}

-- Reverse map: GetItemStats() key -> internal short key
StatForge.STAT_KEY_REVERSE = {}
for short, full in pairs(StatForge.STAT_KEY_MAP) do
    StatForge.STAT_KEY_REVERSE[full] = short
end

-- Optimization path identifiers
StatForge.OPT_PATHS = {
    PRIORITY    = "priority",
    BREAKPOINTS = "breakpoints",
    BUDGET      = "budget",
}

StatForge.OPT_PATH_LABELS = {
    priority    = "Stat Priority",
    breakpoints = "Percentage Breakpoints",
    budget      = "Budget Allocation",
}

-- Applied source type identifiers
StatForge.SOURCE_TYPES = {
    GEM        = "gem",
    ENCHANT    = "enchant",
    CONSUMABLE = "consumable",
}
