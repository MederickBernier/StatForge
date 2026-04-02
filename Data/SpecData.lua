-- StatForge/Data/SpecData.lua
-- Source: Wowhead (Midnight Season 1)
-- Update trigger: new season, major patch, or significant tuning pass.
--
-- Fields per entry:
--   specId         Global spec ID from GetSpecializationInfo(). 0 = unknown (new Midnight spec).
--   heroTalent     Stable internal key (lowercase, no spaces/apostrophes)
--   heroTalentName Human-readable display name
--   sentinelNodeId Trait node ID checked via C_Traits.GetNodeInfo() for hero talent detection.
--                  0 = placeholder; populate from C_Traits inspection or Wowpedia per patch.
--   priority       Ordered stat array using internal keys (see StatForge.STAT_KEY_MAP).
--                  Equal-weight stats (e.g. "Mastery = Versatility") are listed in the order
--                  they appear in the source table and treated as sequential by the engine.
--   notes          Optional string: content-type splits, breakpoints, playstyle variants.
--
-- Spec IDs reference: https://wowpedia.fandom.com/wiki/SpecializationID

StatForge.SPEC_DATA = {}

local function entry(specId, heroTalent, heroTalentName, sentinelNodeId, priority, notes)
    StatForge.SPEC_DATA[#StatForge.SPEC_DATA + 1] = {
        specId         = specId,
        heroTalent     = heroTalent,
        heroTalentName = heroTalentName,
        sentinelNodeId = sentinelNodeId,
        priority       = priority,
        notes          = notes,
    }
end

function StatForge.BuildSpecIndex()
    StatForge.SPEC_INDEX = {}
    for _, e in ipairs(StatForge.SPEC_DATA) do
        local key = tostring(e.specId) .. ":" .. e.heroTalent
        StatForge.SPEC_INDEX[key] = e
    end
end

-- ── Death Knight ──────────────────────────────────────────────────────────────
-- Blood 250 | Frost 251 | Unholy 252

-- Blood: Mastery = Versatility at priority 3; San'layn: Mastery = Crit = Versatility at 3
entry(250, "deathbringer", "Deathbringer", 0,
    {"strength","crit","mastery","versatility","haste"})

entry(250, "sanlayan", "San'layn", 0,
    {"strength","haste","mastery","crit","versatility"})

-- Frost: identical priority for both hero talents
entry(251, "deathbringer", "Deathbringer", 0,
    {"strength","crit","mastery","haste","versatility"})

entry(251, "rideroftheapocalypse", "Rider of the Apocalypse", 0,
    {"strength","crit","mastery","haste","versatility"})

-- Unholy: identical priority for both hero talents
entry(252, "rideroftheapocalypse", "Rider of the Apocalypse", 0,
    {"strength","mastery","crit","haste","versatility"})

entry(252, "sanlayan", "San'layn", 0,
    {"strength","mastery","crit","haste","versatility"})

-- ── Demon Hunter ──────────────────────────────────────────────────────────────
-- Havoc 577 | Vengeance 581 | Devourer 0 (Midnight new spec — ID unknown)

-- Havoc: identical for both hero talents
entry(577, "aldrachireaver", "Aldrachi Reaver", 0,
    {"agility","crit","mastery","haste","versatility"})

entry(577, "felscarred", "Fel-Scarred", 0,
    {"agility","crit","mastery","haste","versatility"})

-- Vengeance: all secondaries roughly equal; Haste more important for Aldrachi Reaver.
-- Defensive priority used as default. Offensive: crit > mastery > versatility > haste.
entry(581, "aldrachireaver", "Aldrachi Reaver", 0,
    {"agility","haste","crit","versatility","mastery"},
    "Defensive priority. Offensive variant: agility > crit > mastery > versatility > haste.")

entry(581, "annihilator", "Annihilator", 0,
    {"agility","haste","crit","versatility","mastery"},
    "Defensive priority. Offensive variant: agility > crit > mastery > versatility > haste.")

-- Devourer: new Midnight spec — caster/support role
entry(0, "annihilator", "Annihilator", 0,
    {"intellect","haste","mastery","crit","versatility"})

entry(0, "voidscarred", "Void-Scarred", 0,
    {"intellect","mastery","haste","crit","versatility"})

-- ── Druid ─────────────────────────────────────────────────────────────────────
-- Balance 102 | Feral 103 | Guardian 104 | Restoration 105

