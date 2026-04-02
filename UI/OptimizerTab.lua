-- StatForge/UI/OptimizerTab.lua
-- Barebone optimizer tab: gear swaps | applied sources | stat vector.

StatForge.OptimizerTab = {}
local OptimizerTab = StatForge.OptimizerTab

-- ── Layout constants ──────────────────────────────────────────────────────────
local ROW_H     = 20
local SEC_H     = 18
local PAD       = 4
local CONTENT_W = 804
local CONTENT_H = 446
local GEAR_W    = 238   -- left column width
local APPL_W    = 292   -- middle column width
local STAT_X    = GEAR_W + 1 + APPL_W + 1 + PAD  -- right column x offset

local STAT_ORDER = {
    "strength","agility","intellect",
    "crit","haste","mastery","versatility",
    "stamina","attackpower","spellpower",
    "dodge","parry","leech","avoidance","speed",
}

-- ── Module state ──────────────────────────────────────────────────────────────
local tabFrame    = nil
local slotRows    = {}   -- [slotKey] -> { nameLbl }
local applRows    = {}   -- [sourceKey] -> { checkLbl, r1Btn, r2Btn }
local statFrames  = {}   -- [shortKey]  -> { frame, keyLbl, valueLbl }
local specInfoLbl = nil

-- Shared gear swap dropdown (lazy-created, one at a time)
local gearDropdown   = nil
local activeDropSlot = nil

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function LinkName(link)
    if not link then return nil end
    return link:match("|h%[(.-)%]|h")
end

-- ── Gear swap dropdown ────────────────────────────────────────────────────────

local function HideDropdown()
    if gearDropdown then gearDropdown:Hide() end
    activeDropSlot = nil
end

local function ShowDropdown(slotKey, anchor)
    -- Toggle off if same slot clicked again
    if activeDropSlot == slotKey and gearDropdown and gearDropdown:IsShown() then
        HideDropdown(); return
    end

    -- Lazy-create the popup frame
    if not gearDropdown then
        gearDropdown = CreateFrame("Frame", "StatForgeGearDropdown", UIParent, "BackdropTemplate")
        gearDropdown:SetFrameStrata("DIALOG")
        gearDropdown:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 16, edgeSize = 12,
            insets   = { left=3, right=3, top=3, bottom=3 },
        })
        gearDropdown:SetBackdropColor(0.07, 0.07, 0.10, 0.98)
        gearDropdown:SetBackdropBorderColor(0.28, 0.28, 0.40, 1)
        gearDropdown._btns = {}
    end

    -- Build entry list: [reset to equipped] + bag alternatives
    local gd      = StatForge.GearScanner.GetData()
    local eq      = gd.equipped and gd.equipped[slotKey]
    local bagList = (gd.bagItems and gd.bagItems[slotKey]) or {}

    local entries = {}
    local eqName  = (eq and LinkName(eq.link)) or "— empty —"
    entries[1] = { label = "[Reset] " .. eqName, link = nil }
    for _, it in ipairs(bagList) do
        entries[#entries+1] = { label = LinkName(it.link) or "?", link = it.link }
    end

    local n   = #entries
    local ddW = 230
    gearDropdown:SetSize(ddW, PAD * 2 + n * ROW_H)
    gearDropdown:ClearAllPoints()
    gearDropdown:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)

    for i = 1, n do
        local btn = gearDropdown._btns[i]
        if not btn then
            btn = CreateFrame("Button", nil, gearDropdown)
            btn:SetHeight(ROW_H)
            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("LEFT", 4, 0)
            lbl:SetPoint("RIGHT", -4, 0)
            lbl:SetJustifyH("LEFT")
            btn._lbl = lbl
            btn:SetScript("OnEnter", function(b)
                b._lbl:SetTextColor(1, 1, 0.5, 1)
            end)
            btn:SetScript("OnLeave", function(b)
                b._lbl:SetTextColor(b._baseR or 0.88, b._baseG or 0.88, b._baseB or 0.88, 1)
            end)
            gearDropdown._btns[i] = btn
        end
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT",  gearDropdown, "TOPLEFT",  PAD,  -PAD - (i-1)*ROW_H)
        btn:SetPoint("TOPRIGHT", gearDropdown, "TOPRIGHT", -PAD, -PAD - (i-1)*ROW_H)

        local e          = entries[i]
        local br, bg, bb = (i == 1) and 0.50 or 0.88, (i == 1) and 0.78 or 0.88, (i == 1) and 1.0 or 0.88
        btn._lbl:SetText(e.label)
        btn._lbl:SetTextColor(br, bg, bb, 1)
        btn._baseR, btn._baseG, btn._baseB = br, bg, bb
        btn:Show()

        btn:SetScript("OnClick", nil)
        local sk  = slotKey
        local lnk = e.link
        btn:SetScript("OnClick", function()
            if lnk then StatForge.State.SetGearOverride(sk, lnk)
            else        StatForge.State.ClearGearOverride(sk) end
            HideDropdown()
        end)
    end
    for i = n+1, #gearDropdown._btns do
        gearDropdown._btns[i]:Hide()
    end

    activeDropSlot = slotKey
    gearDropdown:Show()
