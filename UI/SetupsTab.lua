-- StatForge/UI/SetupsTab.lua
-- Barebone setups tab: save current sandbox, load/delete saved setups.

StatForge.SetupsTab = {}
local SetupsTab = StatForge.SetupsTab

local ROW_H     = 22
local PAD       = 8
local CONTENT_W = 804
local CONTENT_H = 446

local tabFrame   = nil
local listParent = nil   -- Frame that holds the dynamic setup rows
local rowPool    = {}    -- reuse row frames to avoid leaking

-- ── Build row pool ────────────────────────────────────────────────────────────

local function GetRow(index)
    local row = rowPool[index]
    if not row then
        row = CreateFrame("Frame", nil, listParent)
        row:SetSize(CONTENT_W - PAD*2, ROW_H)

        local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLbl:SetPoint("LEFT", 0, 0)
        nameLbl:SetWidth(CONTENT_W - PAD*2 - 130)
        nameLbl:SetJustifyH("LEFT")
        nameLbl:SetTextColor(0.88, 0.88, 0.88, 1)
        row.nameLbl = nameLbl

        local loadBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        loadBtn:SetSize(60, ROW_H - 2)
        loadBtn:SetPoint("RIGHT", row, "RIGHT", -68, 0)
        loadBtn:SetText("Load")
        row.loadBtn = loadBtn

        local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        delBtn:SetSize(60, ROW_H - 2)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        delBtn:SetText("Delete")
        row.delBtn = delBtn

        rowPool[index] = row
    end
    return row
end

-- ── Refresh setup list ────────────────────────────────────────────────────────

local function RefreshList()
    if not listParent then return end

    local names  = StatForge.State.GetSetupList()
    local yOff   = 0

    for i, name in ipairs(names) do
        local row = GetRow(i)
        row:SetPoint("TOPLEFT", listParent, "TOPLEFT", 0, -yOff)
        row.nameLbl:SetText(name)
        row:Show()

        -- Bind buttons (capture name by value)
        local capName = name
        row.loadBtn:SetScript("OnClick", function()
            local ok, err = StatForge.State.LoadSetup(capName)
            if not ok then
                print("|cff00ccffStatForge:|r " .. tostring(err))
            end
        end)
        row.delBtn:SetScript("OnClick", function()
            StaticPopup_Show("STATFORGE_CONFIRM_DELETE", capName, nil, capName)
        end)

        yOff = yOff + ROW_H + 2
    end

    -- Hide unused rows
    for i = #names+1, #rowPool do
        if rowPool[i] then rowPool[i]:Hide() end
    end

    listParent:SetHeight(math.max(yOff, 10))
end

function SetupsTab.Refresh()
    if not tabFrame or not tabFrame:IsShown() then return end
    RefreshList()
end

-- ── Delete confirmation popup ─────────────────────────────────────────────────

StaticPopupDialogs["STATFORGE_CONFIRM_DELETE"] = {
    text        = "Delete setup \"%s\"?",
    button1     = "Delete",
    button2     = "Cancel",
    OnAccept    = function(self, data)
        local ok, err = StatForge.State.DeleteSetup(data)
        if not ok then
            print("|cff00ccffStatForge:|r " .. tostring(err))
        end
    end,
    whileDead   = true,
    hideOnEscape = true,
}

-- ── Build ─────────────────────────────────────────────────────────────────────

function SetupsTab.Build(contentFrame)
    tabFrame = CreateFrame("Frame", nil, contentFrame)
    tabFrame:SetAllPoints(contentFrame)
    tabFrame:Hide()

    -- ── Header row: name input + save button ──────────────────────────────────
    local saveLabel = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    saveLabel:SetPoint("TOPLEFT", PAD, 0)
    saveLabel:SetText("Save current as:")
    saveLabel:SetTextColor(0.65, 0.65, 0.75, 1)

    local nameBox = CreateFrame("EditBox", "StatForgeSetupNameBox", tabFrame, "InputBoxTemplate")
    nameBox:SetSize(240, 24)
    nameBox:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", PAD, -20)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(64)

    local saveBtn = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    saveBtn:SetSize(80, 24)
    saveBtn:SetPoint("LEFT", nameBox, "RIGHT", 8, 0)
    saveBtn:SetText("Save")

    saveBtn:SetScript("OnClick", function()
        local name = strtrim(nameBox:GetText())
        if name == "" then
            print("|cff00ccffStatForge:|r Name cannot be empty.")
            return
        end
        local ok, err = StatForge.State.SaveSetup(name)
        if ok then
            nameBox:SetText("")
            print("|cff00ccffStatForge:|r Saved setup \"" .. name .. "\".")
        else
            print("|cff00ccffStatForge:|r " .. tostring(err))
        end
    end)

    -- Allow Enter key to save
    nameBox:SetScript("OnEnterPressed", function(self)
        saveBtn:Click()
        self:ClearFocus()
    end)

    -- ── Separator ──────────────────────────────────────────────────────────────
    local sep = tabFrame:CreateTexture(nil, "BACKGROUND")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  tabFrame, "TOPLEFT",  PAD, -52)
    sep:SetPoint("TOPRIGHT", tabFrame, "TOPRIGHT", -PAD, -52)
    sep:SetColorTexture(0.20, 0.20, 0.26, 1)

    -- ── Column labels ──────────────────────────────────────────────────────────
    local colHdr = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colHdr:SetPoint("TOPLEFT", PAD, -58)
    colHdr:SetText("SAVED SETUPS")
    colHdr:SetTextColor(0.48, 0.68, 1, 1)

    -- ── Scroll frame for setup list ───────────────────────────────────────────
    local sfH = CONTENT_H - 80

    local sf = CreateFrame("ScrollFrame", "StatForgeSetupsScrollFrame",
        tabFrame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",  tabFrame, "TOPLEFT",  PAD,  -76)
    sf:SetSize(CONTENT_W - PAD*2, sfH)

    listParent = CreateFrame("Frame", nil, sf)
    listParent:SetWidth(CONTENT_W - PAD*2 - 20)
    listParent:SetHeight(10)
    sf:SetScrollChild(listParent)

    -- ── Register + subscribe ──────────────────────────────────────────────────
    StatForge.MainWindow.RegisterTabFrame("setups", tabFrame)

    StatForge.State.OnChange(function(reason)
        if reason == "setups" or reason == "load" then
            SetupsTab.Refresh()
        end
    end)

    tabFrame:SetScript("OnShow", function()
        SetupsTab.Refresh()
    end)
end
