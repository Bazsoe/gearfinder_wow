-- Gearfinder live catalogue: dungeon and raid loot read from the game's own Encounter Journal.
-- Nothing is scanned on login or on a timer: the journal is read once, when the player presses
-- Refresh, and the result is saved so the recommendations are instant on the next login.
-- Items that drop in play (LOOT_OPENED inside an instance) are remembered as "learned" sources, because
-- Forever's journal may not list every drop yet.
local GF = Gearfinder
GF.Catalog = GF.Catalog or {}
local Catalog = GF.Catalog

local SKIP_EQUIP = {
    [""] = true, INVTYPE_BAG = true, INVTYPE_AMMO = true, INVTYPE_QUIVER = true,
    INVTYPE_TABARD = true, INVTYPE_BODY = true, INVTYPE_NON_EQUIP_IGNORE = true,
}

local SCHEMA = 5 -- bump when the stored catalogue/item format changes, so Refresh re-reads everything

local function DB()
    GearfinderDB = GearfinderDB or {}
    GearfinderDB.learned = GearfinderDB.learned or {}
    return GearfinderDB
end

local function IsEquipment(itemID)
    local _, _, _, equipLoc = GF.Compat.GetItemInfoInstant(itemID)
    if equipLoc == nil then return true end -- unknown yet: keep, the item pass filters it later
    return not SKIP_EQUIP[equipLoc]
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g, h = pcall(fn, ...)
    if ok then return a, b, c, d, e, f, g, h end
    return nil
end

-- ---------- Journal helpers (tolerant of the retail-style and the classic-style signatures) ----------
local JOURNAL_ADDONS = { "Blizzard_EncounterJournal", "Blizzard_AdventureGuide", "Blizzard_EncounterJournalClassic" }
local function LoadJournal()
    local loader = (C_AddOns and C_AddOns.LoadAddOn) or _G.LoadAddOn
    if not loader then return end
    for _, name in ipairs(JOURNAL_ADDONS) do pcall(loader, name) end
    -- Opening and closing the journal frame once makes the client populate its tier/instance data.
    if _G.EncounterJournal and _G.EncounterJournal.IsShown and not _G.EncounterJournal:IsShown() and _G.ToggleEncounterJournal then
        pcall(_G.ToggleEncounterJournal)
        pcall(_G.ToggleEncounterJournal)
    end
end