-- Balance: Keeper — Haste = Crit at row 3; Elune's — distinct order
entry(102, "keeperofthegrove", "Keeper of the Grove", 0,
    {"intellect","mastery","haste","crit","versatility"})

entry(102, "eluenschosen", "Elune's Chosen", 0,
    {"intellect","mastery","haste","crit","versatility"})

-- Feral: hero talents shift Haste vs Crit at position 3/4
entry(103, "druidoftheclaw", "Druid of the Claw", 0,
    {"agility","mastery","haste","crit","versatility"})

entry(103, "wildstalker", "Wildstalker", 0,
    {"agility","mastery","crit","haste","versatility"})

-- Guardian: both hero talents share the same priority for both playstyles
entry(104, "druidoftheclaw", "Druid of the Claw", 0,
    {"agility","haste","versatility","crit","mastery"})

entry(104, "eluenschosen", "Elune's Chosen", 0,
    {"agility","haste","versatility","crit","mastery"})

-- Restoration: same for both hero talents and both content types
entry(105, "wildstalker", "Wildstalker", 0,
    {"intellect","haste","mastery","versatility","crit"})

entry(105, "keeperofthegrove", "Keeper of the Grove", 0,
    {"intellect","haste","mastery","versatility","crit"})

-- ── Evoker ────────────────────────────────────────────────────────────────────
-- Devastation 1467 | Preservation 1468 | Augmentation 1473

-- Devastation: identical for both hero talents
entry(1467, "flameshaper", "Flameshaper", 0,
    {"intellect","crit","haste","mastery","versatility"})

entry(1467, "scalecommander", "Scalecommander", 0,
    {"intellect","crit","haste","mastery","versatility"})

-- Preservation: identical for both hero talents (Chronowarden: Crit = Haste in Raid)
entry(1468, "flameshaper", "Flameshaper", 0,
    {"intellect","mastery","haste","crit","versatility"})

entry(1468, "chronowarden", "Chronowarden", 0,
    {"intellect","mastery","haste","crit","versatility"},
    "Crit and Haste are equal in Raid.")

-- Augmentation: identical for both hero talents
entry(1473, "chronowarden", "Chronowarden", 0,
    {"intellect","crit","haste","mastery","versatility"})

entry(1473, "scalecommander", "Scalecommander", 0,
    {"intellect","crit","haste","mastery","versatility"})

-- ── Hunter ────────────────────────────────────────────────────────────────────
-- Beast Mastery 253 | Marksmanship 254 | Survival 255

-- Beast Mastery: ST used as default (Weapon Damage not a tracked stat; agility drives ilvl).
-- AoE variant shifts Crit above Haste at position 4/5.
entry(253, "packleader", "Pack Leader", 0,
    {"agility","mastery","haste","crit","versatility"},
    "Single-target priority. AoE variant: agility > mastery > crit > versatility > haste.")

entry(253, "darkranger", "Dark Ranger", 0,
    {"agility","mastery","haste","crit","versatility"},
    "Single-target priority. AoE variant: agility > mastery > crit > versatility > haste.")

-- Marksmanship: same for both hero talents
entry(254, "sentinel", "Sentinel", 0,
    {"agility","crit","mastery","versatility","haste"})

entry(254, "darkranger", "Dark Ranger", 0,
    {"agility","crit","mastery","versatility","haste"})

-- Survival: Crit = Haste at row 3 for Pack Leader
entry(255, "packleader", "Pack Leader", 0,
    {"agility","mastery","crit","haste","versatility"})

entry(255, "sentinel", "Sentinel", 0,
    {"agility","mastery","crit","haste","versatility"})

-- ── Mage ──────────────────────────────────────────────────────────────────────
-- Arcane 62 | Fire 63 | Frost 64

-- Arcane: same for both hero talents
entry(62, "spellslinger", "Spellslinger", 0,
    {"intellect","mastery","haste","crit","versatility"})

entry(62, "sunfury", "Sunfury", 0,
    {"intellect","mastery","haste","crit","versatility"})

-- Fire: same for both hero talents
entry(63, "sunfury", "Sunfury", 0,
    {"intellect","haste","mastery","versatility","crit"})

entry(63, "frostfire", "Frostfire", 0,
    {"intellect","haste","mastery","versatility","crit"})

-- Frost: same for both hero talents
entry(64, "frostfire", "Frostfire", 0,
    {"intellect","mastery","crit","haste","versatility"})

