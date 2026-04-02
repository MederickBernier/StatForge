-- StatForge/UI/MinimapButton.lua
-- Circular minimap button: click to toggle main window, drag to reposition.

StatForge.MinimapButton = {}
local MinimapButton = StatForge.MinimapButton

local BUTTON_SIZE = 32
local ICON_PATH   = "Interface\\Icons\\Trade_Engraving"

-- ── Polar position helpers ────────────────────────────────────────────────────

-- Map a polar angle (degrees, 0 = top, clockwise) to an x,y offset from
-- the minimap centre so the button sits on the rim.
local function AngleToOffset(angle)
    local rad = math.rad(angle - 90)  -- 90 = rotate so 0° is at the top
    local r   = 80                     -- minimap radius + button offset
    return math.cos(rad) * r, math.sin(rad) * r
end

local function UpdatePosition(btn, angle)
    local x, y = AngleToOffset(angle)
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- ── Drag logic ────────────────────────────────────────────────────────────────

local function OnDragStart(self)
    self:SetScript("OnUpdate", function(btn)
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale  = UIParent:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale

        local angle = math.deg(math.atan2(cy - my, cx - mx)) + 90
        if angle < 0 then angle = angle + 360 end

        StatForge.State.SetMinimapAngle(angle)
        UpdatePosition(btn, angle)
    end)
end

local function OnDragStop(self)
    self:SetScript("OnUpdate", nil)
end

-- ── Build ─────────────────────────────────────────────────────────────────────

function MinimapButton.Build()
    local btn = CreateFrame("Button", "StatForgeMinimapButton", Minimap)
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)

    -- Circular background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Background")

    -- Icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture(ICON_PATH)

    -- Overlay ring (gives the circular border look)
    local ring = btn:CreateTexture(nil, "OVERLAY")
    ring:SetAllPoints()
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("StatForge", 1, 1, 1)
        GameTooltip:AddLine("Click to open / close", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Click: toggle main window
    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            StatForge.MainWindow.Toggle()
        end
    end)

    -- Drag: reposition around minimap rim
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", OnDragStart)
    btn:SetScript("OnDragStop",  OnDragStop)

    -- Restore saved position
    local angle = StatForge.State.GetMinimapAngle()
    UpdatePosition(btn, angle)
end
