-- Gearfinder world-map pins: dungeon and raid entrances in the native Blizzard style (the blue Dungeon
-- and green Raid portal icons), each with the number of upgrade slots it offers your current build.
-- Position sources, best first:
--   1. the game itself (C_EncounterJournal.GetDungeonEntrancesForMap; it only lists discovered entrances)
--   2. entrances you have walked into yourself (remembered exactly)
--   3. a small built-in approximate table (Data/Entrances.lua)
-- Pins are redrawn only when the map changes or opens. Nothing runs on a timer.
--   Hover: instance info + best upgrades   Left click: open Gearfinder   Right click: set waypoint
local GF = Gearfinder
GF.UI = GF.UI or {}
GF.UI.MapPins = GF.UI.MapPins or {}
local Pins = GF.UI.MapPins

local FALLBACK_ICON = "Interface\\AddOns\\Gearfinder\\Media\\MinimapIcon"
local pool, hooked = {}, false
local lastOutdoor

local function DB()
    GearfinderDB = GearfinderDB or {}
    GearfinderDB.entrances = GearfinderDB.entrances or {}
    return GearfinderDB
end

function Pins.IsEnabled() return DB().mapPins ~= false end
function Pins.SetEnabled(value) DB().mapPins = value and true or false; Pins.Update() end

local function Canon(name) return GF.Data.CanonicalName and GF.Data.CanonicalName(name) or tostring(name or ""):lower() end

local function XY(pos)
    if type(pos) ~= "table" then return nil end
    if pos.GetXY then
        local ok, x, y = pcall(pos.GetXY, pos)
        if ok then return x, y end
    end
    return pos.x, pos.y
end

local function MapName(mapID)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    return info and info.name or nil
end

local function AtlasOK(name)
    if not name then return false end
    if C_Texture and C_Texture.GetAtlasInfo then return C_Texture.GetAtlasInfo(name) ~= nil end
    return true
end

-- ---------- learn entrances you walk into (two events per loading screen, no polling) ----------
function Pins.OnLeavingWorld()
    lastOutdoor = nil
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return end
    if IsInInstance and IsInInstance() then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    local x, y = XY(pos)
    if x and y and x > 0 and y > 0 then lastOutdoor = { mapID = mapID, x = x, y = y, t = GetTime and GetTime() or 0 } end
end

function Pins.OnEnteringWorld()
    local ok, name, kind = pcall(GetInstanceInfo)
    if not ok or (kind ~= "party" and kind ~= "raid") or not lastOutdoor then return end
    if GetTime and (GetTime() - lastOutdoor.t) > 300 then return end
    DB().entrances[Canon(name)] = {
        name = name, mapID = lastOutdoor.mapID, x = lastOutdoor.x, y = lastOutdoor.y,
        zone = MapName(lastOutdoor.mapID), raid = (kind == "raid"),
    }
    lastOutdoor = nil
    Pins.Update()
end

-- ---------- pin widget ----------
local function SetIcon(pin, isRaid, atlas)
    local wanted = atlas
    if not AtlasOK(wanted) then wanted = isRaid and "Raid" or "Dungeon" end
    if AtlasOK(wanted) and pin.icon.SetAtlas then
        pin.icon:SetAtlas(wanted)
        pin.icon:SetTexCoord(0, 1, 0, 1)
    else
        pin.icon:SetTexture(FALLBACK_ICON)
    end
end

