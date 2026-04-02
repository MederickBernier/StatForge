-- StatForge/StatForge.lua
-- Entry point: event registration and slash commands.
-- All modules are loaded before this file via the TOC.

local ADDON_NAME = "StatForge"

-- Event listener frame
local eventFrame = CreateFrame("Frame", "StatForgeEventFrame")

eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= ADDON_NAME then return end
        self:UnregisterEvent("ADDON_LOADED")
        StatForge.Init()
    end
end)

function StatForge.Init()
    -- Step 2+: State.Init() will set up SavedVariables
    if StatForge.State.Init then StatForge.State.Init() end

    -- Step 4+: register gear events and do initial scan
    if StatForge.GearScanner.Init then StatForge.GearScanner.Init() end

    -- Step 5+: detect spec and hero talent
    if StatForge.SpecDetector.Detect then StatForge.SpecDetector.Detect() end

    -- Step 7+: build UI
    if StatForge.MainWindow.Build then StatForge.MainWindow.Build() end
    if StatForge.MinimapButton.Build then StatForge.MinimapButton.Build() end

    print("|cff00ccffStatForge|r loaded. Type |cffffd700/statforge|r to open.")
end

-- Slash commands
SLASH_STATFORGE1 = "/statforge"
SLASH_STATFORGE2 = "/sf"

SlashCmdList["STATFORGE"] = function(msg)
    local cmd = strtrim(msg):lower()
    if cmd == "" then
        if StatForge.MainWindow.Open then
            StatForge.MainWindow.Open("optimizer")
        else
            print("|cff00ccffStatForge|r v1.0.0 — UI not yet loaded.")
        end
    elseif cmd == "setups" then
        if StatForge.MainWindow.Open then StatForge.MainWindow.Open("setups") end
    elseif cmd == "list" then
        if StatForge.MainWindow.Open then StatForge.MainWindow.Open("shoppinglist") end
    elseif cmd == "import" then
        if StatForge.MainWindow.Open then StatForge.MainWindow.Open("importexport", "import") end
    elseif cmd == "export" then
        if StatForge.MainWindow.Open then StatForge.MainWindow.Open("importexport", "export") end
    elseif cmd == "reset" then
        if StatForge.State.ResetSandbox then
            StatForge.State.ResetSandbox()
            print("|cff00ccffStatForge|r sandbox reset.")
        end
    else
        print("|cff00ccffStatForge|r commands:")
        print("  /statforge          — Optimizer")
        print("  /statforge setups   — Saved setups")
        print("  /statforge list     — Shopping list")
        print("  /statforge import   — Import a setup")
        print("  /statforge export   — Export current setup")
        print("  /statforge reset    — Reset sandbox")
    end
end

-- Addon Compartment callbacks (registered via TOC metadata fields)
function StatForge_OnAddonCompartmentClick()
    if StatForge.MainWindow.Toggle then
        StatForge.MainWindow.Toggle()
    end
end

function StatForge_OnAddonCompartmentEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("StatForge", 1, 1, 1)
    GameTooltip:AddLine("Stat optimization sandbox", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

function StatForge_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
