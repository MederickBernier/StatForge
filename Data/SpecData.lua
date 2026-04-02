-- StatForge/Data/SpecData.lua
-- 40 specs × 2 hero talent builds = 80 stat priority entries.
--
-- Fields:
--   specId         Global spec ID returned by GetSpecializationInfo()
--   heroTalent     Stable internal key (lowercase, no spaces/apostrophes)
--   heroTalentName Human-readable display name
--   priority       Ordered array of internal stat keys (StatForge.STAT_KEY_MAP)
--   sentinelNodeId Trait node ID checked via C_Traits.GetNodeInfo() to detect
--                  which hero talent path is active. Values are TWW-era node IDs;
--                  update this file at each expansion / major talent patch.
--
-- Priority lists reflect community-accepted stat weights (TWW season baseline).
-- Edit locally via /statforge setups or StatForgeDB.specOverrides for personal
-- adjustments ahead of an official data update.

StatForge.SPEC_DATA = {}

local function entry(specId, heroTalent, heroTalentName, sentinelNodeId, priority)
    StatForge.SPEC_DATA[#StatForge.SPEC_DATA + 1] = {
        specId         = specId,
        heroTalent     = heroTalent,
        heroTalentName = heroTalentName,
        sentinelNodeId = sentinelNodeId,
        priority       = priority,
    }
end

-- Helper: build a lookup by specId+heroTalent for O(1) access at runtime
-- Called by SpecDetector after this file loads.
function StatForge.BuildSpecIndex()
    StatForge.SPEC_INDEX = {}
    for _, e in ipairs(StatForge.SPEC_DATA) do
        local key = tostring(e.specId) .. ":" .. e.heroTalent
        StatForge.SPEC_INDEX[key] = e
    end
end

-- ── Death Knight ──────────────────────────────────────────────────────────────
-- Blood 250 | Frost 251 | Unholy 252

-- Blood / San'layn — mastery buffs blood shield
entry(250, "sanlayan", "San'layn", 212279,
    {"stamina","strength","mastery","versatility","haste","crit"})

-- Blood / Deathbringer — direct damage amp, versatility over mastery
entry(250, "deathbringer", "Deathbringer", 212278,
    {"stamina","strength","versatility","haste","mastery","crit"})

-- Frost / Rider of the Apocalypse — haste first for proc density
entry(251, "rideroftheapocalypse", "Rider of the Apocalypse", 212277,
    {"strength","haste","crit","mastery","versatility"})

-- Frost / Deathbringer — mastery shifts up for Reaper's Mark
entry(251, "deathbringer", "Deathbringer", 212278,
    {"strength","haste","mastery","crit","versatility"})

-- Unholy / Rider of the Apocalypse — haste for ghoul speed and DT procs
entry(252, "rideroftheapocalypse", "Rider of the Apocalypse", 212277,
    {"strength","haste","mastery","crit","versatility"})

-- Unholy / San'layn — mastery amplifies Virulent Plague dot
entry(252, "sanlayan", "San'layn", 212279,
    {"strength","mastery","haste","crit","versatility"})

-- ── Demon Hunter ──────────────────────────────────────────────────────────────
-- Havoc 577 | Vengeance 581

entry(577, "aldrachireaver", "Aldrachi Reaver", 212415,
    {"agility","versatility","haste","crit","mastery"})

entry(577, "felscarred", "Fel-Scarred", 212414,
    {"agility","haste","crit","versatility","mastery"})

entry(581, "aldrachireaver", "Aldrachi Reaver", 212415,
    {"agility","versatility","mastery","haste","crit"})

entry(581, "felscarred", "Fel-Scarred", 212414,
    {"agility","haste","versatility","mastery","crit"})

-- ── Druid ─────────────────────────────────────────────────────────────────────
-- Balance 102 | Feral 103 | Guardian 104 | Restoration 105

entry(102, "eluenschosen", "Elune's Chosen", 212523,
    {"intellect","haste","mastery","crit","versatility"})

entry(102, "keeperofthegrove", "Keeper of the Grove", 212524,
    {"intellect","mastery","haste","crit","versatility"})

entry(103, "wildstalker", "Wildstalker", 212526,
    {"agility","haste","crit","mastery","versatility"})

entry(103, "druidoftheclaw", "Druid of the Claw", 212525,
    {"agility","haste","mastery","crit","versatility"})

entry(104, "wildstalker", "Wildstalker", 212526,
    {"agility","mastery","versatility","haste","crit"})

