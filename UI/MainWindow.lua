-- StatForge/UI/MainWindow.lua
-- Main window frame: title bar, custom tab strip, content area.
-- Each tab module builds its own content inside the shared contentFrame,
-- then registers it via MainWindow.RegisterTabFrame(tabId, frame).
--
-- Public API:
--   MainWindow.Build()
--   MainWindow.RegisterTabFrame(tabId, frame)
--   MainWindow.ShowTab(tabId)
--   MainWindow.Open(tabId [, arg])
--   MainWindow.Close()
--   MainWindow.Toggle()
--   MainWindow.GetContentFrame()

StatForge.MainWindow = {}

local MainWindow = StatForge.MainWindow

-- ── Layout constants ──────────────────────────────────────────────────────────

local WINDOW_W = 820
local WINDOW_H = 520
local CHROME_T = 36    -- pixels from frame top to usable content (title bar height)
local TAB_H    = 28    -- height of each tab button
local BORDER   = 8     -- left/right inset

local TAB_DEFS = {
    { id = "optimizer",    label = "Optimizer"       },
    { id = "setups",       label = "Setups"          },
    { id = "shoppinglist", label = "Shopping List"   },
    { id = "importexport", label = "Import / Export" },
}

-- Internal state
local frame        = nil
local contentFrame = nil
local tabButtons   = {}
local tabFrames    = {}
local activeTabId  = nil

-- ── Build ─────────────────────────────────────────────────────────────────────

function MainWindow.Build()
    -- ── Outer frame ──
    frame = CreateFrame("Frame", "StatForgeFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(WINDOW_W, WINDOW_H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()

    if frame.TitleText then
        frame.TitleText:SetText("StatForge")
    end

    -- ── Tab buttons ──
    -- Sit just below the title bar chrome, spanning the content width equally.
    local tabW = math.floor((WINDOW_W - BORDER * 2) / #TAB_DEFS)

    for i, def in ipairs(TAB_DEFS) do
        local btn = CreateFrame("Button", "StatForgeTab" .. i, frame)
        btn:SetSize(tabW, TAB_H)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT",
            BORDER + (i - 1) * tabW, -CHROME_T)

        -- Background
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.09, 0.11, 0.95)
        btn._bg = bg

        -- Blue accent line along the top edge (active tab only)
        local accent = btn:CreateTexture(nil, "BORDER")
        accent:SetPoint("TOPLEFT",  btn, "TOPLEFT",  0, 0)
        accent:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
        accent:SetHeight(2)
        accent:SetColorTexture(0.36, 0.58, 1.00, 1.00)
        accent:Hide()
        btn._accent = accent

        -- 1 px vertical divider on the right edge (between tabs, not after last)
        if i < #TAB_DEFS then
            local div = btn:CreateTexture(nil, "BORDER")
            div:SetWidth(1)
            div:SetPoint("TOPRIGHT",    btn, "TOPRIGHT",    0, -3)
            div:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0,  3)
            div:SetColorTexture(0.20, 0.20, 0.25, 0.80)
        end

        -- Label
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetAllPoints()
        lbl:SetJustifyH("CENTER")
        lbl:SetText(def.label)
        lbl:SetTextColor(0.55, 0.55, 0.55, 1.00)
        btn._lbl = lbl

        -- Hover highlight via OnEnter/OnLeave (avoids SetHighlightTexture pitfalls)
        btn:SetScript("OnEnter", function(self)
            if activeTabId ~= def.id then
                self._bg:SetColorTexture(0.12, 0.13, 0.16, 0.95)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeTabId ~= def.id then
                self._bg:SetColorTexture(0.08, 0.09, 0.11, 0.95)
            end
        end)

        local tabId = def.id
        btn:SetScript("OnClick", function()
            MainWindow.ShowTab(tabId)
        end)

        tabButtons[def.id] = btn
    end

    -- 1 px horizontal separator below the tab strip
    local sep = frame:CreateTexture(nil, "OVERLAY")
    sep:SetHeight(1)
    sep:SetColorTexture(0.20, 0.20, 0.25, 1.00)
    sep:SetPoint("TOPLEFT",  frame, "TOPLEFT",  BORDER,  -(CHROME_T + TAB_H))
    sep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -BORDER, -(CHROME_T + TAB_H))

    -- ── Content area (below tab strip + separator) ──
    contentFrame = CreateFrame("Frame", "StatForgeContentFrame", frame)
    contentFrame:SetPoint("TOPLEFT",
        frame, "TOPLEFT",  BORDER,  -(CHROME_T + TAB_H + 2))
    contentFrame:SetPoint("BOTTOMRIGHT",
        frame, "BOTTOMRIGHT", -BORDER, BORDER)

    -- ── Build tab content (stubs are no-ops) ──
    if StatForge.OptimizerTab.Build    then StatForge.OptimizerTab.Build(contentFrame)    end
    if StatForge.SetupsTab.Build       then StatForge.SetupsTab.Build(contentFrame)       end
    if StatForge.ShoppingListTab.Build then StatForge.ShoppingListTab.Build(contentFrame) end
    if StatForge.ImportExportTab.Build then StatForge.ImportExportTab.Build(contentFrame) end

    MainWindow.ShowTab("optimizer")
end

-- ── Tab management ────────────────────────────────────────────────────────────

function MainWindow.RegisterTabFrame(tabId, tabFrame)
    tabFrames[tabId] = tabFrame
    tabFrame:Hide()
end

function MainWindow.ShowTab(tabId)
    for _, f in pairs(tabFrames) do
        f:Hide()
    end
    for id, btn in pairs(tabButtons) do
        btn._bg:SetColorTexture(0.08, 0.09, 0.11, 0.95)
        btn._lbl:SetTextColor(0.55, 0.55, 0.55, 1.00)
        btn._accent:Hide()
    end

    local f   = tabFrames[tabId]
    local btn = tabButtons[tabId]
    if f   then f:Show() end
    if btn then
        btn._bg:SetColorTexture(0.16, 0.18, 0.24, 1.00)
        btn._lbl:SetTextColor(1.00, 1.00, 1.00, 1.00)
        btn._accent:Show()
    end

    activeTabId = tabId
end

-- ── Public window control ─────────────────────────────────────────────────────

function MainWindow.Open(tabId, arg)
    if not frame then return end
    frame:Show()
    if tabId then
        MainWindow.ShowTab(tabId)
        if arg and tabId == "importexport" then
            local ie = StatForge.ImportExportTab
            if ie and ie.SetMode then ie.SetMode(arg) end
        end
    end
end

function MainWindow.Close()
    if frame then frame:Hide() end
end

function MainWindow.Toggle()
    if not frame then return end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

-- ── Accessors ─────────────────────────────────────────────────────────────────

function MainWindow.GetContentFrame() return contentFrame end
function MainWindow.GetFrame()        return frame        end
function MainWindow.GetActiveTab()    return activeTabId  end
