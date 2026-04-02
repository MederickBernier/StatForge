-- StatForge/UI/ImportExportTab.lua
-- Barebone import/export tab.
-- Export: generate share string from current sandbox or a saved setup.
-- Import: paste a share string, preview it, save as a new named setup.

StatForge.ImportExportTab = {}
local ImportExportTab = StatForge.ImportExportTab

local PAD       = 8
local CONTENT_W = 804
local CONTENT_H = 446

local tabFrame     = nil
local exportBox    = nil   -- output EditBox (read-only display)
local importBox    = nil   -- input EditBox (paste here)
local previewLbl   = nil   -- shows decoded sandbox summary
local statusLbl    = nil   -- import status line
local importedSB   = nil   -- last successfully decoded sandbox (nil if none)

-- ── Export helpers ────────────────────────────────────────────────────────────

local function ExportCurrent()
    local str, err = StatForge.ImportExport.ExportCurrent()
    if str then
        exportBox:SetText(str)
    else
        exportBox:SetText("Error: " .. tostring(err))
    end
end

local function ExportSetup(name)
    local str, err = StatForge.ImportExport.Export(name)
    if str then
        exportBox:SetText(str)
    else
        exportBox:SetText("Error: " .. tostring(err))
    end
end

-- ── Import helpers ────────────────────────────────────────────────────────────

local function TryImport()
    local str    = strtrim(importBox:GetText())
    previewLbl:SetText("")
    statusLbl:SetText("")
    importedSB = nil

    if str == "" then
        statusLbl:SetText("Paste a share string above.")
        statusLbl:SetTextColor(0.6, 0.6, 0.6, 1)
        return
    end

    local sb, err = StatForge.ImportExport.Import(str)
    if not sb then
        statusLbl:SetText("Error: " .. tostring(err))
        statusLbl:SetTextColor(1, 0.4, 0.4, 1)
        return
    end

    importedSB = sb
    local preview = StatForge.ImportExport.Preview(sb)
    previewLbl:SetText(preview)
    previewLbl:SetTextColor(0.7, 0.9, 0.7, 1)
    statusLbl:SetText("Ready to import — enter a name and click Save.")
    statusLbl:SetTextColor(0.7, 0.7, 0.7, 1)
end

-- ── SetMode (called from MainWindow.Open) ─────────────────────────────────────

function ImportExportTab.SetMode(mode)
    -- Could scroll to export or import section; no-op for barebone
end

function ImportExportTab.Refresh()
    -- Nothing to auto-refresh; content is user-driven
end

-- ── Build ─────────────────────────────────────────────────────────────────────