local function ListInstances()
    local list, seen = {}, {}
    if type(_G.EJ_GetInstanceByIndex) ~= "function" then return list end
    local tiers = Call(_G.EJ_GetNumTiers) or 1
    -- tier 0 = "no tier selected" (some clients list everything then), then every real tier
    for tier = 0, math.max(1, tonumber(tiers) or 1) do
        if tier > 0 and _G.EJ_SelectTier then Call(_G.EJ_SelectTier, tier) end
        for _, isRaid in ipairs({ false, true }) do
            local index = 1
            while index < 300 do
                local id, name = Call(_G.EJ_GetInstanceByIndex, index, isRaid)
                if not id then break end
                if not seen[id] then
                    seen[id] = true
                    list[#list + 1] = { id = id, name = name or ("Instance " .. id), isRaid = isRaid }
                end
                index = index + 1
            end
        end
    end
    return list
end

local function ResetLootFilters()
    -- The journal normally filters loot to the current class/spec; show everything.
    if _G.EJ_ResetLootFilter then Call(_G.EJ_ResetLootFilter) end
    if _G.EJ_SetLootFilter then Call(_G.EJ_SetLootFilter, 0, 0) end
    if C_EncounterJournal and C_EncounterJournal.ResetSlotFilter then Call(C_EncounterJournal.ResetSlotFilter) end
    if C_EncounterJournal and C_EncounterJournal.SetSlotFilter and _G.Enum and Enum.ItemSlotFilterType then
        Call(C_EncounterJournal.SetSlotFilter, Enum.ItemSlotFilterType.NoFilter)
    end
end

local function ReadLoot(index)
    if C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex then
        local info = Call(C_EncounterJournal.GetLootInfoByIndex, index)
        if type(info) == "table" then return info.itemID, info.encounterID end
    end
    if _G.EJ_GetLootInfoByIndex then
        -- name, icon, slot, armorType, itemID, link, encounterID
        local _, _, _, _, itemID, _, encounterID = Call(_G.EJ_GetLootInfoByIndex, index)
        return itemID, encounterID
    end
end

local function CollectCurrentLoot(into, bossName, instanceKey)
    local count = tonumber(Call(_G.EJ_GetNumLoot)) or 0
    local added = 0
    for i = 1, count do
        local itemID = ReadLoot(i)
        itemID = tonumber(itemID)
        if itemID and IsEquipment(itemID) then
            local list = into[itemID]
            if not list then list = {}; into[itemID] = list end
            local duplicate = false
            for _, src in ipairs(list) do
                if src.inst == instanceKey and src.boss == bossName then duplicate = true; break end
            end
            if not duplicate then list[#list + 1] = { inst = instanceKey, boss = bossName }; added = added + 1 end
        end
    end
    return added, count
end

local function ScanInstance(instance, items)
    Call(_G.EJ_SelectInstance, instance.id)
    ResetLootFilters()
    local key = tostring(instance.id)
    local bosses, found = {}, 0
    local index = 1
    while index < 80 do
        local name, _, encounterID = Call(_G.EJ_GetEncounterInfoByIndex, index)
        if not name then break end
        bosses[#bosses + 1] = name
        if encounterID then Call(_G.EJ_SelectEncounter, encounterID) end
        local added = CollectCurrentLoot(items, name, key)
        found = found + added
        index = index + 1
    end
    -- Instance-wide pass catches trash / non-boss drops that the per-boss lists do not contain.
    if _G.EJ_SelectEncounter then Call(_G.EJ_SelectEncounter, 0) end
    ResetLootFilters()
    local extra = CollectCurrentLoot(items, "Trash / other drops", key)
    -- Items already attributed to a boss should not also be listed as trash; drop the duplicates.
    for _, list in pairs(items) do
        local hasBoss = false
        for _, src in ipairs(list) do if src.inst == key and src.boss ~= "Trash / other drops" then hasBoss = true end end
        if hasBoss then
            for i = #list, 1, -1 do
                if list[i].inst == key and list[i].boss == "Trash / other drops" then table.remove(list, i) end
            end
        end
    end
    return bosses, found + extra
end

-- ---------- Public: scan ----------
-- Reads every dungeon and raid in the journal. Runs in small steps (one instance per frame), never in
-- a repeating timer. onDone(ok, message) is called when finished.
-- Plain-language report of what the journal API does on this client (used by /gf probe and the i button).
function Catalog.Probe()
    local out = {}
    local function Add(text) out[#out + 1] = text end
    local names = { "EJ_GetNumTiers", "EJ_SelectTier", "EJ_GetInstanceByIndex", "EJ_SelectInstance", "EJ_GetEncounterInfoByIndex",
        "EJ_SelectEncounter", "EJ_GetNumLoot", "EJ_GetLootInfoByIndex", "EJ_ResetLootFilter", "EJ_SetLootFilter" }
    local missing = {}
    for _, n in ipairs(names) do if type(_G[n]) ~= "function" then missing[#missing + 1] = n end end
    Add("journal functions missing: " .. (#missing == 0 and "none" or table.concat(missing, ", ")))
    Add("C_EncounterJournal.GetLootInfoByIndex: " .. tostring(C_EncounterJournal and type(C_EncounterJournal.GetLootInfoByIndex) or "no table"))
    -- which journal-like addons / APIs does this client have at all?
    local found = {}
    local getNum = (C_AddOns and C_AddOns.GetNumAddOns) or _G.GetNumAddOns
    local getInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or _G.GetAddOnInfo
    if getNum and getInfo then
        for i = 1, getNum() do
            local ok, a, b = pcall(getInfo, i)
            local name = ok and (type(a) == "table" and a.name or a) or nil
            if name and (name:lower():find("journal") or name:lower():find("adventure") or name:lower():find("encounter")) then found[#found + 1] = name end
        end
    end
    Add("journal-like addons: " .. (#found > 0 and table.concat(found, ", ") or "none found"))
    local apiKeys = {}
    if type(_G.C_EncounterJournal) == "table" then for k in pairs(_G.C_EncounterJournal) do apiKeys[#apiKeys + 1] = k end end
    table.sort(apiKeys)
    Add("C_EncounterJournal functions: " .. (#apiKeys > 0 and table.concat(apiKeys, ", ") or "none"))
    LoadJournal()
    Add("EncounterJournal frame: " .. tostring(_G.EncounterJournal ~= nil) .. ", ToggleEncounterJournal: " .. tostring(type(_G.ToggleEncounterJournal)))
    local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal")) or (_G.IsAddOnLoaded and _G.IsAddOnLoaded("Blizzard_EncounterJournal"))
    Add("Blizzard_EncounterJournal loaded: " .. tostring(loaded))
    if type(_G.EJ_GetNumTiers) == "function" then
        local ok, tiers = pcall(_G.EJ_GetNumTiers)
        Add("tiers: " .. tostring(ok and tiers or ("error: " .. tostring(tiers))))
    end
    local instances = ListInstances()
    local dungeons, raids = 0, 0
    for _, i in ipairs(instances) do if i.isRaid then raids = raids + 1 else dungeons = dungeons + 1 end end
    if GF.AtlasLoot then
        local names = GF.AtlasLoot.ModuleNames()
        Add("AtlasLoot addons: " .. (#names > 0 and table.concat(names, ", ") or "none installed"))
        if #names > 0 then
            local items, _, count, reason = GF.AtlasLoot.Import()
            local n = 0
            if items then for _ in pairs(items) do n = n + 1 end end
            Add("AtlasLoot import: " .. count .. " instances, " .. n .. " items" .. (reason and (" (" .. reason .. ")") or ""))
            local atlas = _G.AtlasLoot
            if type(atlas) == "table" and type(atlas.ItemDB) == "table" and type(atlas.ItemDB.Storage) == "table" then
                local keys = {}
                for k in pairs(atlas.ItemDB.Storage) do keys[#keys + 1] = tostring(k) end
                table.sort(keys)
                Add("AtlasLoot storage: " .. table.concat(keys, ", "))
            end
        end
    end
    Add("journal lists: " .. dungeons .. " dungeons, " .. raids .. " raids")
    for i = 1, math.min(4, #instances) do Add("  e.g. " .. tostring(instances[i].name) .. " (" .. tostring(instances[i].id) .. ")") end
    if instances[1] and type(_G.EJ_SelectInstance) == "function" then
        local ok, err = pcall(_G.EJ_SelectInstance, instances[1].id)
        ResetLootFilters()
        local bosses = 0
        for idx = 1, 40 do if Call(_G.EJ_GetEncounterInfoByIndex, idx) then bosses = bosses + 1 else break end end
        Add("first instance: SelectInstance " .. tostring(ok and "ok" or err) .. ", bosses " .. bosses .. ", loot rows " .. tostring(Call(_G.EJ_GetNumLoot)))
    end
    return out
end

function Catalog.Scan(onProgress, onDone)
    if type(_G.EJ_GetInstanceByIndex) ~= "function" or type(_G.EJ_SelectInstance) ~= "function" then
        if onDone then onDone(false, "This client has no Encounter Journal API.") end
        return
    end
    LoadJournal()
    local instances = ListInstances()
    if #instances == 0 and GF.AtlasLoot then
        -- Forever has no Encounter Journal data: read the loot from an installed AtlasLoot instead.
        local alItems, alMeta, alCount, alReason = GF.AtlasLoot.Import()
        if alItems then
            for itemID in pairs(alItems) do if not IsEquipment(itemID) then alItems[itemID] = nil end end
            local build = select(2, GetBuildInfo())
            DB().catalog = { build = build, time = time and time() or 0, instances = alMeta, items = alItems, source = "AtlasLoot", schema = SCHEMA }
            Catalog.BuildIndex()
            if onDone then onDone(true, alCount .. " instances from AtlasLoot") end
            return
        end
        -- Neither the journal nor AtlasLoot: use the catalogue that ships inside Gearfinder.
        local bundled = GF.Data and GF.Data.Loot
        if bundled and bundled.items and next(bundled.items) then
            local build = select(2, GetBuildInfo())
            local instances = {}
            for key, inst in pairs(bundled.instances or {}) do
                local copy = {}
                for k, v in pairs(inst) do copy[k] = v end
                local hint = GF.Data.GetInstanceMeta(copy.name) or {}
                copy.isRaid = copy.isRaid or hint.raid or false
                copy.size = copy.size or hint.size; copy.new = copy.new or hint.new
                copy.min = copy.min or hint.min; copy.max = copy.max or hint.max; copy.unlock = copy.unlock or hint.unlock
                instances[key] = copy
            end
            DB().catalog = { build = build, time = time and time() or 0, instances = instances, items = bundled.items,
                source = "built-in", schema = SCHEMA }
            Catalog.BuildIndex()
            if onDone then onDone(true, "built-in catalogue") end
            return
        end
        if onDone then onDone(false, "The game has no Encounter Journal data and " .. tostring(alReason or "AtlasLoot was not found") .. " Install AtlasLoot Classic Forever, then press Refresh.") end
        return
    end
    if #instances == 0 then
        if onDone then onDone(false, "The Encounter Journal returned no instances. Type /gf probe in chat and send me the lines it prints.") end
        return
    end
    local items, meta, cursor, emptyRetries = {}, {}, 1, 0
    local function Step()
        local instance = instances[cursor]
        if not instance then
            local build = select(2, GetBuildInfo())
            DB().catalog = { build = build, time = time and time() or 0, instances = meta, items = items, schema = SCHEMA }
            Catalog.BuildIndex()
            if onDone then onDone(true, #instances .. " instances read") end
            return
        end
        local bosses, found = ScanInstance(instance, items)
        -- Journal data can load lazily: if an instance with bosses returned nothing, retry shortly.
        if found == 0 and #bosses > 0 and emptyRetries < 2 then
            emptyRetries = emptyRetries + 1
            if C_Timer and C_Timer.After then C_Timer.After(0.25, Step) else Step() end
            return
        end
        emptyRetries = 0
        local hint = GF.Data.GetInstanceMeta(instance.name) or {}
        meta[tostring(instance.id)] = {
            id = instance.id, name = instance.name, isRaid = instance.isRaid or hint.raid or false,
            bosses = bosses, size = hint.size, new = hint.new, min = hint.min, max = hint.max, unlock = hint.unlock,
        }
        cursor = cursor + 1
        if onProgress then onProgress(cursor - 1, #instances, instance.name) end
        if C_Timer and C_Timer.After then C_Timer.After(0, Step) else Step() end
    end
    Step()
end

-- ---------- Index used by the recommendation engine ----------
-- API.catalogByID[itemID] = { {id, instance, instanceName, boss, isRaid, mode}, ... }
function Catalog.BuildIndex()
    local API = GF.API
    API.catalogByID = {}
    API.instances = {}
    local saved = DB().catalog
    if not saved and GF.Data and GF.Data.Loot and GF.Data.Loot.items then saved = GF.Data.Loot end
    local function Push(itemID, instKey, boss, instName, isRaid)
        local list = API.catalogByID[itemID]
        if not list then list = {}; API.catalogByID[itemID] = list end
        for _, rec in ipairs(list) do
            if rec.instance == instKey and rec.boss == boss then return end
        end
        list[#list + 1] = { id = itemID, instance = instKey, instanceName = instName, boss = boss, isRaid = isRaid, mode = "Normal" }
    end
    if saved then
        for key, inst in pairs(saved.instances or {}) do API.instances[key] = inst end
        for itemID, sources in pairs(saved.items or {}) do
            for _, src in ipairs(sources) do
                local inst = API.instances[src.inst] or {}
                Push(itemID, src.inst, src.boss, inst.name or src.inst, inst.isRaid)
            end
        end
    end
    -- Fresh loot for the new Forever dungeons (Data/LootUpdate.lua), merged into whatever catalogue is in use.
    local update = GF.Data and GF.Data.LootUpdate
    if update and update.instances then
        local byCanon = {}
        for key, inst in pairs(API.instances) do byCanon[GF.Data.CanonicalName(inst.name or key)] = key end
        for _, entry in ipairs(update.instances) do
            local canon = GF.Data.CanonicalName(entry.name)
            local key = byCanon[canon]
            if not key then
                key = "al:" .. canon
                local hint = GF.Data.GetInstanceMeta(entry.name) or {}
                API.instances[key] = { id = key, name = entry.name, isRaid = hint.raid or false, bosses = {},
                    size = hint.size, new = entry.new or hint.new, min = entry.min or hint.min, max = entry.max or hint.max,
                    unlock = hint.unlock }
                byCanon[canon] = key
            end
            local inst = API.instances[key]
            for _, row in ipairs(entry.items) do
                Push(row[1], key, row[2], inst.name or entry.name, inst.isRaid)
            end
        end
    end
    for itemID, sources in pairs(DB().learned) do
        itemID = tonumber(itemID)
        for _, src in ipairs(sources) do
            -- A learned source whose instance the journal already knows by name is merged into it.
            local key = "learned:" .. tostring(src.inst)
            local wanted = GF.Data.CanonicalName(src.inst)
            for instKey, inst in pairs(API.instances) do
                if GF.Data.CanonicalName(inst.name or instKey) == wanted then key = instKey break end
            end
            if not API.instances[key] then
                local hint = GF.Data.GetInstanceMeta(src.inst) or {}
                API.instances[key] = { id = key, name = src.inst, isRaid = src.isRaid or hint.raid or false,
                    size = hint.size, new = hint.new, min = hint.min, max = hint.max, unlock = hint.unlock, learned = true }
            end
            Push(itemID, key, src.boss, src.inst, src.isRaid)
        end
    end
end

function Catalog.GetInfo()
    local saved = DB().catalog
    local instances, dungeons, raids = 0, 0, 0
    for _, inst in pairs(GF.API.instances or {}) do
        instances = instances + 1
        if inst.isRaid then raids = raids + 1 else dungeons = dungeons + 1 end
    end
    local items = 0
    for _ in pairs(GF.API.catalogByID or {}) do items = items + 1 end
    local learned = 0
    for _ in pairs(DB().learned) do learned = learned + 1 end
    local currentBuild = select(2, GetBuildInfo())
    return {
        hasScan = DB().catalog ~= nil, time = saved and saved.time or nil, build = saved and saved.build or nil,
        outdated = saved ~= nil and (tostring(saved.build) ~= tostring(currentBuild) or saved.schema ~= SCHEMA),
        instances = instances, dungeons = dungeons, raids = raids, items = items, learned = learned,
    }
end

-- ---------- Learned drops ----------
local lastBoss, lastBossTime
function Catalog.OnEncounterEnd(_, name)
    lastBoss, lastBossTime = name, GetTime and GetTime() or 0
end

function Catalog.OnLootOpened()
    local instanceName, instanceType
    local ok, name, kind = pcall(GetInstanceInfo)
    if ok then instanceName, instanceType = name, kind end
    if instanceType ~= "party" and instanceType ~= "raid" then return end
    if type(GetNumLootItems) ~= "function" or type(GetLootSlotLink) ~= "function" then return end
    local boss = "Trash / other drops"
    if lastBoss and GetTime and (GetTime() - (lastBossTime or 0)) < 180 then boss = lastBoss end
    local learned, changed = DB().learned, false
    for slot = 1, (GetNumLootItems() or 0) do
        local okLink, link = pcall(GetLootSlotLink, slot)
        local itemID = okLink and type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
        if itemID and IsEquipment(itemID) then
            local list = learned[itemID]
            if not list then list = {}; learned[itemID] = list end
            local seen = false
            for _, src in ipairs(list) do if src.inst == instanceName and src.boss == boss then seen = true end end
            if not seen then
                list[#list + 1] = { inst = instanceName, boss = boss, isRaid = instanceType == "raid" }
                changed = true
            end
        end
    end
    if changed then
        Catalog.BuildIndex()
        -- The looted item is in the client cache right now: read it immediately (no server request).
        for slot = 1, (GetNumLootItems() or 0) do
            local okLink, link = pcall(GetLootSlotLink, slot)
            local itemID = okLink and type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
            if itemID and GF.API.ProcessItem then pcall(GF.API.ProcessItem, itemID) end
        end
        GF.API.RecalculateCached()
        if GF.UI and GF.UI.Refresh then GF.UI.Refresh() end
    end
end
