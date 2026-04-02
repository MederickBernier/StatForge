-- StatForge/Modules/ImportExport.lua
-- Serializes and deserializes sandbox snapshots for cross-character sharing.
--
-- Share string format:  SF:1:<base64-encoded-payload>
-- Payload format: newline-separated key=value pairs (split on first '='):
--   v={version}
--   o={optPath}
--   g.{slotKey}={itemLink}
--   a.{sourceKey}={0|1},{rank}
--
-- No external libraries — pure Lua base64 + custom serialization.

StatForge.ImportExport = {}

local ImportExport = StatForge.ImportExport

local SHARE_VERSION = "1"
local PREFIX        = "SF:" .. SHARE_VERSION .. ":"

-- ── Base64 ────────────────────────────────────────────────────────────────────

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local B64_DEC = {}
for i = 1, #B64 do
    B64_DEC[B64:sub(i, i)] = i - 1
end

local function b64Encode(data)
    local out = {}
    local len = #data
    local i   = 1
    while i <= len do
        local b1 = data:byte(i)     or 0
        local b2 = data:byte(i + 1) or 0
        local b3 = data:byte(i + 2) or 0
        local n  = b1 * 65536 + b2 * 256 + b3

        out[#out + 1] = B64:sub(math.floor(n / 262144) % 64 + 1,
                                math.floor(n / 262144) % 64 + 1)
        out[#out + 1] = B64:sub(math.floor(n /   4096) % 64 + 1,
                                math.floor(n /   4096) % 64 + 1)
        out[#out + 1] = (i + 1 <= len)
            and B64:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
            or  "="
        out[#out + 1] = (i + 2 <= len)
            and B64:sub(n % 64 + 1, n % 64 + 1)
            or  "="
        i = i + 3
    end
    return table.concat(out)
end

local function b64Decode(data)
    data = data:gsub("[^A-Za-z0-9+/=]", "")
    local out = {}
    local i   = 1
    while i <= #data do
        local c1 = B64_DEC[data:sub(i,   i)  ] or 0
        local c2 = B64_DEC[data:sub(i+1, i+1)] or 0
        local c3 = B64_DEC[data:sub(i+2, i+2)] or 0
        local c4 = B64_DEC[data:sub(i+3, i+3)] or 0
        local n  = c1 * 262144 + c2 * 4096 + c3 * 64 + c4

        out[#out + 1] = string.char(math.floor(n / 65536) % 256)
        if data:sub(i+2, i+2) ~= "=" then
            out[#out + 1] = string.char(math.floor(n / 256) % 256)
        end
        if data:sub(i+3, i+3) ~= "=" then
            out[#out + 1] = string.char(n % 256)
        end
        i = i + 4
    end
    return table.concat(out)
end

-- ── Serialization ─────────────────────────────────────────────────────────────

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = deepCopy(v) end
    return c
end

local function serialize(sandbox)
    local lines = {}
    lines[#lines + 1] = "v=" .. SHARE_VERSION
    lines[#lines + 1] = "o=" .. tostring(sandbox.optPath or StatForge.OPT_PATHS.PRIORITY)

    -- Gear overrides — stable sort by slot key
    if sandbox.gearOverrides then
        local keys = {}
        for k in pairs(sandbox.gearOverrides) do keys[#keys + 1] = k end
        table.sort(keys)
        for _, slotKey in ipairs(keys) do
            local link = sandbox.gearOverrides[slotKey]
            if link and link ~= "" then
                lines[#lines + 1] = "g." .. slotKey .. "=" .. link
            end
        end
    end

    -- Applied sources — stable sort by source key
    if sandbox.appliedSources then
        local keys = {}
        for k in pairs(sandbox.appliedSources) do keys[#keys + 1] = k end
        table.sort(keys)
        for _, sourceKey in ipairs(keys) do
            local src = sandbox.appliedSources[sourceKey]
            if src then
                local en = src.enabled and "1" or "0"
                lines[#lines + 1] = "a." .. sourceKey .. "=" .. en .. "," .. tostring(src.rank or 1)
            end
        end
    end

    return table.concat(lines, "\n")
end

local function deserialize(str)
    local sandbox = {
        gearOverrides  = {},
        appliedSources = {},
        optPath        = StatForge.OPT_PATHS.PRIORITY,
    }

    -- Iterate lines; split each on the first '=' only
    for line in (str .. "\n"):gmatch("([^\n]*)\n") do
        local eqPos = line:find("=", 1, true)
        if eqPos then
            local key   = line:sub(1, eqPos - 1)
            local value = line:sub(eqPos + 1)

            if key == "o" then
                sandbox.optPath = value

            elseif key:sub(1, 2) == "g." then
                local slotKey = key:sub(3)
                if slotKey ~= "" and value ~= "" then
                    sandbox.gearOverrides[slotKey] = value
                end

            elseif key:sub(1, 2) == "a." then
                local sourceKey = key:sub(3)
                local en, rank  = value:match("^([01]),(%d+)$")
                if en and sourceKey ~= "" then
                    sandbox.appliedSources[sourceKey] = {
                        enabled = (en == "1"),
                        rank    = tonumber(rank) or 1,
                    }
                end
            end
        end
    end

    return sandbox
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Export a named saved setup to a share string.
-- Returns the share string, or nil + error message.
function ImportExport.Export(setupName)
    if not StatForgeDB or not StatForgeDB.setups then
        return nil, "No saved data available."
    end
    local snapshot = StatForgeDB.setups[setupName]
    if not snapshot then
        return nil, "Setup not found: " .. tostring(setupName)
    end
    local ok, result = pcall(function()
        return PREFIX .. b64Encode(serialize(snapshot))
    end)
    if not ok then
        return nil, "Export failed: " .. tostring(result)
    end
    return result
end

-- Export the current live sandbox (unsaved state) to a share string.
function ImportExport.ExportCurrent()
    local ok, result = pcall(function()
        return PREFIX .. b64Encode(serialize(StatForge.State.GetSandbox()))
    end)
    if not ok then
        return nil, "Export failed: " .. tostring(result)
    end
    return result
end

-- Decode a share string. Returns the sandbox table, or nil + error message.
function ImportExport.Import(str)
    if not str or strtrim(str) == "" then
        return nil, "Empty import string."
    end
    str = strtrim(str)

    if str:sub(1, #PREFIX) ~= PREFIX then
        return nil, "Not a StatForge share string (expected prefix '" .. PREFIX .. "')."
    end

    local encoded = str:sub(#PREFIX + 1)
    local ok, decoded = pcall(b64Decode, encoded)
    if not ok or not decoded then
        return nil, "Failed to decode base64 payload."
    end

    local sandbox = deserialize(decoded)
    return sandbox
end

-- Returns a human-readable summary of a decoded sandbox for confirmation dialogs.
function ImportExport.Preview(sandbox)
    if not sandbox then return "Invalid data." end

    local gearCount    = 0
    local enabledCount = 0
    local totalCount   = 0

    for _ in pairs(sandbox.gearOverrides  or {}) do gearCount    = gearCount    + 1 end
    for _, src in pairs(sandbox.appliedSources or {}) do
        totalCount = totalCount + 1
        if src.enabled then enabledCount = enabledCount + 1 end
    end

    local lines = {
        "Optimization path : " .. tostring(sandbox.optPath or "priority"),
        "Gear swaps        : " .. gearCount,
        "Applied sources   : " .. enabledCount .. " enabled / " .. totalCount .. " total",
    }
    return table.concat(lines, "\n")
end

-- Save an imported sandbox as a new named setup.
-- Returns true, or false + error message.
function ImportExport.ImportAsSetup(sandbox, name)
    if not name or strtrim(name) == "" then
        return false, "Name cannot be empty."
    end
    if StatForge.State.SetupExists(name) then
        return false, "A setup named '" .. name .. "' already exists."
    end
    StatForgeDB.setups[name] = deepCopy(sandbox)
    StatForge.State.NotifyChange("setups")
    return true
end
