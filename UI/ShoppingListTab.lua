-- StatForge/UI/ShoppingListTab.lua
-- Barebone shopping list tab: shows enabled applied sources, copy to clipboard.

StatForge.ShoppingListTab = {}
local ShoppingListTab = StatForge.ShoppingListTab

local PAD       = 8
local CONTENT_W = 804
local CONTENT_H = 446

local tabFrame  = nil
local textChild = nil   -- Frame holding the text FontString
local textLbl   = nil   -- The FontString itself

-- ── Refresh ───────────────────────────────────────────────────────────────────

function ShoppingListTab.Refresh()
    if not tabFrame or not tabFrame:IsShown() then return end

    local items    = StatForge.ShoppingList.Generate()
    local textStr  = StatForge.ShoppingList.FormatText(items)

    textLbl:SetText(textStr)

    -- Resize child frame so scroll works
    local th = textLbl:GetStringHeight()
    textChild:SetHeight(math.max(th + PAD * 2, 10))
end

-- ── Build ─────────────────────────────────────────────────────────────────────

function ShoppingListTab.Build(contentFrame)
    tabFrame = CreateFrame("Frame", nil, contentFrame)
    tabFrame:SetAllPoints(contentFrame)
    tabFrame:Hide()

    -- Toolbar row
    local hdr = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", PAD, 0)
    hdr:SetText("SHOPPING LIST")
    hdr:SetTextColor(0.48, 0.68, 1, 1)

    local copyBtn = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    copyBtn:SetSize(120, 22)
    copyBtn:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", PAD, -20)
    copyBtn:SetText("Copy to Clipboard")
    copyBtn:SetScript("OnClick", function()
        local items   = StatForge.ShoppingList.Generate()
        local textStr = StatForge.ShoppingList.FormatText(items)
        if C_Clipboard and C_Clipboard.SetText then
            C_Clipboard.SetText(textStr)
            print("|cff00ccffStatForge:|r Shopping list copied to clipboard.")
        else
            print("|cff00ccffStatForge:|r C_Clipboard not available.")
        end
    end)

    -- Separator
    local sep = tabFrame:CreateTexture(nil, "BACKGROUND")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  tabFrame, "TOPLEFT",  PAD, -50)
    sep:SetPoint("TOPRIGHT", tabFrame, "TOPRIGHT", -PAD, -50)
    sep:SetColorTexture(0.20, 0.20, 0.26, 1)

    -- Scroll frame
    local sfH = CONTENT_H - 54

    local sf = CreateFrame("ScrollFrame", "StatForgeShopScrollFrame",
        tabFrame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",  tabFrame, "TOPLEFT",  PAD, -54)
    sf:SetSize(CONTENT_W - PAD*2, sfH)

    textChild = CreateFrame("Frame", nil, sf)
    textChild:SetWidth(CONTENT_W - PAD*2 - 20)
    textChild:SetHeight(10)
    sf:SetScrollChild(textChild)

    textLbl = textChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    textLbl:SetPoint("TOPLEFT", textChild, "TOPLEFT", 0, -PAD)
    textLbl:SetWidth(CONTENT_W - PAD*2 - 20)
    textLbl:SetJustifyH("LEFT")
    textLbl:SetJustifyV("TOP")
    textLbl:SetSpacing(2)

    -- ── Register + subscribe ──────────────────────────────────────────────────
    StatForge.MainWindow.RegisterTabFrame("shoppinglist", tabFrame)

    StatForge.State.OnChange(function()
        ShoppingListTab.Refresh()
    end)

    tabFrame:SetScript("OnShow", function()
        ShoppingListTab.Refresh()
    end)
end
