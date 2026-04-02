-- StatForge/Modules/StatEngine.lua
-- Pure stat aggregation. No side effects, no API calls.
-- All inputs are plain tables; returns a flat stat totals table.
--
-- Primary entry point:
--   StatForge.StatEngine.Calculate(sandbox, gearData) -> totals
--
-- totals shape: { [internalStatKey] = number }
-- Internal stat keys are the short keys from StatForge.STAT_KEY_MAP
-- (e.g. "crit", "haste", "mastery", "versatility", "strength")

StatForge.StatEngine = {}

local StatEngine = StatForge.StatEngine

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- Convert a full WoW stat key (e.g. "ITEM_MOD_CRIT_RATING_SHORT") to the
-- internal short key (e.g. "crit"). Returns nil for unknown keys.
local function ToShortKey(fullKey)
    return StatForge.STAT_KEY_REVERSE[fullKey]
end

-- Add all entries from src table into dst table (in-place, short keys only).
-- src keys may be either full WoW keys or internal short keys.
local function MergeStats(dst, src)
    if not src then return end
    for k, v in pairs(src) do
        local shortKey = StatForge.STAT_KEY_REVERSE[k] or
                         (StatForge.STAT_KEY_MAP[k] and k) -- already a short key
        if shortKey then
            dst[shortKey] = (dst[shortKey] or 0) + v
        end
    end
end

-- ── Core calculation ─────────────────────────────────────────────────────────

-- Calculate the full stat vector for the current sandbox state.
--
-- Parameters:
--   sandbox   from State.GetSandbox()
--   gearData  from GearScanner.GetData()
--
-- Returns a new table: { [shortStatKey] = totalValue }
function StatEngine.Calculate(sandbox, gearData)
    local totals = {}

    -- 1. Gear stats — use sandbox override if a bag item is swapped in, otherwise equipped
    for _, slotKey in ipairs(StatForge.SLOT_ORDER) do
        local overrideLink = sandbox.gearOverrides and sandbox.gearOverrides[slotKey]
        local item

        if overrideLink then
            -- Hypothetical swap: find this link in gearData.bagItems
            local candidates = gearData.bagItems and gearData.bagItems[slotKey]
            if candidates then
                for _, candidate in ipairs(candidates) do
                    if candidate.link == overrideLink then
                        item = candidate
                        break
                    end
                end
            end
            -- Fallback: re-query stats from the link directly if not found in cache
            if not item then
                local stats = {}
                GetItemStats(overrideLink, stats)
                item = { stats = stats }
            end
        else
            item = gearData.equipped and gearData.equipped[slotKey]
        end

        if item and item.stats then
            MergeStats(totals, item.stats)
        end
    end

    -- 2. Applied sources — gems, enchants, consumables
    if sandbox.appliedSources then
        for sourceKey, entry in pairs(sandbox.appliedSources) do
            if entry.enabled then
                -- sourceKey format: "gem:masterful" or "enchant:neck_haste" etc.
                -- The base key (without per-slot suffix) maps to APPLIED_INDEX
                local baseKey = sourceKey:match("^([^|]+)")
                local sourceData = StatForge.APPLIED_INDEX and StatForge.APPLIED_INDEX[baseKey]
                if sourceData then
                    local rankStats = (entry.rank == 2) and sourceData.rank2 or sourceData.rank1
                    if rankStats then
                        -- For flask/augment that give primary stats, only add the stat
                        -- matching the player's primary (engine is class-agnostic — add all;
                        -- SpecDetector provides context for display filtering in the UI)
                        MergeStats(totals, rankStats)
                    end
                end
            end
        end
    end

    return totals
end

-- ── Priority evaluation ───────────────────────────────────────────────────────

-- Given a stat totals table and a priority list (array of short stat keys),
-- return a new table: { [shortStatKey] = priorityRank (1 = best) }
-- Stats not in the priority list get rank = #priority + 1.
function StatEngine.RankStats(totals, priorityList)
    if not priorityList then return {} end
    local ranks = {}
    local unranked = #priorityList + 1
    for shortKey in pairs(totals) do
        ranks[shortKey] = unranked
    end
    for i, shortKey in ipairs(priorityList) do
        if totals[shortKey] then
            ranks[shortKey] = i
        end
    end
    return ranks
end

-- ── Convenience wrapper ───────────────────────────────────────────────────────

-- Full recalc using current live state and gear data.
-- Returns { totals, ranks } where ranks is nil if no spec is detected.
function StatEngine.Recalculate()
    local sandbox  = StatForge.State.GetSandbox()
    local gearData = StatForge.GearScanner.GetData()
    local totals   = StatEngine.Calculate(sandbox, gearData)

    local specInfo = StatForge.SpecDetector and StatForge.SpecDetector.GetCurrent()
    local ranks    = nil
    if specInfo then
        local key   = tostring(specInfo.specId) .. ":" .. specInfo.heroTalent
        local entry = StatForge.SPEC_INDEX and StatForge.SPEC_INDEX[key]
        if entry then
            -- Also merge user override if present
            local override = StatForge.State.GetSpecOverride(specInfo.specId, specInfo.heroTalent)
            local priority = (override and override.priority) or entry.priority
            ranks = StatEngine.RankStats(totals, priority)
        end
    end

    return totals, ranks
end
