-- StatForge/Data/AppliedData.lua
-- Source: Wowhead (Midnight Season 1)
-- Update trigger: new season, major patch, crafted item changes.
--
-- Applied sources: gems, enchants, consumables (food, flasks, weapon buffs).
-- These are the non-gear stat layers the user toggles in the Optimizer tab.
--
-- Data shape per entry:
--   key    Unique source key: "type:internalname" (e.g. "gem:masterful_ruby")
--   name   Display name
--   type   StatForge.SOURCE_TYPES constant: "gem", "enchant", "consumable"
--   slot   Which gear slot or logical slot this applies to:
--            gems      -> gear slot key (e.g. "head", "finger1") or "any" for prismatic
--            enchants  -> gear slot key (e.g. "neck", "mainhand")
--            consumable-> "food", "flask", "weaponbuff", "augment"
--   rank1  Stat table at quality rank 1  { [internalStatKey] = value }
--   rank2  Stat table at quality rank 2  { [internalStatKey] = value }
--
-- Internal stat keys are the short keys from StatForge.STAT_KEY_MAP
-- (e.g. "crit", "haste", "mastery", "versatility", "strength", etc.)
--
-- NOTE: Stub file — populate with Season 1 Midnight data.

StatForge.APPLIED_DATA = {}

local function source(key, name, sourceType, slot, rank1, rank2)
    StatForge.APPLIED_DATA[#StatForge.APPLIED_DATA + 1] = {
        key        = key,
        name       = name,
        type       = sourceType,
        slot       = slot,
        rank1      = rank1,
        rank2      = rank2,
    }
end

-- Build a lookup by key for O(1) access
function StatForge.BuildAppliedIndex()
    StatForge.APPLIED_INDEX = {}
    for _, e in ipairs(StatForge.APPLIED_DATA) do
        StatForge.APPLIED_INDEX[e.key] = e
    end
end

-- ── Gems ─────────────────────────────────────────────────────────────────────
-- Slot value: the gear slot key this gem is assigned to (set at runtime by user).
-- "any" gems (prismatic) can go in any socket.
-- Stat values below are placeholders — replace with actual Midnight Season 1 values.

source("gem:masterful", "Masterful gem",
    StatForge.SOURCE_TYPES.GEM, "any",
    { mastery = 90 },
    { mastery = 120 })

source("gem:quick", "Quick gem",
    StatForge.SOURCE_TYPES.GEM, "any",
    { haste = 90 },
    { haste = 120 })

source("gem:keen", "Keen gem",
    StatForge.SOURCE_TYPES.GEM, "any",
    { crit = 90 },
    { crit = 120 })

source("gem:versatile", "Versatile gem",
    StatForge.SOURCE_TYPES.GEM, "any",
    { versatility = 90 },
    { versatility = 120 })

source("gem:puissant", "Puissant gem (Stamina)",
    StatForge.SOURCE_TYPES.GEM, "any",
    { stamina = 135 },
    { stamina = 180 })

-- ── Enchants ─────────────────────────────────────────────────────────────────
-- Slot matches the gear slot key (neck, back, wrist, finger1/finger2 use same enchant).
-- Finger enchants apply to both ring slots — handled by assigning to "finger".

source("enchant:neck_haste", "Neck — Haste enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "neck",
    { haste = 80 },
    { haste = 110 })

source("enchant:neck_crit", "Neck — Crit enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "neck",
    { crit = 80 },
    { crit = 110 })

source("enchant:back_haste", "Cloak — Haste enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "back",
    { haste = 60 },
    { haste = 80 })

source("enchant:back_versatility", "Cloak — Versatility enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "back",
    { versatility = 60 },
    { versatility = 80 })

source("enchant:wrist_mastery", "Bracers — Mastery enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "wrist",
    { mastery = 70 },
    { mastery = 95 })

source("enchant:wrist_haste", "Bracers — Haste enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "wrist",
    { haste = 70 },
    { haste = 95 })

source("enchant:finger_haste", "Ring — Haste enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "finger",
    { haste = 80 },
    { haste = 110 })

source("enchant:finger_mastery", "Ring — Mastery enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "finger",
    { mastery = 80 },
    { mastery = 110 })

source("enchant:finger_crit", "Ring — Crit enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "finger",
    { crit = 80 },
    { crit = 110 })

source("enchant:finger_versatility", "Ring — Versatility enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "finger",
    { versatility = 80 },
    { versatility = 110 })

source("enchant:mainhand_haste", "Weapon — Haste enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "mainhand",
    { haste = 120 },
    { haste = 165 })

source("enchant:mainhand_mastery", "Weapon — Mastery enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "mainhand",
    { mastery = 120 },
    { mastery = 165 })

source("enchant:mainhand_crit", "Weapon — Crit enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "mainhand",
    { crit = 120 },
    { crit = 165 })

source("enchant:chest_haste", "Chest — Haste enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "chest",
    { haste = 80 },
    { haste = 110 })

source("enchant:chest_crit", "Chest — Crit enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "chest",
    { crit = 80 },
    { crit = 110 })

source("enchant:feet_haste", "Boots — Haste enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "feet",
    { haste = 70 },
    { haste = 95 })

source("enchant:legs_haste", "Legs — Haste enchant",
    StatForge.SOURCE_TYPES.ENCHANT, "legs",
    { haste = 80 },
    { haste = 110 })

-- ── Consumables ───────────────────────────────────────────────────────────────
-- slot = "food", "flask", "weaponbuff", or "augment" (logical consumable slot)

source("consumable:food_haste", "Feast / Food — Haste",
    StatForge.SOURCE_TYPES.CONSUMABLE, "food",
    { haste = 100 },
    { haste = 150 })

source("consumable:food_crit", "Feast / Food — Crit",
    StatForge.SOURCE_TYPES.CONSUMABLE, "food",
    { crit = 100 },
    { crit = 150 })

source("consumable:food_mastery", "Feast / Food — Mastery",
    StatForge.SOURCE_TYPES.CONSUMABLE, "food",
    { mastery = 100 },
    { mastery = 150 })

source("consumable:food_versatility", "Feast / Food — Versatility",
    StatForge.SOURCE_TYPES.CONSUMABLE, "food",
    { versatility = 100 },
    { versatility = 150 })

source("consumable:flask_primary", "Flask — Primary Stat",
    StatForge.SOURCE_TYPES.CONSUMABLE, "flask",
    { strength = 250, agility = 250, intellect = 250 },
    { strength = 350, agility = 350, intellect = 350 })

source("consumable:flask_stamina", "Flask — Stamina",
    StatForge.SOURCE_TYPES.CONSUMABLE, "flask",
    { stamina = 500 },
    { stamina = 700 })

source("consumable:weaponbuff_haste", "Weapon Oil — Haste",
    StatForge.SOURCE_TYPES.CONSUMABLE, "weaponbuff",
    { haste = 80 },
    { haste = 120 })

source("consumable:weaponbuff_mastery", "Weapon Oil — Mastery",
    StatForge.SOURCE_TYPES.CONSUMABLE, "weaponbuff",
    { mastery = 80 },
    { mastery = 120 })

source("consumable:augment_primary", "Augment Rune",
    StatForge.SOURCE_TYPES.CONSUMABLE, "augment",
    { strength = 90, agility = 90, intellect = 90 },
    { strength = 90, agility = 90, intellect = 90 })

-- ── Post-load index ───────────────────────────────────────────────────────────
StatForge.BuildAppliedIndex()