local function GetPin(index)
    local pin = pool[index]
    if pin then return pin end
    pin = CreateFrame("Button", nil, WorldMapFrame:GetCanvas())
    pin:SetSize(26, 26)
    pin:SetFrameStrata("HIGH")
    pin:SetFrameLevel(2200)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetAllPoints(pin)
    pin.highlight = pin:CreateTexture(nil, "HIGHLIGHT")
    pin.highlight:SetAllPoints(pin)
    pin.highlight:SetColorTexture(1, 1, 1, 0.18)
    pin.badge = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pin.badge:SetPoint("TOP", pin, "BOTTOM", 0, 2)
    pin.badge:SetTextColor(0.4, 1, 0.45)
    pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        local inst = self.inst or {}
        GameTooltip:AddLine(inst.name or self.name or "Instance", 1, 0.82, 0)
        local bits = {}
        bits[#bits + 1] = self.isRaid and ("Raid" .. (inst.size and (" " .. inst.size) or "")) or "Dungeon"
        if inst.min then bits[#bits + 1] = "Level " .. inst.min .. (inst.max and ("–" .. inst.max) or "") end
        if inst.new then bits[#bits + 1] = "New in Forever" end
        GameTooltip:AddLine(table.concat(bits, "  •  "), 0.7, 0.9, 1)
        if inst.unlock and time and time() < inst.unlock then
            GameTooltip:AddLine("Opens December 9 (Forever roadmap)", 1, 0.82, 0.3)
        end
        local ups = self.upgrades or {}
        if #ups > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(#ups .. " slot(s) with an upgrade here:", 0.4, 1, 0.4)
            for i = 1, math.min(5, #ups) do
                local u = ups[i]
                local delta = u.item.delta
                GameTooltip:AddDoubleLine(u.slot .. ": " .. tostring(u.item.name),
                    delta and ((delta >= 0 and "+" or "") .. string.format("%.1f", delta)) or "new", 0.9, 0.9, 0.9, 0.4, 1, 0.4)
            end
            if #ups > 5 then GameTooltip:AddLine("…and " .. (#ups - 5) .. " more", 0.65, 0.65, 0.65) end
        elseif inst.name then
            GameTooltip:AddLine("No upgrade for your current build here.", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("Not in the Gearfinder catalogue yet. Press Refresh.", 0.7, 0.7, 0.7)
        end
        GameTooltip:AddLine(" ")
        local source = self.source == "game" and "game data" or (self.source == "learned" and "learned from your visit" or "built-in, approximate")
        GameTooltip:AddLine("Position: " .. source, 0.6, 0.6, 0.6)
        GameTooltip:AddLine("Left-click: open Gearfinder   Right-click: set waypoint", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pin:SetScript("OnClick", function(self, button)
        if button == "RightButton" and self.mapID and self.x and C_Map and C_Map.SetUserWaypoint and _G.UiMapPoint then
            pcall(function()
                C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(self.mapID, self.x, self.y))
                if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
            end)
        elseif GF.UI.Toggle then
            GF.UI.Toggle()
        end
    end)
    pool[index] = pin
    return pin
end

-- ---------- collect what to draw on the open map ----------
local function Collect(mapID)
    local list, seen = {}, {}
    local function Add(entry)
        local key = Canon(entry.name)
        if seen[key] then return end
        local meta = GF.Data.GetInstanceMeta(entry.name)
        if meta and meta.unavailable then return end
        seen[key] = true
        entry.key = key
        list[#list + 1] = entry
    end
    -- 1) the game's own entrances (discovered ones)
    if C_EncounterJournal and C_EncounterJournal.GetDungeonEntrancesForMap then
        local ok, entrances = pcall(C_EncounterJournal.GetDungeonEntrancesForMap, mapID)
        if ok and type(entrances) == "table" then
            for _, e in ipairs(entrances) do
                local x, y = XY(e.position)
                if x and y then
                    Add({ name = e.name, x = x, y = y, journalInstanceID = e.journalInstanceID, atlas = e.atlasName, source = "game",
                          isRaid = (e.atlasName == "Raid") })
                end
            end
        end
    end
    -- 2) entrances you walked into
    for _, e in pairs(DB().entrances) do
        if e.mapID == mapID then Add({ name = e.name, x = e.x, y = e.y, source = "learned", isRaid = e.raid }) end
    end
    -- 3) built-in approximate table, matched by zone name
    local zone = MapName(mapID)
    if zone and GF.Data.Entrances then
        local zoneKey = zone:lower()
        for _, e in ipairs(GF.Data.Entrances) do
            if e.zone:lower() == zoneKey then Add({ name = e.name, x = e.x, y = e.y, source = "builtin", isRaid = e.raid }) end
        end
    end
    return list
end

local function FindInstance(entry)
    local instances = GF.API.instances or {}
    if entry.journalInstanceID then
        local inst = instances[tostring(entry.journalInstanceID)]
        if inst then return tostring(entry.journalInstanceID), inst end
    end
    for key, inst in pairs(instances) do
        if Canon(inst.name) == entry.key then return key, inst end
    end
end

function Pins.Update()
    for _, pin in ipairs(pool) do pin:Hide() end
    if not Pins.IsEnabled() or not _G.WorldMapFrame or not WorldMapFrame.GetMapID or not WorldMapFrame.GetCanvas then return end
    local mapID = WorldMapFrame:GetMapID()
    if not mapID then return end
    local canvas = WorldMapFrame:GetCanvas()
    local width, height = canvas:GetWidth(), canvas:GetHeight()
    local scale = 1
    if WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.GetCanvasScale then
        scale = tonumber(WorldMapFrame.ScrollContainer:GetCanvasScale()) or 1
    end
    if scale <= 0 then scale = 1 end

    local shown = 0
    for _, entry in ipairs(Collect(mapID)) do
        shown = shown + 1
        local pin = GetPin(shown)
        local key, inst = FindInstance(entry)
        pin.inst, pin.name, pin.mapID, pin.x, pin.y, pin.source = inst, entry.name, mapID, entry.x, entry.y, entry.source
        pin.isRaid = (inst and inst.isRaid) or entry.isRaid or false
        pin.upgrades = key and GF.API.GetInstanceUpgrades(key) or {}
        pin.badge:SetText(#pin.upgrades > 0 and tostring(#pin.upgrades) or "")
        SetIcon(pin, pin.isRaid, entry.atlas)
        pin:SetScale(1 / scale)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", canvas, "TOPLEFT", (entry.x * width) * scale, -(entry.y * height) * scale)
        pin:Show()
    end
end

function Pins.Setup()
    if hooked or not _G.WorldMapFrame then return end
    hooked = true
    if WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", Pins.Update) end
    if WorldMapFrame.HookScript then WorldMapFrame:HookScript("OnShow", Pins.Update) end
end
