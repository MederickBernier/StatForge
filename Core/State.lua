-- StatForge/Core/State.lua
-- Owns StatForgeDB (SavedVariables). Central sandbox state, saved setup CRUD,
-- and a simple observer bus so UI frames react to any state mutation.

StatForge.State = {}

local State = StatForge.State

-- Default DB shape — merged over saved data on load
local DB_DEFAULTS = {
    sandbox = {
        gearOverrides  = {},   -- [slotKey] = itemLink
        appliedSources = {},   -- [sourceKey] = { enabled=bool, rank=1|2 }
        optPath        = StatForge.OPT_PATHS.PRIORITY,
    },
    setups       = {},         -- [name] = serialized sandbox snapshot
    minimapAngle = 225,
    specOverrides = {},        -- [specId..heroTalent] = { priority=[...] }  (user escape hatch)
}

-- ── Observer bus ──────────────────────────────────────────────────────────────

local listeners = {}

function State.OnChange(callback)
    listeners[#listeners + 1] = callback
end

local function FireChange(reason)
    for _, cb in ipairs(listeners) do
        cb(reason)
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function State.Init()
    -- StatForgeDB is populated from SavedVariables before ADDON_LOADED fires
    StatForgeDB = StatForgeDB or {}

    -- Deep-merge defaults into saved data so new keys appear without wiping saves
    local function mergeDefaults(target, defaults)
        for k, v in pairs(defaults) do
            if target[k] == nil then
                if type(v) == "table" then
                    target[k] = {}
                    mergeDefaults(target[k], v)
                else
                    target[k] = v
                end
            elseif type(v) == "table" and type(target[k]) == "table" then
                mergeDefaults(target[k], v)
            end
        end
    end

    mergeDefaults(StatForgeDB, DB_DEFAULTS)
end

-- ── Sandbox accessors ─────────────────────────────────────────────────────────

function State.GetSandbox()
    return StatForgeDB.sandbox
end

function State.ResetSandbox()
    StatForgeDB.sandbox = {
        gearOverrides  = {},
        appliedSources = {},
        optPath        = StatForge.OPT_PATHS.PRIORITY,
    }
    FireChange("reset")
end

-- Gear overrides (hypothetical bag-item swaps)

function State.SetGearOverride(slotKey, itemLink)
    StatForgeDB.sandbox.gearOverrides[slotKey] = itemLink
    FireChange("gear")
end

function State.ClearGearOverride(slotKey)
    StatForgeDB.sandbox.gearOverrides[slotKey] = nil
    FireChange("gear")
end

function State.GetGearOverride(slotKey)
    return StatForgeDB.sandbox.gearOverrides[slotKey]
end

-- Applied sources (gems, enchants, consumables)

function State.SetAppliedSource(sourceKey, enabled, rank)
    StatForgeDB.sandbox.appliedSources[sourceKey] = {
        enabled = enabled,
        rank    = rank or 1,
    }
    FireChange("applied")
end

function State.GetAppliedSource(sourceKey)
    return StatForgeDB.sandbox.appliedSources[sourceKey]
        or { enabled = false, rank = 1 }
end

function State.ToggleAppliedSource(sourceKey)
    local src = State.GetAppliedSource(sourceKey)
    State.SetAppliedSource(sourceKey, not src.enabled, src.rank)
end

function State.SetAppliedSourceRank(sourceKey, rank)
    local src = State.GetAppliedSource(sourceKey)
    State.SetAppliedSource(sourceKey, src.enabled, rank)
end

-- Group toggle: enable/disable all sources of a given type
function State.SetGroupEnabled(sourceType, enabled)
    for key, entry in pairs(StatForgeDB.sandbox.appliedSources) do
        -- sourceKey format: "type:name:slot"
        if key:match("^" .. sourceType .. ":") then
            entry.enabled = enabled
        end
    end
    FireChange("applied")
end

-- Optimization path

function State.SetOptPath(path)
    StatForgeDB.sandbox.optPath = path
    FireChange("optpath")
end

function State.GetOptPath()
    return StatForgeDB.sandbox.optPath or StatForge.OPT_PATHS.PRIORITY
end

-- ── Setup snapshot helpers ────────────────────────────────────────────────────

-- Deep-copy a table (no metatables, plain data only)
local function deepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function snapshotSandbox()
    return deepCopy(StatForgeDB.sandbox)
end

local function restoreSandbox(snapshot)
    StatForgeDB.sandbox = deepCopy(snapshot)
    FireChange("load")
end

-- ── Setup CRUD ────────────────────────────────────────────────────────────────

function State.GetSetupList()
    local names = {}
    for name in pairs(StatForgeDB.setups) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function State.SetupExists(name)
    return StatForgeDB.setups[name] ~= nil
end

function State.SaveSetup(name)
    if not name or name == "" then return false, "Name cannot be empty." end
    StatForgeDB.setups[name] = snapshotSandbox()
    FireChange("setups")
    return true
end

function State.LoadSetup(name)
    local snapshot = StatForgeDB.setups[name]
    if not snapshot then return false, "Setup not found: " .. tostring(name) end
    restoreSandbox(snapshot)
    return true
end

function State.DeleteSetup(name)
    if not StatForgeDB.setups[name] then
        return false, "Setup not found: " .. tostring(name)
    end
    StatForgeDB.setups[name] = nil
    FireChange("setups")
    return true
end

function State.RenameSetup(oldName, newName)
    if not newName or newName == "" then return false, "New name cannot be empty." end
    if not StatForgeDB.setups[oldName] then
        return false, "Setup not found: " .. tostring(oldName)
    end
    if StatForgeDB.setups[newName] then
        return false, "A setup named '" .. newName .. "' already exists."
    end
    StatForgeDB.setups[newName] = StatForgeDB.setups[oldName]
    StatForgeDB.setups[oldName] = nil
    FireChange("setups")
    return true
end

function State.DuplicateSetup(name, newName)
    if not newName or newName == "" then return false, "New name cannot be empty." end
    if not StatForgeDB.setups[name] then
        return false, "Setup not found: " .. tostring(name)
    end
    if StatForgeDB.setups[newName] then
        return false, "A setup named '" .. newName .. "' already exists."
    end
    StatForgeDB.setups[newName] = deepCopy(StatForgeDB.setups[name])
    FireChange("setups")
    return true
end

-- ── Spec priority overrides (user escape hatch) ───────────────────────────────

function State.GetSpecOverride(specId, heroTalent)
    local key = tostring(specId) .. ":" .. tostring(heroTalent)
    return StatForgeDB.specOverrides[key]
end

function State.SetSpecOverride(specId, heroTalent, priorityList)
    local key = tostring(specId) .. ":" .. tostring(heroTalent)
    StatForgeDB.specOverrides[key] = deepCopy(priorityList)
end

function State.ClearSpecOverride(specId, heroTalent)
    local key = tostring(specId) .. ":" .. tostring(heroTalent)
    StatForgeDB.specOverrides[key] = nil
end

-- ── Minimap angle ─────────────────────────────────────────────────────────────

function State.GetMinimapAngle()
    return StatForgeDB.minimapAngle or 225
end

function State.SetMinimapAngle(angle)
    StatForgeDB.minimapAngle = angle
end
