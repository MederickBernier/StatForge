-- StatForge/Modules/ShoppingList.lua
-- Derives the list of applied sources currently enabled in the sandbox.
-- Pure read — no side effects, no API calls.
--
-- Generate() → array of { key, name, type, slot, rank }
-- FormatText(items) → multiline string for clipboard / chat paste

StatForge.ShoppingList = {}

local ShoppingList = StatForge.ShoppingList

local TYPE_ORDER = {
    [StatForge.SOURCE_TYPES.GEM]        = 1,
    [StatForge.SOURCE_TYPES.ENCHANT]    = 2,
    [StatForge.SOURCE_TYPES.CONSUMABLE] = 3,
}

local TYPE_LABELS = {
    [StatForge.SOURCE_TYPES.GEM]        = "Gems",
    [StatForge.SOURCE_TYPES.ENCHANT]    = "Enchants",
    [StatForge.SOURCE_TYPES.CONSUMABLE] = "Consumables",
}

-- ── Public API ────────────────────────────────────────────────────────────────

-- Returns an array of enabled applied-source entries, sorted by type then name.
-- Each element: { key, name, type, slot, rank }
function ShoppingList.Generate()
    local sandbox = StatForge.State.GetSandbox()
    local items   = {}

    for sourceKey, entry in pairs(sandbox.appliedSources) do
        if entry.enabled then
            -- Strip optional per-slot suffix (e.g. "gem:masterful|head" → "gem:masterful")
            local baseKey    = sourceKey:match("^([^|]+)")
            local sourceData = StatForge.APPLIED_INDEX and StatForge.APPLIED_INDEX[baseKey]
            if sourceData then
                items[#items + 1] = {
                    key  = sourceKey,
                    name = sourceData.name,
                    type = sourceData.type,
                    slot = sourceData.slot,
                    rank = entry.rank or 1,
                }
            end
        end
    end

    table.sort(items, function(a, b)
        local ta = TYPE_ORDER[a.type] or 9
        local tb = TYPE_ORDER[b.type] or 9
        if ta ~= tb then return ta < tb end
        return a.name < b.name
    end)

    return items
end

-- Formats the shopping list as a plain multiline string.
function ShoppingList.FormatText(items)
    if not items or #items == 0 then
        return "Shopping list is empty — enable some gems, enchants, or consumables."
    end

    local lines    = {}
    local lastType = nil

    for _, item in ipairs(items) do
        if item.type ~= lastType then
            if lastType then lines[#lines + 1] = "" end
            lines[#lines + 1] = "=== " .. (TYPE_LABELS[item.type] or item.type) .. " ==="
            lastType = item.type
        end
        local rankStr = (item.rank == 2) and " [R2]" or " [R1]"
        lines[#lines + 1] = "  " .. item.name .. rankStr
    end

    return table.concat(lines, "\n")
end