end

-- ── Refresh helpers ───────────────────────────────────────────────────────────

local function RefreshGear()
    local gd = StatForge.GearScanner.GetData()
    local sb = StatForge.State.GetSandbox()

    for _, sk in ipairs(StatForge.SLOT_ORDER) do
        local row = slotRows[sk]
        if row then
            local ov = sb.gearOverrides[sk]
            local item
            if ov then
                for _, c in ipairs((gd.bagItems and gd.bagItems[sk]) or {}) do
                    if c.link == ov then item = c; break end
                end
                if not item then item = { link = ov } end
            else
                item = gd.equipped and gd.equipped[sk]
            end

            local name      = (item and LinkName(item.link)) or "— empty —"
            local r, g, b   = 0.52, 0.52, 0.52
            if item and item.link then
                if ov then r, g, b = 1.0, 0.78, 0.18
                else       r, g, b = 0.88, 0.88, 0.88 end
                if item.hasEmptySocket or (item.isEnchanted == false) then
                    r, g, b = 1.0, 0.50, 0.10
                end
            end
            row.nameLbl:SetText(name)
            row.nameLbl:SetTextColor(r, g, b, 1)
        end
    end
end

local function RefreshApplied()
    local sb = StatForge.State.GetSandbox()
    for sourceKey, row in pairs(applRows) do
        local src  = sb.appliedSources[sourceKey] or { enabled = false, rank = 1 }
        local rank = src.rank or 1
        if src.enabled then
            row.checkLbl:SetText("[x]")
            row.checkLbl:SetTextColor(0.22, 1.0, 0.22, 1)
        else
            row.checkLbl:SetText("[ ]")
            row.checkLbl:SetTextColor(0.42, 0.42, 0.42, 1)
        end
        local r1a = (rank == 1) and 1.0 or 0.32
        local r1b = (rank == 1) and 0.85 or 0.32
        row.r1Btn._lbl:SetTextColor(r1a, r1b, (rank == 1) and 0.20 or 0.32, 1)
        local r2a = (rank == 2) and 1.0 or 0.32
        local r2b = (rank == 2) and 0.85 or 0.32
        row.r2Btn._lbl:SetTextColor(r2a, r2b, (rank == 2) and 0.20 or 0.32, 1)
    end
end