entry(104, "druidoftheclaw", "Druid of the Claw", 212525,
    {"agility","versatility","mastery","haste","crit"})

entry(105, "eluenschosen", "Elune's Chosen", 212523,
    {"intellect","haste","mastery","crit","versatility"})

entry(105, "keeperofthegrove", "Keeper of the Grove", 212524,
    {"intellect","haste","crit","mastery","versatility"})

-- ── Evoker ────────────────────────────────────────────────────────────────────
-- Devastation 1467 | Preservation 1468 | Augmentation 1473

entry(1467, "flameshaper", "Flameshaper", 212441,
    {"intellect","haste","mastery","crit","versatility"})

entry(1467, "scalecommander", "Scalecommander", 212442,
    {"intellect","haste","crit","mastery","versatility"})

entry(1468, "chronowarden", "Chronowarden", 212443,
    {"intellect","haste","mastery","crit","versatility"})

entry(1468, "flameshaper", "Flameshaper", 212441,
    {"intellect","haste","crit","mastery","versatility"})

entry(1473, "chronowarden", "Chronowarden", 212443,
    {"intellect","mastery","haste","crit","versatility"})

entry(1473, "scalecommander", "Scalecommander", 212442,
    {"intellect","haste","mastery","crit","versatility"})

-- ── Hunter ────────────────────────────────────────────────────────────────────
-- Beast Mastery 253 | Marksmanship 254 | Survival 255

entry(253, "packleader", "Pack Leader", 212387,
    {"agility","haste","crit","mastery","versatility"})

entry(253, "darkranger", "Dark Ranger", 212388,
    {"agility","crit","haste","mastery","versatility"})

entry(254, "sentinel", "Sentinel", 212389,
    {"agility","crit","mastery","haste","versatility"})

entry(254, "darkranger", "Dark Ranger", 212388,
    {"agility","haste","crit","mastery","versatility"})

entry(255, "packleader", "Pack Leader", 212387,
    {"agility","haste","mastery","crit","versatility"})

entry(255, "sentinel", "Sentinel", 212389,
    {"agility","mastery","haste","crit","versatility"})

-- ── Mage ──────────────────────────────────────────────────────────────────────
-- Arcane 62 | Fire 63 | Frost 64

entry(62, "spellslinger", "Spellslinger", 212456,
    {"intellect","haste","crit","mastery","versatility"})

entry(62, "sunfury", "Sunfury", 212457,
    {"intellect","mastery","haste","crit","versatility"})

entry(63, "spellslinger", "Spellslinger", 212456,
    {"intellect","crit","haste","versatility","mastery"})

entry(63, "sunfury", "Sunfury", 212457,
    {"intellect","crit","mastery","haste","versatility"})

entry(64, "frostfire", "Frostfire", 212458,
    {"intellect","haste","crit","mastery","versatility"})

entry(64, "spellslinger", "Spellslinger", 212456,
    {"intellect","haste","mastery","crit","versatility"})

-- ── Monk ──────────────────────────────────────────────────────────────────────
-- Brewmaster 268 | Mistweaver 270 | Windwalker 269

entry(268, "masterofharmony", "Master of Harmony", 212537,
    {"agility","versatility","mastery","haste","crit"})

entry(268, "shadopan", "Shado-Pan", 212538,
    {"agility","haste","versatility","mastery","crit"})

entry(270, "masterofharmony", "Master of Harmony", 212537,
    {"intellect","haste","mastery","crit","versatility"})

entry(270, "conduitofthecelestials", "Conduit of the Celestials", 212539,
    {"intellect","haste","crit","mastery","versatility"})

entry(269, "shadopan", "Shado-Pan", 212538,
    {"agility","haste","mastery","crit","versatility"})

entry(269, "conduitofthecelestials", "Conduit of the Celestials", 212539,
    {"agility","crit","haste","mastery","versatility"})

-- ── Paladin ───────────────────────────────────────────────────────────────────
-- Holy 65 | Protection 66 | Retribution 70

entry(65, "heraldofthesun", "Herald of the Sun", 212491,
    {"intellect","haste","mastery","crit","versatility"})

entry(65, "lightsmith", "Lightsmith", 212492,
    {"intellect","haste","crit","mastery","versatility"})

entry(66, "lightsmith", "Lightsmith", 212492,
    {"strength","versatility","haste","mastery","crit"})

entry(66, "heraldofthesun", "Herald of the Sun", 212491,
    {"strength","haste","versatility","mastery","crit"})