function ImportExportTab.Build(contentFrame)
    tabFrame = CreateFrame("Frame", nil, contentFrame)
    tabFrame:SetAllPoints(contentFrame)
    tabFrame:Hide()

    local halfH = math.floor(CONTENT_H / 2) - 4
    local boxW  = CONTENT_W - PAD*2

    -- ════════════════════════════════════════════════════════════
    -- EXPORT SECTION (top half)
    -- ════════════════════════════════════════════════════════════
    local expHdr = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    expHdr:SetPoint("TOPLEFT", PAD, 0)
    expHdr:SetText("EXPORT")
    expHdr:SetTextColor(0.48, 0.68, 1, 1)

    -- Button row
    local expCurrentBtn = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    expCurrentBtn:SetSize(140, 22)
    expCurrentBtn:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", PAD, -20)
    expCurrentBtn:SetText("Export Current")
    expCurrentBtn:SetScript("OnClick", ExportCurrent)

    -- Setup name input + export-setup button
    local setupLbl = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    setupLbl:SetPoint("LEFT", expCurrentBtn, "RIGHT", 16, 0)
    setupLbl:SetText("or setup:")
    setupLbl:SetTextColor(0.60, 0.60, 0.70, 1)

    local setupBox = CreateFrame("EditBox", "StatForgeExportSetupBox", tabFrame, "InputBoxTemplate")
    setupBox:SetSize(180, 22)
    setupBox:SetPoint("LEFT", setupLbl, "RIGHT", 6, 0)
    setupBox:SetAutoFocus(false)
    setupBox:SetMaxLetters(64)

    local expSetupBtn = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    expSetupBtn:SetSize(60, 22)
    expSetupBtn:SetPoint("LEFT", setupBox, "RIGHT", 4, 0)
    expSetupBtn:SetText("Export")
    expSetupBtn:SetScript("OnClick", function()
        local name = strtrim(setupBox:GetText())
        if name == "" then
            print("|cff00ccffStatForge:|r Enter a setup name.")
        else
            ExportSetup(name)
        end
    end)

    -- Output EditBox (read-ish; user can still select-all and copy)
    local expBoxFrame = CreateFrame("Frame", nil, tabFrame, "BackdropTemplate")
    expBoxFrame:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 10,
        insets   = { left=2, right=2, top=2, bottom=2 },
    })
    expBoxFrame:SetBackdropColor(0.04, 0.04, 0.06, 1)
    expBoxFrame:SetBackdropBorderColor(0.22, 0.22, 0.30, 1)
    expBoxFrame:SetPoint("TOPLEFT",  tabFrame, "TOPLEFT",  PAD,     -48)
    expBoxFrame:SetSize(boxW, halfH - 52)

    exportBox = CreateFrame("EditBox", nil, expBoxFrame)
    exportBox:SetPoint("TOPLEFT",     expBoxFrame, "TOPLEFT",  4,  -4)
    exportBox:SetPoint("BOTTOMRIGHT", expBoxFrame, "BOTTOMRIGHT", -4, 4)
    exportBox:SetMultiLine(true)
    exportBox:SetAutoFocus(false)
    exportBox:SetFontObject(GameFontHighlightSmall)
    exportBox:SetMaxLetters(0)

    local copyBtn = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    copyBtn:SetSize(100, 22)
    copyBtn:SetPoint("BOTTOMRIGHT", expBoxFrame, "TOPRIGHT", 0, 4)
    copyBtn:SetText("Copy")
    copyBtn:SetScript("OnClick", function()
        local s = exportBox:GetText()
        if s and s ~= "" then
            if C_Clipboard and C_Clipboard.SetText then
                C_Clipboard.SetText(s)
                print("|cff00ccffStatForge:|r Copied to clipboard.")
            else
                exportBox:SetFocus()
                exportBox:HighlightText()
            end
        end
    end)

    -- Section divider
    local midSep = tabFrame:CreateTexture(nil, "BACKGROUND")
    midSep:SetHeight(1)
    midSep:SetPoint("TOPLEFT",  tabFrame, "TOPLEFT",  PAD,  -halfH - 4)
    midSep:SetPoint("TOPRIGHT", tabFrame, "TOPRIGHT", -PAD, -halfH - 4)
    midSep:SetColorTexture(0.20, 0.20, 0.26, 1)

    -- ════════════════════════════════════════════════════════════
    -- IMPORT SECTION (bottom half)
    -- ════════════════════════════════════════════════════════════
    local impY = halfH + 8

    local impHdr = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    impHdr:SetPoint("TOPLEFT", PAD, -impY)
    impHdr:SetText("IMPORT")
    impHdr:SetTextColor(0.48, 0.68, 1, 1)

    -- Paste EditBox
    local impBoxFrame = CreateFrame("Frame", nil, tabFrame, "BackdropTemplate")
    impBoxFrame:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 10,
        insets   = { left=2, right=2, top=2, bottom=2 },
    })
    impBoxFrame:SetBackdropColor(0.04, 0.04, 0.06, 1)
    impBoxFrame:SetBackdropBorderColor(0.22, 0.22, 0.30, 1)
    impBoxFrame:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", PAD, -(impY + 20))
    impBoxFrame:SetSize(boxW, 50)

    importBox = CreateFrame("EditBox", nil, impBoxFrame)
    importBox:SetPoint("TOPLEFT",     impBoxFrame, "TOPLEFT",     4,  -4)
    importBox:SetPoint("BOTTOMRIGHT", impBoxFrame, "BOTTOMRIGHT", -4,  4)
    importBox:SetMultiLine(true)
    importBox:SetAutoFocus(false)
    importBox:SetFontObject(GameFontHighlightSmall)
    importBox:SetMaxLetters(0)

    local previewBtn = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    previewBtn:SetSize(80, 22)
    previewBtn:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", PAD, -(impY + 76))
    previewBtn:SetText("Preview")
    previewBtn:SetScript("OnClick", TryImport)

    -- Preview text
    previewLbl = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewLbl:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", PAD, -(impY + 104))
    previewLbl:SetWidth(boxW - 200)
    previewLbl:SetJustifyH("LEFT")
    previewLbl:SetJustifyV("TOP")
    previewLbl:SetSpacing(2)

    -- Save-as row
    local saveAsLbl = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    saveAsLbl:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", PAD, -(impY + 160))
    saveAsLbl:SetText("Save as:")
    saveAsLbl:SetTextColor(0.60, 0.60, 0.70, 1)

    local saveAsBox = CreateFrame("EditBox", "StatForgeImportNameBox", tabFrame, "InputBoxTemplate")
    saveAsBox:SetSize(200, 22)
    saveAsBox:SetPoint("LEFT", saveAsLbl, "RIGHT", 6, 0)
    saveAsBox:SetAutoFocus(false)
    saveAsBox:SetMaxLetters(64)

    local saveAsBtn = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    saveAsBtn:SetSize(80, 22)
    saveAsBtn:SetPoint("LEFT", saveAsBox, "RIGHT", 6, 0)
    saveAsBtn:SetText("Save Setup")
    saveAsBtn:SetScript("OnClick", function()
        if not importedSB then
            statusLbl:SetText("Preview the share string first.")
            statusLbl:SetTextColor(1, 0.6, 0.2, 1)
            return
        end
        local name = strtrim(saveAsBox:GetText())
        local ok, err = StatForge.ImportExport.ImportAsSetup(importedSB, name)
        if ok then
            statusLbl:SetText("Saved as \"" .. name .. "\".")
            statusLbl:SetTextColor(0.3, 1, 0.3, 1)
            saveAsBox:SetText("")
            importBox:SetText("")
            previewLbl:SetText("")
            importedSB = nil
        else
            statusLbl:SetText("Error: " .. tostring(err))
            statusLbl:SetTextColor(1, 0.4, 0.4, 1)
        end
    end)

    -- Status line
    statusLbl = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusLbl:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", PAD, -(impY + 190))
    statusLbl:SetWidth(boxW)
    statusLbl:SetJustifyH("LEFT")
    statusLbl:SetTextColor(0.6, 0.6, 0.6, 1)

    -- ── Register with MainWindow ──────────────────────────────────────────────
    StatForge.MainWindow.RegisterTabFrame("importexport", tabFrame)

    tabFrame:SetScript("OnShow", function()
        ImportExportTab.Refresh()
    end)
end
