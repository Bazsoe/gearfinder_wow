-- Gearfinder bootstrap (WoW Forever). No external data: loot comes from the live game client.
Gearfinder = Gearfinder or {}
local GF = Gearfinder
do
    -- The version comes from the TOC; the CurseForge packager writes the release tag (e.g. v2.15.0) there.
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    local v = getMeta and getMeta("Gearfinder", "Version")
    if not v or v == "" or v:find("@") then v = "2.14.0-dev" end
    GF.version = v:gsub("^v", "")
end
GF.Data = GF.Data or {}
GF.State = GF.State or { status = "Press Refresh to read the dungeons and raids from the live game.", loading = false }
GF.API = GF.API or {}
GF.UI = GF.UI or {}

local eventFrame = CreateFrame("Frame")
-- RegisterEvent raises an error for event names a client does not know, so every registration is protected.
for _, name in ipairs({
    "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GET_ITEM_INFO_RECEIVED",
    "PLAYER_TALENT_UPDATE", "CHARACTER_POINTS_CHANGED", "PLAYER_LEVEL_UP", "UNIT_LEVEL",
    "ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "TRAIT_CONFIG_UPDATED",
    "LOOT_OPENED", "ENCOUNTER_END", "PLAYER_LEAVING_WORLD",
}) do
    pcall(eventFrame.RegisterEvent, eventFrame, name)
end

local function InitDB()
    GearfinderCharDB = GearfinderCharDB or {}
    GearfinderDB = GearfinderDB or {}
    GearfinderDB.minimap = GearfinderDB.minimap or {}
    GearfinderDB.learned = GearfinderDB.learned or {}
end

eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "Gearfinder" then
        InitDB()
        if GF.API.LoadSavedCache then GF.API.LoadSavedCache() end
    elseif event == "PLAYER_LOGIN" then
        InitDB()
        if GF.API.LoadSavedCache then GF.API.LoadSavedCache() end
        if GF.API.RecalculateCached then GF.API.RecalculateCached() end
        if GF.UI.Create then GF.UI.Create() end
        if GF.UI.CreateCharacterButton then GF.UI.CreateCharacterButton() end
        if GF.UI.CreateMinimapButton then GF.UI.CreateMinimapButton() end
        if GF.UI.MapPins then GF.UI.MapPins.Setup() end
        if GF.UI.Refresh then GF.UI.Refresh() end
        -- One automatic refresh a few seconds after login, only when the catalogue is empty or the game
        -- build changed (never repeated, never on a timer). Switch off with /gf auto off.
        -- Detect a new WoW Forever client build (e.g. 1.60.1.70938 -> 1.60.1.71091) and say so in chat.
        local clientVersion, clientBuild = GetBuildInfo()
        local current = tostring(clientVersion) .. "." .. tostring(clientBuild)
        local previous = GearfinderDB.lastClient
        GearfinderDB.lastClient = current
        local buildChanged = previous ~= nil and previous ~= current
        if buildChanged then
            print("|cffd9b15fGearfinder|r new WoW Forever client detected: |cffaaaaaa" .. previous .. "|r → |cff66ff66" .. current .. "|r. "
                .. (GearfinderDB.autoRefresh ~= false and "Item data will be re-read in a few seconds." or "Press |cffffff00Refresh|r to re-read the item data."))
        end
        if GearfinderDB.autoRefresh ~= false and C_Timer and C_Timer.After then
            C_Timer.After(8, function()
                local info = GF.Catalog.GetInfo()
                if (buildChanged or not info.hasScan or info.outdated or info.items == 0) and not GF.State.loading then GF.API.Refresh() end
            end)
        end
        print("|cffd9b15fGearfinder|r " .. GF.version .. " loaded. Click the |cffffff00minimap button|r, then press |cffffff00Refresh|r to read the live dungeons and raids.")
    elseif event == "PLAYER_LEAVING_WORLD" then
        if GF.UI.MapPins then GF.UI.MapPins.OnLeavingWorld() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if GF.UI.MapPins then GF.UI.MapPins.OnEnteringWorld() end
        if GF.UI.CreateCharacterButton then GF.UI.CreateCharacterButton() end
        if GF.UI.CreateMinimapButton then GF.UI.CreateMinimapButton() end
        if GF.UI.MapPins then GF.UI.MapPins.Setup() end
    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_WorldMap" then
        if GF.UI.MapPins then GF.UI.MapPins.Setup() end
    elseif event == "ADDON_LOADED" and (arg1 == "Blizzard_CharacterUI" or arg1 == "Blizzard_CharacterFrame") then
        if GF.UI.CreateCharacterButton then GF.UI.CreateCharacterButton() end
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        if GF.API.OnItemInfoReceived then GF.API.OnItemInfoReceived(arg1, arg2) end
    elseif event == "LOOT_OPENED" then
        if GF.Catalog and GF.Catalog.OnLootOpened then GF.Catalog.OnLootOpened() end
    elseif event == "ENCOUNTER_END" then
        -- ENCOUNTER_END: encounterID, encounterName, difficultyID, groupSize, success
        if GF.Catalog and GF.Catalog.OnEncounterEnd then GF.Catalog.OnEncounterEnd(arg1, arg2) end
    elseif event == "PLAYER_TALENT_UPDATE" or event == "CHARACTER_POINTS_CHANGED" or event == "PLAYER_LEVEL_UP"
        or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" or event == "TRAIT_CONFIG_UPDATED"
        or (event == "UNIT_LEVEL" and arg1 == "player") then
        -- Re-score already cached records only. This never queries items or the journal.
        if GF.API.RecalculateCached then GF.API.RecalculateCached() end
        if GF.UI.Refresh then GF.UI.Refresh() end
    end
end)

-- /gf, /gearfinder: toggle the window; "/gf refresh" reads the data now; "/gf auto on|off"; "/gf probe" prints a journal diagnostic; "/gf info" prints build details
SLASH_GEARFINDER1 = "/gf"
SLASH_GEARFINDER2 = "/gearfinder"
if SlashCmdList then SlashCmdList["GEARFINDER"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local prefix = "|cffd9b15fGearfinder|r "
    if msg == "probe" then
        for _, line in ipairs(GF.Catalog.Probe()) do print(prefix .. line) end
    elseif msg == "refresh" or msg == "scan" or msg == "reload" then
        local ok, why = GF.API.Refresh()
        print(prefix .. (ok and "Refresh started…" or tostring(why)))
    elseif msg == "auto on" or msg == "auto off" then
        GearfinderDB.autoRefresh = (msg == "auto on")
        print(prefix .. "Automatic refresh after login: " .. (GearfinderDB.autoRefresh and "on" or "off"))
    elseif msg == "logo" or msg:find("^logo ") then
        local arg = msg:match("^logo%s+(%S+)")
        local map = { ["1"] = "amber", amber = "amber", gold = "amber", arany = "amber", ["2"] = "arcane", arcane = "arcane", blue = "arcane", kek = "arcane" }
        print(prefix .. "Logo: " .. GF.UI.SetLogo(arg and map[arg] or nil))
    elseif msg == "info" then
        GF.UI.Minimap.PrintInfo()
    elseif GF.UI and GF.UI.Toggle then
        GF.UI.Toggle()
    end
end
end
