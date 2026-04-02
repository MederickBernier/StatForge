-- StatForge/Modules/GearScanner.lua
-- Reads equipped gear and bag alternatives using the modern C_Container API.
-- Does NOT mutate State — calls State.NotifyChange() so observers can react.
--
-- gearData shape:
--   equipped[slotKey] = {
--     link           string    item link
--     stats          table     { [fullStatKey] = value } from GetItemStats()
--     hasEmptySocket boolean
--     isEnchanted    boolean
--     itemId         number
--   }
--   bagItems[slotKey] = array of {
--     link, stats, hasEmptySocket, isEnchanted, itemId
--   }

StatForge.GearScanner = {}

local GearScanner = StatForge.GearScanner

-- Internal cache — modules read this via GearScanner.GetData()
local gearData = {
    equipped = {},
    bagItems = {},
}

-- Slots that can carry an enchant — flagged as "unenchanted" if enchantId == 0
local ENCHANTABLE_SLOTS = {
    neck     = true,
    back     = true,
    chest    = true,
    wrist    = true,
    hands    = true,
    legs     = true,
    feet     = true,
    finger1  = true,
    finger2  = true,
    mainhand = true,
    offhand  = true,
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- Parse enchant ID out of an item hyperlink.
-- Link format: |Hitem:itemID:enchantID:...|h[Name]|h
local function GetEnchantIdFromLink(link)
    if not link then return nil end
    local enchantId = link:match("|Hitem:%d+:(%d+):")
    local id = tonumber(enchantId)
    return (id and id ~= 0) and id or nil
end

-- Check GetItemStats() output for any EMPTY_SOCKET_* key.
local function HasEmptySocket(stats)
    for k in pairs(stats) do
        if k:find("^EMPTY_SOCKET") then
            return true
        end
    end
    return false
end

-- Build a single item record from a link. Returns nil if link is missing.
local function BuildItemRecord(link, slotKey)
    if not link or link == "" then return nil end

    local stats = {}
    C_Item.GetItemStats(link, stats)

    local hasEmpty   = HasEmptySocket(stats)
    local enchantId  = GetEnchantIdFromLink(link)
    local isEnchanted = (enchantId ~= nil)
        or (ENCHANTABLE_SLOTS[slotKey] == nil)  -- non-enchantable slots always "OK"

    -- Extract itemId from link
    local itemId = tonumber(link:match("|Hitem:(%d+):")) or 0

    return {
        link           = link,
        stats          = stats,
        hasEmptySocket = hasEmpty,
        isEnchanted    = isEnchanted,
        itemId         = itemId,
    }
end

-- ── Equipped scan ─────────────────────────────────────────────────────────────

function GearScanner.ScanEquipped()
    for _, slotKey in ipairs(StatForge.SLOT_ORDER) do
        local slotId = StatForge.SLOT_IDS[slotKey]
        local link   = GetInventoryItemLink("player", slotId)
        gearData.equipped[slotKey] = BuildItemRecord(link, slotKey)
    end
end

-- ── Bag scan ──────────────────────────────────────────────────────────────────

function GearScanner.ScanBags()
    -- Reset bag item lists for all slots
    for _, slotKey in ipairs(StatForge.SLOT_ORDER) do
        gearData.bagItems[slotKey] = {}
    end

    -- Iterate all bag containers (0 = backpack, 1-4 = bag slots)
    for bagId = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bagId)
        if numSlots and numSlots > 0 then
            for slotIndex = 1, numSlots do
                local info = C_Container.GetContainerItemInfo(bagId, slotIndex)
                if info and info.hyperlink and info.itemID then
                    -- Get the equip location string for this item
                    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfoInstant(info.itemID)
                    if equipLoc and equipLoc ~= "" then
                        local targetSlots = StatForge.INVTYPE_TO_SLOTS[equipLoc]
                        if targetSlots then
                            local record = BuildItemRecord(info.hyperlink, targetSlots[1])
                            if record then
                                for _, slotKey in ipairs(targetSlots) do
                                    gearData.bagItems[slotKey] = gearData.bagItems[slotKey] or {}
                                    -- Avoid duplicate entries (same item can appear in multiple
                                    -- target slots for INVTYPE_FINGER / INVTYPE_TRINKET)
                                    gearData.bagItems[slotKey][#gearData.bagItems[slotKey] + 1] = record
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ── Public API ────────────────────────────────────────────────────────────────

function GearScanner.GetData()
    return gearData
end

-- Full scan (equipped + bags) — called on addon load and can be called manually.
function GearScanner.Scan()
    GearScanner.ScanEquipped()
    GearScanner.ScanBags()
    StatForge.State.NotifyChange("gear")
end

-- ── Event registration ────────────────────────────────────────────────────────

function GearScanner.Init()
    local frame = CreateFrame("Frame", "StatForgeGearScannerFrame")

    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_EQUIPMENT_CHANGED" then
            -- arg1 = slotId, arg2 = hasCurrent (bool)
            GearScanner.ScanEquipped()
            StatForge.State.NotifyChange("gear")
        elseif event == "BAG_UPDATE_DELAYED" then
            GearScanner.ScanBags()
            StatForge.State.NotifyChange("bags")
        end
    end)

    -- Initial scan on load
    GearScanner.Scan()
end