entry(64, "spellslinger", "Spellslinger", 0,
    {"intellect","mastery","crit","haste","versatility"})

-- ── Monk ──────────────────────────────────────────────────────────────────────
-- Brewmaster 268 | Mistweaver 270 | Windwalker 269

-- Brewmaster: both hero talents share priority per playstyle.
-- Defensive (default for tanks): Versatility = Crit = Mastery at row 2.
-- Offensive: Crit > Mastery > Versatility > Haste.
entry(268, "masterofharmony", "Master of Harmony", 0,
    {"agility","versatility","crit","mastery","haste"},
    "Defensive priority. Offensive variant: agility > crit > mastery > versatility > haste.")

entry(268, "shadopan", "Shado-Pan", 0,
    {"agility","versatility","crit","mastery","haste"},
    "Defensive priority. Offensive variant: agility > crit > mastery > versatility > haste.")

-- Mistweaver: same for both hero talents and both content types
entry(270, "conduitofthecelestials", "Conduit of the Celestials", 0,
    {"intellect","haste","crit","versatility","mastery"})

entry(270, "masterofharmony", "Master of Harmony", 0,
    {"intellect","haste","crit","versatility","mastery"})

-- Windwalker: hero talents diverge at position 3/4
entry(269, "shadopan", "Shado-Pan", 0,
    {"agility","haste","crit","mastery","versatility"})

entry(269, "conduitofthecelestials", "Conduit of the Celestials", 0,
    {"agility","haste","mastery","crit","versatility"})

-- ── Paladin ───────────────────────────────────────────────────────────────────
-- Holy 65 | Protection 66 | Retribution 70

-- Holy: same for both hero talents; Haste = Crit at row 3
entry(65, "heraldofthesun", "Herald of the Sun", 0,
    {"intellect","mastery","haste","crit","versatility"})

entry(65, "lightsmith", "Lightsmith", 0,
    {"intellect","mastery","haste","crit","versatility"})

-- Protection: both hero talents share priority; survivability used as default.
-- DPS variant: strength > haste > versatility > crit > mastery.
entry(66, "lightsmith", "Lightsmith", 0,
    {"strength","haste","versatility","mastery","crit"},
    "Survivability priority. DPS variant: strength > haste > versatility > crit > mastery.")

entry(66, "templar", "Templar", 0,
    {"strength","haste","versatility","mastery","crit"},
    "Survivability priority. DPS variant: strength > haste > versatility > crit > mastery.")

-- Retribution: same for both hero talents
entry(70, "templar", "Templar", 0,
    {"strength","mastery","crit","haste","versatility"})

entry(70, "heraldofthesun", "Herald of the Sun", 0,
    {"strength","mastery","crit","haste","versatility"})

-- ── Priest ────────────────────────────────────────────────────────────────────
-- Discipline 256 | Holy 257 | Shadow 258

-- Discipline: hero talent does not influence priority. Raid used as default.
-- M+ variant: intellect > haste > crit > versatility > mastery.
entry(256, "oracle", "Oracle", 0,
    {"intellect","haste","crit","mastery","versatility"},
    "Raid priority. M+ variant: intellect > haste > crit > versatility > mastery.")

entry(256, "voidweaver", "Voidweaver", 0,
    {"intellect","haste","crit","mastery","versatility"},
    "Raid priority. M+ variant: intellect > haste > crit > versatility > mastery.")

-- Holy: Raid used as default; Versatility = Mastery at row 3.
-- M+ variant: intellect > versatility > crit > haste > mastery.
entry(257, "archon", "Archon", 0,
    {"intellect","crit","versatility","mastery","haste"},
    "Raid priority. M+ variant: intellect > versatility > crit > haste > mastery.")

entry(257, "oracle", "Oracle", 0,
    {"intellect","crit","versatility","mastery","haste"},
    "Raid priority. M+ variant: intellect > versatility > crit > haste > mastery.")

-- Shadow: same for both hero talents
entry(258, "archon", "Archon", 0,
    {"intellect","haste","mastery","crit","versatility"})

entry(258, "voidweaver", "Voidweaver", 0,
    {"intellect","haste","mastery","crit","versatility"})

-- ── Rogue ─────────────────────────────────────────────────────────────────────
-- Assassination 259 | Outlaw 260 | Subtlety 261

-- Assassination: same for both hero talents
entry(259, "deathstalker", "Deathstalker", 0,
    {"agility","crit","haste","mastery","versatility"})