entry(70, "templar", "Templar", 212493,
    {"strength","haste","crit","versatility","mastery"})

entry(70, "heraldofthesun", "Herald of the Sun", 212491,
    {"strength","haste","mastery","crit","versatility"})

-- ── Priest ────────────────────────────────────────────────────────────────────
-- Discipline 256 | Holy 257 | Shadow 258

entry(256, "archon", "Archon", 212507,
    {"intellect","haste","mastery","crit","versatility"})

entry(256, "oracle", "Oracle", 212508,
    {"intellect","haste","crit","mastery","versatility"})

entry(257, "archon", "Archon", 212507,
    {"intellect","haste","mastery","crit","versatility"})

entry(257, "oracle", "Oracle", 212508,
    {"intellect","mastery","haste","crit","versatility"})

entry(258, "archon", "Archon", 212507,
    {"intellect","haste","crit","mastery","versatility"})

entry(258, "voidweaver", "Voidweaver", 212509,
    {"intellect","mastery","haste","crit","versatility"})

-- ── Rogue ─────────────────────────────────────────────────────────────────────
-- Assassination 259 | Outlaw 260 | Subtlety 261

entry(259, "fatebound", "Fatebound", 212474,
    {"agility","haste","mastery","crit","versatility"})

entry(259, "trickster", "Trickster", 212475,
    {"agility","mastery","haste","crit","versatility"})

entry(260, "fatebound", "Fatebound", 212474,
    {"agility","haste","crit","versatility","mastery"})

entry(260, "trickster", "Trickster", 212475,
    {"agility","haste","versatility","crit","mastery"})

entry(261, "fatebound", "Fatebound", 212474,
    {"agility","mastery","haste","crit","versatility"})

entry(261, "trickster", "Trickster", 212475,
    {"agility","crit","mastery","haste","versatility"})

-- ── Shaman ────────────────────────────────────────────────────────────────────
-- Elemental 262 | Enhancement 263 | Restoration 264

entry(262, "stormbringer", "Stormbringer", 212553,
    {"intellect","haste","mastery","crit","versatility"})

entry(262, "farseer", "Farseer", 212554,
    {"intellect","mastery","haste","crit","versatility"})

entry(263, "stormbringer", "Stormbringer", 212553,
    {"agility","haste","mastery","crit","versatility"})

entry(263, "totemic", "Totemic", 212555,
    {"agility","haste","crit","mastery","versatility"})

entry(264, "farseer", "Farseer", 212554,
    {"intellect","haste","mastery","crit","versatility"})

entry(264, "totemic", "Totemic", 212555,
    {"intellect","haste","crit","mastery","versatility"})

-- ── Warlock ───────────────────────────────────────────────────────────────────
-- Affliction 265 | Demonology 266 | Destruction 267

entry(265, "hellcaller", "Hellcaller", 212569,
    {"intellect","haste","mastery","crit","versatility"})

entry(265, "soalharvester", "Soul Harvester", 212570,
    {"intellect","mastery","haste","crit","versatility"})

entry(266, "diabolist", "Diabolist", 212571,
    {"intellect","haste","mastery","crit","versatility"})

entry(266, "soalharvester", "Soul Harvester", 212570,
    {"intellect","mastery","haste","crit","versatility"})

entry(267, "hellcaller", "Hellcaller", 212569,
    {"intellect","haste","crit","mastery","versatility"})

entry(267, "diabolist", "Diabolist", 212571,
    {"intellect","crit","haste","mastery","versatility"})

-- ── Warrior ───────────────────────────────────────────────────────────────────
-- Arms 71 | Fury 72 | Protection 73

entry(71, "colossus", "Colossus", 212583,
    {"strength","haste","mastery","crit","versatility"})

entry(71, "slayer", "Slayer", 212584,
    {"strength","crit","haste","mastery","versatility"})

entry(72, "colossus", "Colossus", 212583,
    {"strength","haste","crit","mastery","versatility"})

entry(72, "slayer", "Slayer", 212584,
    {"strength","haste","mastery","crit","versatility"})

entry(73, "colossus", "Colossus", 212583,
    {"strength","versatility","haste","crit","mastery"})

entry(73, "mountainthane", "Mountain Thane", 212585,
    {"strength","haste","versatility","mastery","crit"})

-- ── Post-load index ───────────────────────────────────────────────────────────
-- Build the lookup index immediately after the table is populated.
StatForge.BuildSpecIndex()