local function RefreshStats()
    -- Spec info label
    local si = StatForge.SpecDetector and StatForge.SpecDetector.GetCurrent()
    if specInfoLbl then
        if si then
            local suffix = si.heroTalentUnknown and " (?)" or ""
            specInfoLbl:SetText(si.heroTalentName .. suffix)
            specInfoLbl:SetTextColor(
                si.heroTalentUnknown and 1.0 or 0.45,
                si.heroTalentUnknown and 0.65 or 0.85,
                si.heroTalentUnknown and 0.15 or 0.45, 1)
        else
            specInfoLbl:SetText("Spec: not detected")
            specInfoLbl:SetTextColor(0.48, 0.48, 0.48, 1)
        end
    end

    -- Stat totals
    local gd       = StatForge.GearScanner.GetData()
    local sb       = StatForge.State.GetSandbox()
    local totals   = StatForge.StatEngine.Calculate(sb, gd)
    local priority = StatForge.SpecDetector and StatForge.SpecDetector.GetPriority()
    local ranks    = priority and StatForge.StatEngine.RankStats(totals, priority)

    -- Build ordered visible list: priority stats first, then the rest
    local visible  = {}
    local inPrio   = {}
    if priority then
        for _, sk in ipairs(priority) do
            inPrio[sk] = true
            if (totals[sk] or 0) > 0 then
                visible[#visible+1] = sk
            end
        end
    end
    for _, sk in ipairs(STAT_ORDER) do
        if not inPrio[sk] and (totals[sk] or 0) > 0 then
            visible[#visible+1] = sk
        end
    end

    -- Hide all stat frames first
    for _, sf in pairs(statFrames) do
        sf.frame:Hide()
    end

    -- Position and show visible ones
    local startY = SEC_H + 2 + ROW_H + 4
    for i, sk in ipairs(visible) do
        local sf = statFrames[sk]
        if sf then
            sf.frame:ClearAllPoints()
            sf.frame:SetPoint("TOPLEFT", tabFrame, "TOPLEFT",
                STAT_X, -(startY + (i-1)*ROW_H))
            sf.frame:Show()
            sf.valueLbl:SetText(tostring(totals[sk]))

            local rank = ranks and ranks[sk]
            if      rank == 1 then sf.keyLbl:SetTextColor(1.00, 0.85, 0.00, 1)
            elseif  rank == 2 then sf.keyLbl:SetTextColor(0.40, 0.80, 1.00, 1)
            elseif  rank == 3 then sf.keyLbl:SetTextColor(0.45, 1.00, 0.40, 1)
            elseif  rank and rank <= 5
                              then sf.keyLbl:SetTextColor(0.80, 0.80, 0.80, 1)
            else                   sf.keyLbl:SetTextColor(0.50, 0.50, 0.50, 1)
            end
        end
    end
end

function OptimizerTab.Refresh()
    if not tabFrame or not tabFrame:IsShown() then return end
    RefreshGear()
    RefreshApplied()
    RefreshStats()
end

-- ── Build ─────────────────────────────────────────────────────────────────────

function OptimizerTab.Build(contentFrame)
    tabFrame = CreateFrame("Frame", nil, contentFrame)
    tabFrame:SetAllPoints(contentFrame)
    tabFrame:Hide()

    -- Column separator lines
    local function MakeSep(x)
        local t = tabFrame:CreateTexture(nil, "BACKGROUND")
        t:SetWidth(1)
        t:SetPoint("TOPLEFT",    tabFrame, "TOPLEFT",    x, -2)
        t:SetPoint("BOTTOMLEFT", tabFrame, "BOTTOMLEFT", x,  2)
        t:SetColorTexture(0.20, 0.20, 0.26, 1)
    end
    MakeSep(GEAR_W)
    MakeSep(GEAR_W + 1 + APPL_W)

    -- ── Left: Gear slots ──────────────────────────────────────────────────────
    do
        local hdr = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hdr:SetPoint("TOPLEFT", 2, 0)
        hdr:SetText("GEAR SLOTS")
        hdr:SetTextColor(0.48, 0.68, 1, 1)

        local yOff = SEC_H + 4

        for _, sk in ipairs(StatForge.SLOT_ORDER) do
            -- Slot label (fixed width)
            local slotLbl = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            slotLbl:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 2, -yOff)
            slotLbl:SetWidth(64)
            slotLbl:SetJustifyH("LEFT")
            slotLbl:SetText(StatForge.SLOT_NAMES[sk])
            slotLbl:SetTextColor(0.48, 0.48, 0.58, 1)

            -- Item name
            local nameLbl = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nameLbl:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 68, -yOff)
            nameLbl:SetWidth(GEAR_W - 68 - 24)
            nameLbl:SetJustifyH("LEFT")
            nameLbl:SetText("—")
            nameLbl:SetTextColor(0.52, 0.52, 0.52, 1)

            -- Swap button
            local swapBtn = CreateFrame("Button", nil, tabFrame)
            swapBtn:SetSize(22, ROW_H)
            swapBtn:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", GEAR_W - 22, -yOff)
            local swapTxt = swapBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            swapTxt:SetAllPoints()
            swapTxt:SetText("v")
            swapTxt:SetTextColor(0.40, 0.40, 0.60, 1)
            swapBtn:SetScript("OnEnter", function() swapTxt:SetTextColor(1, 1, 1, 1) end)
            swapBtn:SetScript("OnLeave", function() swapTxt:SetTextColor(0.40, 0.40, 0.60, 1) end)
            local capSk = sk
            swapBtn:SetScript("OnClick", function() ShowDropdown(capSk, swapBtn) end)

            slotRows[sk] = { nameLbl = nameLbl }
            yOff = yOff + ROW_H
        end
    end

    -- ── Middle: Applied sources (scrollable) ──────────────────────────────────
    do
        local applX = GEAR_W + 1 + PAD

        local hdr = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hdr:SetPoint("TOPLEFT", applX, 0)
        hdr:SetText("APPLIED SOURCES")
        hdr:SetTextColor(0.48, 0.68, 1, 1)

        local sfW = APPL_W - PAD     -- total width of scroll frame
        local sfH = CONTENT_H - SEC_H - 6

        local sf = CreateFrame("ScrollFrame", "StatForgeApplScrollFrame",
            tabFrame, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", applX, -(SEC_H + 4))
        sf:SetSize(sfW, sfH)

        local childW = sfW - 20   -- subtract scrollbar
        local child  = CreateFrame("Frame", nil, sf)
        child:SetWidth(childW)
        sf:SetScrollChild(child)

        local TYPE_ORDER = {
            StatForge.SOURCE_TYPES.GEM,
            StatForge.SOURCE_TYPES.ENCHANT,
            StatForge.SOURCE_TYPES.CONSUMABLE,
        }
        local TYPE_LABELS = {
            [StatForge.SOURCE_TYPES.GEM]        = "Gems",
            [StatForge.SOURCE_TYPES.ENCHANT]    = "Enchants",
            [StatForge.SOURCE_TYPES.CONSUMABLE] = "Consumables",
        }

        local grouped = {}
        for _, t in ipairs(TYPE_ORDER) do grouped[t] = {} end
        for _, e in ipairs(StatForge.APPLIED_DATA or {}) do
            if grouped[e.type] then
                grouped[e.type][#grouped[e.type]+1] = e
            end
        end

        local yOff   = 0
        local totalH = 0

        for _, t in ipairs(TYPE_ORDER) do
            local entries = grouped[t]
            if #entries > 0 then
                local secHdr = child:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                secHdr:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -yOff)
                secHdr:SetText(TYPE_LABELS[t])
                secHdr:SetTextColor(0.70, 0.70, 0.36, 1)
                yOff   = yOff + SEC_H
                totalH = totalH + SEC_H

                for _, entry in ipairs(entries) do
                    -- Toggle button
                    local ckBtn = CreateFrame("Button", nil, child)
                    ckBtn:SetSize(26, ROW_H)
                    ckBtn:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -yOff)
                    local ckLbl = ckBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    ckLbl:SetAllPoints()
                    ckLbl:SetText("[ ]")
                    ckLbl:SetTextColor(0.42, 0.42, 0.42, 1)
                    ckBtn:SetScript("OnEnter", function() ckLbl:SetTextColor(1, 1, 1, 1) end)
                    ckBtn:SetScript("OnLeave", function()
                        local s = StatForge.State.GetAppliedSource(entry.key)
                        if s.enabled then ckLbl:SetTextColor(0.22, 1, 0.22, 1)
                        else              ckLbl:SetTextColor(0.42, 0.42, 0.42, 1) end
                    end)
                    local capKey = entry.key
                    ckBtn:SetScript("OnClick", function()
                        StatForge.State.ToggleAppliedSource(capKey)
                    end)

                    -- Name label
                    local nameLbl = child:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    nameLbl:SetPoint("TOPLEFT", child, "TOPLEFT", 28, -yOff)
                    nameLbl:SetWidth(childW - 28 - 50)
                    nameLbl:SetJustifyH("LEFT")
                    nameLbl:SetText(entry.name)
                    nameLbl:SetTextColor(0.80, 0.80, 0.80, 1)

                    -- R1 button
                    local r1Btn = CreateFrame("Button", nil, child)
                    r1Btn:SetSize(22, ROW_H)
                    r1Btn:SetPoint("TOPLEFT", child, "TOPLEFT", childW - 46, -yOff)
                    local r1Lbl = r1Btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    r1Lbl:SetAllPoints(); r1Lbl:SetText("R1")
                    r1Lbl:SetTextColor(0.32, 0.32, 0.32, 1)
                    r1Btn._lbl = r1Lbl
                    local ck1 = capKey
                    r1Btn:SetScript("OnClick", function()
                        StatForge.State.SetAppliedSourceRank(ck1, 1)
                    end)

                    -- R2 button
                    local r2Btn = CreateFrame("Button", nil, child)
                    r2Btn:SetSize(22, ROW_H)
                    r2Btn:SetPoint("TOPLEFT", child, "TOPLEFT", childW - 22, -yOff)
                    local r2Lbl = r2Btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    r2Lbl:SetAllPoints(); r2Lbl:SetText("R2")
                    r2Lbl:SetTextColor(0.32, 0.32, 0.32, 1)
                    r2Btn._lbl = r2Lbl
                    local ck2 = capKey
                    r2Btn:SetScript("OnClick", function()
                        StatForge.State.SetAppliedSourceRank(ck2, 2)
                    end)

                    applRows[entry.key] = { checkLbl = ckLbl, r1Btn = r1Btn, r2Btn = r2Btn }
                    yOff   = yOff + ROW_H
                    totalH = totalH + ROW_H
                end
                yOff   = yOff + 4
                totalH = totalH + 4
            end
        end

        child:SetHeight(math.max(totalH, 10))
    end

    -- ── Right: Stat vector ────────────────────────────────────────────────────
    do
        local hdr = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hdr:SetPoint("TOPLEFT", STAT_X, 0)
        hdr:SetText("STAT TOTALS")
        hdr:SetTextColor(0.48, 0.68, 1, 1)

        specInfoLbl = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        specInfoLbl:SetPoint("TOPLEFT", STAT_X, -(SEC_H + 2))
        specInfoLbl:SetWidth(CONTENT_W - STAT_X - 4)
        specInfoLbl:SetJustifyH("LEFT")
        specInfoLbl:SetText("—")
        specInfoLbl:SetTextColor(0.48, 0.48, 0.48, 1)

        -- Pre-create one frame per stat (shown/hidden + re-anchored on refresh)
        for _, sk in ipairs(STAT_ORDER) do
            local rf = CreateFrame("Frame", nil, tabFrame)
            rf:SetSize(CONTENT_W - STAT_X - 4, ROW_H)
            rf:Hide()

            local fullKey  = StatForge.STAT_KEY_MAP[sk]
            local dispName = (StatForge.STAT_DISPLAY[fullKey] or sk) .. ":"

            local kLbl = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            kLbl:SetPoint("LEFT", 0, 0)
            kLbl:SetWidth(90)
            kLbl:SetJustifyH("LEFT")
            kLbl:SetText(dispName)
            kLbl:SetTextColor(0.62, 0.62, 0.62, 1)

            local vLbl = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            vLbl:SetPoint("LEFT", 92, 0)
            vLbl:SetWidth(100)
            vLbl:SetJustifyH("LEFT")
            vLbl:SetText("")
            vLbl:SetTextColor(0.88, 0.88, 0.88, 1)

            statFrames[sk] = { frame = rf, keyLbl = kLbl, valueLbl = vLbl }
        end
    end

    -- ── Register with MainWindow ──────────────────────────────────────────────
    StatForge.MainWindow.RegisterTabFrame("optimizer", tabFrame)

    StatForge.State.OnChange(function()
        OptimizerTab.Refresh()
    end)

    tabFrame:SetScript("OnShow", function()
        OptimizerTab.Refresh()
    end)

    tabFrame:SetScript("OnHide", function()
        HideDropdown()
    end)
end
