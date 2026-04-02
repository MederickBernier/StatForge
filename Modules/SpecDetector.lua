-- StatForge/Modules/SpecDetector.lua
-- Auto-detects the player's active spec and hero talent path.
--
-- Detection strategy:
--   1. GetSpecialization()     -> local spec index (1-4)
--   2. GetSpecializationInfo() -> global spec ID
--   3. IsPlayerSpell(sentinelSpellId) per SpecData entry
--      -> true means that hero talent path is active (each path grants a unique spell)
--
-- sentinelSpellId = 0 in SpecData means the spell ID is not yet populated.
-- In that case detection falls back to the first matching entry and sets
-- heroTalentUnknown = true so the UI can show an appropriate prompt.
--
-- Cached result shape:
--   {
--     specId            number   global spec ID
--     heroTalent        string   internal hero talent key
--     heroTalentName    string   display name
--     heroTalentUnknown boolean  true when sentinel spell IDs are unpopulated
--     specEntry         table    full SpecData entry (priority, notes, etc.)
--   }

StatForge.SpecDetector = {}

local SpecDetector = StatForge.SpecDetector
local currentSpec  = nil   -- cached detection result

-- ── Detection ─────────────────────────────────────────────────────────────────

function SpecDetector.Detect()
    -- Spec index is unavailable before the player is fully in the world
    local specIndex = GetSpecialization()
    if not specIndex or specIndex == 0 then
        currentSpec = nil
        return nil
    end

    -- GetSpecializationInfo returns: id, name, description, icon, bg, role, primaryStat, classId
    local specId = GetSpecializationInfo(specIndex)
    if not specId or specId == 0 then
        currentSpec = nil
        return nil
    end

    -- Collect all SpecData entries for this spec ID
    -- Skip placeholder entries (specId == 0) — Devourer DH until real ID is known
    local candidates = {}
    for _, entry in ipairs(StatForge.SPEC_DATA) do
        if entry.specId == specId then
            candidates[#candidates + 1] = entry
        end
    end

    if #candidates == 0 then
        -- Spec not yet in data file (new Midnight spec, or data needs update)
        currentSpec = nil
        StatForge.State.NotifyChange("spec")
        return nil
    end

    -- Single entry for this spec — no hero talent ambiguity
    if #candidates == 1 then
        currentSpec = {
            specId            = specId,
            heroTalent        = candidates[1].heroTalent,
            heroTalentName    = candidates[1].heroTalentName,
            heroTalentUnknown = false,
            specEntry         = candidates[1],
        }
        StatForge.State.NotifyChange("spec")
        return currentSpec
    end

    -- Multiple entries — attempt hero talent detection via sentinel spells
    for _, entry in ipairs(candidates) do
        if entry.sentinelSpellId and entry.sentinelSpellId ~= 0 then
            if IsPlayerSpell(entry.sentinelSpellId) then
                currentSpec = {
                    specId            = specId,
                    heroTalent        = entry.heroTalent,
                    heroTalentName    = entry.heroTalentName,
                    heroTalentUnknown = false,
                    specEntry         = entry,
                }
                StatForge.State.NotifyChange("spec")
                return currentSpec
            end
        end
    end

    -- Fallback: sentinel spell IDs not yet populated for this spec.
    -- Use first candidate and flag as unknown so the UI can prompt the user.
    currentSpec = {
        specId            = specId,
        heroTalent        = candidates[1].heroTalent,
        heroTalentName    = candidates[1].heroTalentName,
        heroTalentUnknown = true,
        specEntry         = candidates[1],
    }
    StatForge.State.NotifyChange("spec")
    return currentSpec
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Returns the cached detection result without re-running detection.
function SpecDetector.GetCurrent()
    return currentSpec
end

-- Returns the active priority list for the current spec+hero talent,
-- applying any user override from State. Returns nil if spec is unknown.
function SpecDetector.GetPriority()
    if not currentSpec then return nil end

    local override = StatForge.State.GetSpecOverride(
        currentSpec.specId, currentSpec.heroTalent)
    if override and override.priority then
        return override.priority
    end

    return currentSpec.specEntry and currentSpec.specEntry.priority
end

-- Returns the notes string for the active spec entry, or nil.
function SpecDetector.GetNotes()
    if not currentSpec or not currentSpec.specEntry then return nil end
    return currentSpec.specEntry.notes
end

-- ── Event registration ────────────────────────────────────────────────────────

function SpecDetector.Init()
    local frame = CreateFrame("Frame", "StatForgeSpecDetectorFrame")

    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Defer one frame — talent data from C_Traits isn't always ready
            -- at the exact moment PLAYER_ENTERING_WORLD fires
            C_Timer.After(0, SpecDetector.Detect)
        else
            SpecDetector.Detect()
        end
    end)

    -- Attempt an immediate detect in case PLAYER_ENTERING_WORLD already fired
    -- (shouldn't happen, but handles edge cases like manual addon loads)
    SpecDetector.Detect()
end

-- ── Debug helper ──────────────────────────────────────────────────────────────

-- Prints current spec detection result and checks all sentinel spell IDs for
-- this spec against IsPlayerSpell(). Run via /statforge debug to verify detection
-- and to identify which spell IDs are still missing (sentinelSpellId = 0).
function SpecDetector.PrintDebugInfo()
    local lines = {}
    local function p(msg)
        lines[#lines + 1] = tostring(msg)
        print("|cff00ccffStatForge Debug:|r " .. tostring(msg))
    end

    local specIndex = GetSpecialization()
    if not specIndex or specIndex == 0 then
        p("GetSpecialization() = nil/0 — are you in the world?"); return
    end
    local specId, specName = GetSpecializationInfo(specIndex)
    p(string.format("specIndex=%d  specId=%d  name=%s", specIndex, specId, tostring(specName)))

    -- Show what Detect() resolved
    local cur = currentSpec
    if cur then
        p(string.format("detected: heroTalent=%s  heroTalentName=%s  unknown=%s",
            cur.heroTalent, cur.heroTalentName, tostring(cur.heroTalentUnknown)))
    else
        p("detected: nil (no candidates for this specId)")
    end

    -- Check sentinel spells for all candidates of this spec
    p("--- Sentinel spell check ---")
    for _, entry in ipairs(StatForge.SPEC_DATA) do
        if entry.specId == specId then
            local spellId = entry.sentinelSpellId or 0
            local known   = (spellId ~= 0) and IsPlayerSpell(spellId)
            p(string.format("  %-30s  spellId=%-8s  IsPlayerSpell=%s",
                entry.heroTalentName,
                spellId ~= 0 and tostring(spellId) or "MISSING",
                spellId ~= 0 and tostring(known) or "n/a"))
        end
    end

    local report = table.concat(lines, "\n")
    StatForgeDB.debugLog = report
    print("|cff00ccffStatForge Debug:|r /reload then check SavedVariables/StatForge.lua -> debugLog")
    if C_Clipboard and C_Clipboard.SetText then
        pcall(C_Clipboard.SetText, report)
    end
end
