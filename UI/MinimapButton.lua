-- Gearfinder minimap button (draggable around the minimap, position saved account-wide).
--   Left click  : open / close the Gearfinder window
--   Right click : print client / data diagnostics (useful for bug reports)
--   Drag        : move the button around the minimap edge
local GF = Gearfinder
GF.UI.Minimap = GF.UI.Minimap or {}

-- Selectable logo: "amber" (default, golden runes) or "arcane" (blue runes). Saved account-wide.
local LOGOS = {
    amber  = { path = "Interface\\AddOns\\Gearfinder\\Media\\Logo_Amber",  label = "Golden runes" },
    arcane = { path = "Interface\\AddOns\\Gearfinder\\Media\\Logo_Arcane", label = "Arcane blue" },
}
local LOGO_ORDER = { "amber", "arcane" }
function GF.UI.GetLogoKey()
    local key = GearfinderDB and GearfinderDB.logo
    return LOGOS[key] and key or "amber"
end
function GF.UI.GetLogo() return LOGOS[GF.UI.GetLogoKey()].path end
function GF.UI.SetLogo(key)
    if not LOGOS[key] then
        -- no / unknown key: step to the next logo
        local current, nextKey = GF.UI.GetLogoKey(), LOGO_ORDER[1]
        for i, k in ipairs(LOGO_ORDER) do if k == current then nextKey = LOGO_ORDER[i % #LOGO_ORDER + 1] end end
        key = nextKey
    end
    GearfinderDB = GearfinderDB or {}
    GearfinderDB.logo = key
    if GF.UI.ApplyLogo then GF.UI.ApplyLogo() end
    return LOGOS[key].label
end
local function ICON_PATH_NOW() return GF.UI.GetLogo() end
local DEFAULT_ANGLE = 215
local button

local function GetDB()
    GearfinderDB = GearfinderDB or {}
    GearfinderDB.minimap = GearfinderDB.minimap or {}
    local db = GearfinderDB.minimap
    if type(db.angle) ~= "number" then db.angle = DEFAULT_ANGLE end
    return db
end

-- Quadrant table used by addons that skin the minimap (true = round corner, false = square corner).
local MINIMAP_SHAPES = {
    ["ROUND"] = { true, true, true, true },
    ["SQUARE"] = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, false, false, true },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
    ["TRICORNER-TOPLEFT"] = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local function UpdatePosition()
    if not button then return end
    local angle = math.rad(GetDB().angle)
    local x, y, quadrant = math.cos(angle), math.sin(angle), 1
    if x < 0 then quadrant = quadrant + 1 end
    if y > 0 then quadrant = quadrant + 2 end
    local shape = (type(GetMinimapShape) == "function" and GetMinimapShape()) or "ROUND"
    local quadTable = MINIMAP_SHAPES[shape] or MINIMAP_SHAPES["ROUND"]
    local w = (Minimap:GetWidth() / 2) + 5
    local h = (Minimap:GetHeight() / 2) + 5
    if quadTable[quadrant] then
        x, y = x * w, y * h
    else
        local diagW = math.sqrt(2 * w * w) - 10
        local diagH = math.sqrt(2 * h * h) - 10
        x = math.max(-w, math.min(x * diagW, w))
        y = math.max(-h, math.min(y * diagH, h))
    end
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local atan2 = math.atan2 or math.atan

local function OnDragUpdate()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    GetDB().angle = math.deg(atan2(py - my, px - mx)) % 360
    UpdatePosition()
end

function GF.UI.Minimap.ShowTooltip(owner, anchor)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner, anchor or "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Gearfinder", 1, 0.82, 0)
    GameTooltip:AddLine("Dungeon & raid gear advisor  v" .. tostring(GF.version), 0.8, 0.8, 0.8)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffffffffLeft-click|r  open / close", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cffffffffRight-click|r  client & data info", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cffffffffDrag|r  move around the minimap", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cffffffffShift-click|r  switch logo (golden / arcane)", 0.9, 0.9, 0.9)
    GameTooltip:Show()
end

function GF.UI.Minimap.PrintInfo()
    local prefix = "|cffd9b15fGearfinder|r "
    print(prefix .. "v" .. tostring(GF.version) .. " • " .. GF.Compat.Describe())
    if GF.API and GF.API.GetDiagnostics then
        local info = GF.API.GetDiagnostics()
        print(prefix .. tostring(info.uniqueItemIDs) .. " items • " .. tostring(info.dungeonCount) .. " dungeons • " .. tostring(info.raidCount) .. " raids • " .. tostring(info.learnedItems) .. " learned drops")
    end
    if GF.Catalog and GF.Catalog.Probe then
        for _, line in ipairs(GF.Catalog.Probe()) do print(prefix .. line) end
    end
end

function GF.UI.Minimap.Click(mouseButton)
    if IsShiftKeyDown and IsShiftKeyDown() and mouseButton == "LeftButton" then
        print("|cffd9b15fGearfinder|r logo: " .. GF.UI.SetLogo())
        return
    end
    if mouseButton == "RightButton" then
        GF.UI.Minimap.PrintInfo()
    elseif GF.UI.Toggle then
        GF.UI.Toggle()
    end
end

function GF.UI.CreateMinimapButton()
    if button or not Minimap then return end
    local db = GetDB()

    button = CreateFrame("Button", "GearfinderMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    if button.SetFixedFrameStrata then button:SetFixedFrameStrata(true) end
    button:SetFrameLevel(8)
    if button.SetFixedFrameLevel then button:SetFixedFrameLevel(true) end
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- The round gold ring is part of the icon texture itself, so no Blizzard border is needed.
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexture(ICON_PATH_NOW())

    button:SetScript("OnClick", function(_, mouseButton) GF.UI.Minimap.Click(mouseButton) end)
    button:SetScript("OnEnter", function(self)
        if self.dragging then return end
        GF.UI.Minimap.ShowTooltip(self, "ANCHOR_LEFT")
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnMouseDown", function(self) self.icon:SetPoint("TOPLEFT", 1, -1); self.icon:SetPoint("BOTTOMRIGHT", 1, -1) end)
    button:SetScript("OnMouseUp", function(self) self.icon:SetAllPoints(self) end)
    button:SetScript("OnDragStart", function(self)
        self.dragging = true
        GameTooltip:Hide()
        self:LockHighlight()
        self:SetScript("OnUpdate", OnDragUpdate)
    end)
    button:SetScript("OnDragStop", function(self)
        self.dragging = nil
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)

    UpdatePosition()
    if db.hide then button:Hide() else button:Show() end
end

-- Re-apply the chosen logo to the minimap button and the window portrait.
function GF.UI.ApplyLogo()
    if button and button.icon then button.icon:SetTexture(GF.UI.GetLogo()) end
    local window = _G.GearfinderMainFrame
    if window then
        pcall(function()
            if window.SetPortraitToAsset then window:SetPortraitToAsset(GF.UI.GetLogo())
            elseif window.portrait then window.portrait:SetTexture(GF.UI.GetLogo()) end
        end)
    end
end

-- Addon compartment (the "addons" dropdown next to the minimap on Mainline-family clients such as
-- WoW Forever). The functions are referenced from the TOC; clients without a compartment ignore them.
function GearfinderAddonCompartmentClick(_, mouseButton)
    GF.UI.Minimap.Click(mouseButton)
end
function GearfinderAddonCompartmentEnter(_, menuButtonFrame)
    GF.UI.Minimap.ShowTooltip(menuButtonFrame, "ANCHOR_LEFT")
end
function GearfinderAddonCompartmentLeave()
    if GameTooltip then GameTooltip:Hide() end
end