entry(259, "fatebound", "Fatebound", 0,
    {"agility","crit","haste","mastery","versatility"})

-- Outlaw: same for both hero talents; note 25% Haste soft-cap
entry(260, "fatebound", "Fatebound", 0,
    {"agility","haste","crit","versatility","mastery"},
    "Aim for ~25% Haste before prioritising other secondaries.")

entry(260, "trickster", "Trickster", 0,
    {"agility","haste","crit","versatility","mastery"},
    "Aim for ~25% Haste before prioritising other secondaries.")

-- Subtlety: same for both hero talents and both target counts; ~18% Haste breakpoint
entry(261, "deathstalker", "Deathstalker", 0,
    {"agility","mastery","haste","crit","versatility"},
    "~18% Haste is a soft breakpoint. Priority is the same for ST and M+.")

entry(261, "trickster", "Trickster", 0,
    {"agility","mastery","haste","crit","versatility"},
    "~18% Haste is a soft breakpoint. Priority is the same for ST and M+.")

-- ── Shaman ────────────────────────────────────────────────────────────────────
-- Elemental 262 | Enhancement 263 | Restoration 264

-- Elemental: Mastery to 1200 rating is a hard breakpoint target (see Breakpoints path).
-- Haste = Crit after breakpoint. Intellect appears at position 4 in source table.
entry(262, "farseer", "Farseer", 0,
    {"mastery","haste","crit","versatility","intellect"},
    "Mastery to 1200 rating is a breakpoint. Use the Breakpoints optimisation path to track this.")

entry(262, "stormbringer", "Stormbringer", 0,
    {"mastery","haste","crit","versatility","intellect"},
    "Mastery to 1200 rating is a breakpoint. Use the Breakpoints optimisation path to track this.")

-- Enhancement: hero talents diverge at position 2/3
entry(263, "stormbringer", "Stormbringer", 0,
    {"agility","haste","mastery","crit","versatility"})

entry(263, "totemic", "Totemic", 0,
    {"agility","mastery","haste","crit","versatility"})

-- Restoration: same for both hero talents; Mastery = Versatility at row 3
entry(264, "farseer", "Farseer", 0,
    {"intellect","crit","mastery","versatility","haste"})

entry(264, "totemic", "Totemic", 0,
    {"intellect","crit","mastery","versatility","haste"})

-- ── Warlock ───────────────────────────────────────────────────────────────────
-- Affliction 265 | Demonology 266 | Destruction 267

-- Affliction: same for both hero talents; Mastery = Crit at row 2
entry(265, "hellcaller", "Hellcaller", 0,
    {"intellect","mastery","crit","haste","versatility"})

entry(265, "soalharvester", "Soul Harvester", 0,
    {"intellect","mastery","crit","haste","versatility"})

-- Demonology: same for both hero talents; Haste = Crit at row 2
entry(266, "diabolist", "Diabolist", 0,
    {"intellect","haste","crit","mastery","versatility"})

entry(266, "soalharvester", "Soul Harvester", 0,
    {"intellect","haste","crit","mastery","versatility"})

-- Destruction: same for both hero talents; Mastery = Crit at row 3
entry(267, "diabolist", "Diabolist", 0,
    {"intellect","haste","mastery","crit","versatility"})

entry(267, "hellcaller", "Hellcaller", 0,
    {"intellect","haste","mastery","crit","versatility"})

-- ── Warrior ───────────────────────────────────────────────────────────────────
-- Arms 71 | Fury 72 | Protection 73

-- Arms: same for both hero talents
entry(71, "colossus", "Colossus", 0,
    {"strength","crit","haste","mastery","versatility"})

entry(71, "slayer", "Slayer", 0,
    {"strength","crit","haste","mastery","versatility"})

-- Fury: same for both hero talents
entry(72, "mountainthane", "Mountain Thane", 0,
    {"strength","haste","mastery","crit","versatility"})

entry(72, "slayer", "Slayer", 0,
    {"strength","haste","mastery","crit","versatility"})

-- Protection: both hero talents share priority per playstyle; survivability as default.
-- DPS variant: strength > haste > crit > versatility > mastery (same as survivability here).
entry(73, "colossus", "Colossus", 0,
    {"strength","haste","crit","versatility","mastery"})

entry(73, "mountainthane", "Mountain Thane", 0,
    {"strength","haste","crit","versatility","mastery"})

-- ── Post-load index ───────────────────────────────────────────────────────────
StatForge.BuildSpecIndex()
