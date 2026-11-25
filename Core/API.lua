-- Gearfinder data API for WoW Forever.
-- Source of truth: the live client. The Refresh button (and only the Refresh button) reads the
-- Encounter Journal (Core/Catalog.lua), then asks the client for every item's data. Results are saved
-- account-wide, so the recommendations are available instantly on the next login.
local GF = Gearfinder
GF.API = GF.API or {}
local API = GF.API
API.version = 2
API.itemCache = API.itemCache or {}
API.recommendations = API.recommendations or {}
API.pending = {}
API.pendingCount = 0
API.catalogByID = API.catalogByID or {}
API.instances = API.instances or {}
API.lastRefreshCompleted = false

local function CopyTable(source)
    local out = {}
    for key, value in pairs(source or {}) do out[key] = value end
    return out
end

local function CurrentBuild()
    return tostring(select(2, GetBuildInfo()))
end

function API.LoadSavedCache()
    GearfinderDB = GearfinderDB or {}
    GearfinderDB.items = GearfinderDB.items or {}
    API.itemCache = GearfinderDB.items
    if GF.Catalog and GF.Catalog.BuildIndex then GF.Catalog.BuildIndex() end
end

-- ---------- Settings (per character) ----------
local function CharDB()
    GearfinderCharDB = GearfinderCharDB or {}
    return GearfinderCharDB
end

-- Source filter: "all" | "dungeon" | "raid"
function API.GetSourceFilter() return CharDB().sourceFilter or "all" end
function API.SetSourceFilter(mode)
    if mode ~= "dungeon" and mode ~= "raid" then mode = "all" end
    CharDB().sourceFilter = mode
    API.RecalculateCached()
    if GF.UI and GF.UI.Refresh then GF.UI.Refresh() end
end

-- Loot filter: "all" | "boss" | "trash"
function API.GetLootFilter() return CharDB().lootFilter or "all" end
function API.SetLootFilter(mode)
    if mode ~= "boss" and mode ~= "trash" and mode ~= "quest" then mode = "all" end
    CharDB().lootFilter = mode
    API.RecalculateCached()
    if GF.UI and GF.UI.Refresh then GF.UI.Refresh() end
end

-- Instance filter: nil = every instance, otherwise one instance key from API.instances
function API.GetInstanceFilter()
    local key = CharDB().instanceFilter
    if key and API.instances and not API.instances[key] then return nil end
    return key
end
function API.SetInstanceFilter(key)
    CharDB().instanceFilter = key
    API.RecalculateCached()
    if GF.UI and GF.UI.Refresh then GF.UI.Refresh() end
end

-- Instances for the dungeon picker: dungeons first, then raids, each sorted by level then name.
function API.GetInstanceList()
    local list = {}
    for key, inst in pairs(API.instances or {}) do if not API.IsInstanceUnavailable(key) then list[#list + 1] = { key = key, name = inst.name or key, isRaid = inst.isRaid, min = inst.min } end end
    table.sort(list, function(a, b)
        if (a.isRaid and 1 or 0) ~= (b.isRaid and 1 or 0) then return not a.isRaid end
        if (a.min or 99) ~= (b.min or 99) then return (a.min or 99) < (b.min or 99) end
        return tostring(a.name) < tostring(b.name)
    end)
    return list
end

local TRASH_PATTERNS = { "^trash", "other drops", "^keys?$", "^all bosses$", "sets$", "^plans$", "^class books", "^world drop" }
-- "boss" | "trash" | "quest"
function API.RecordKind(record)
    local boss = tostring(record.boss or ""):lower()
    if boss:find("^quest") or boss:find("quest reward") or boss:find("only quest") or boss:find("%(horde quest%)") or boss:find("%(alliance quest%)") then return "quest" end
    if boss == "" or boss == "drop" then return "trash" end
    for _, pattern in ipairs(TRASH_PATTERNS) do if boss:find(pattern) then return "trash" end end
    return "boss"
end
function API.IsTrashRecord(record) return API.RecordKind(record) == "trash" end

-- Level look-ahead: how many levels above the character an item's required level may be (0, 5, or 99 = all).
function API.GetLevelAhead() return tonumber(CharDB().levelAhead) or 0 end
function API.SetLevelAhead(value)
    CharDB().levelAhead = tonumber(value) or 0
    API.RecalculateCached()
    if GF.UI and GF.UI.Refresh then GF.UI.Refresh() end
end

-- ---------- Item data ----------
-- Reads one item from the client cache. Returns true when the item was available.
local function ProcessItem(itemID)
    local Compat = GF.Compat
    if not Compat.HasItemInfo() then return false end
    local name, link, quality, itemLevel, requiredLevel, itemType, itemSubType, _, equipLoc, texture, _, classID, subclassID = Compat.GetItemInfo(itemID)
    if not name then return false end
    local cache = API.itemCache[itemID] or {}
    cache.name, cache.link, cache.quality = name, link, quality
    cache.itemLevel = tonumber(itemLevel) or 0
    cache.requiredLevel = tonumber(requiredLevel) or 0
    cache.itemType, cache.itemSubType = itemType, itemSubType
    cache.equipLoc = equipLoc
    cache.texture = texture
    cache.itemClass = tonumber(classID)
    cache.subclass = tonumber(subclassID)
    if not cache.equipLoc or not cache.itemClass then
        local _, _, _, instantLoc, icon, instantClass, instantSub = Compat.GetItemInfoInstant(itemID)
        cache.equipLoc = cache.equipLoc or instantLoc
        cache.texture = cache.texture or icon
        cache.itemClass = cache.itemClass or tonumber(instantClass)
        cache.subclass = cache.subclass or tonumber(instantSub)
    end
    local stats, restriction, tooltipLevel = GF.Stats.FromLink(link or ("item:" .. itemID))
    -- Some Forever items report 0 from the item API; the tooltip's "Requires Level N" is authoritative.
    if tooltipLevel and tooltipLevel > (cache.requiredLevel or 0) then cache.requiredLevel = tooltipLevel end
    cache.stats = stats
    cache.classRestriction = restriction
    cache.scanBuild = CurrentBuild()
    cache.scanVersion = 3
    API.itemCache[itemID] = cache
    return true
end

API.ProcessItem = ProcessItem

local function NeedsItemPass(itemID)
    local cache = API.itemCache[itemID]
    return not (cache and cache.name and type(cache.stats) == "table" and cache.scanBuild == CurrentBuild() and cache.scanVersion == 3)
end

local function MergeItemData(record)
    local cache = API.itemCache[record.id] or {}
    local item = CopyTable(cache)
    item.id, item.itemID = record.id, record.id
    item.name = cache.name or ("Item #" .. tostring(record.id))
    item.requiredLevel = tonumber(cache.requiredLevel) or 0
    item.itemLevel = tonumber(cache.itemLevel) or 0
    item.slot = GF.ItemFilter.GetSlot({ equipLoc = cache.equipLoc })
    item.stats = type(cache.stats) == "table" and cache.stats or {}
    item.statsReady = next(item.stats) ~= nil
    item.statsSource = cache.name and "WoW Forever client (live)" or "not loaded yet"
    item.dungeon, item.dungeonName, item.boss = record.instance, record.instanceName, record.boss
    item.isRaid = record.isRaid
    item.mode = record.mode or "Normal"
    item.sourceType = record.isRaid and "Raid" or "Dungeon"
    return item
end

local function SourceText(record)
    return tostring(record.instanceName or "Instance") .. " — " .. tostring(record.boss or "Drop")
end

function API.GetItemSources(itemID)
    local out, seen = {}, {}
    for _, record in ipairs(API.catalogByID[tonumber(itemID)] or {}) do
        local text = SourceText(record)
        if not seen[text] then seen[text] = true; out[#out + 1] = text end
    end
    return out
end

function API.GetItemData(itemID)
    local records = API.catalogByID[tonumber(itemID)]
    if not records or not records[1] then return nil end
    local item = MergeItemData(records[1])
    item.sources = API.GetItemSources(itemID)
    return item
end
API.GetItem = API.GetItemData

function API.GetInstances() return API.instances or {} end

function API.Search(query)
    query = tostring(query or ""):lower()
    local results = {}
    for itemID in pairs(API.catalogByID) do
        local data = API.GetItemData(itemID)
        if data then
            local haystack = (tostring(data.name) .. " " .. table.concat(data.sources, " ") .. " " .. tostring(itemID)):lower()
            if query == "" or haystack:find(query, 1, true) then results[#results + 1] = data end
        end
    end
    table.sort(results, function(a, b) return tostring(a.name) < tostring(b.name) end)
    return results
end

function API.GetDiagnostics()
    local info = GF.Catalog.GetInfo()
    return {
        apiVersion = API.version, addonVersion = GF.version,
        uniqueItemIDs = info.items, dungeonCount = info.dungeons, raidCount = info.raids,
        learnedItems = info.learned, scanTime = info.time, scanBuild = info.build, outdated = info.outdated,
        loading = GF.State.loading == true, status = GF.State.status,
        lastRefreshCompleted = API.lastRefreshCompleted,
    }
end

-- ---------- Refresh (the only thing that talks to the server / journal) ----------
local function SetProgress(stage, done, total, text)
    GF.State.progress = { stage = stage, done = done or 0, total = total or 0 }
    if text then GF.State.status = text end
    if GF.UI and GF.UI.Refresh then GF.UI.Refresh() end
end

local function FinishRefresh(message, timedOut)
    if not GF.State.loading then return end
    GF.State.loading = false
    GF.State.progress = nil
    API.pending, API.pendingCount = {}, 0
    API.lastRefreshCompleted = true
    local missing = 0
    for itemID in pairs(API.catalogByID) do
        local cache = API.itemCache[itemID]
        if not (cache and cache.name) then missing = missing + 1 end
    end
    if message then
        GF.State.status = message
    elseif timedOut and missing > 0 then
        GF.State.status = "Refresh finished; " .. missing .. " items did not load from the server yet. Press Refresh again later."
    else
        GF.State.status = "Refreshed from the live client at " .. ((date and date("%H:%M:%S")) or "now")
    end
    API.RecalculateCached()
    if GF.UI and GF.UI.Refresh then GF.UI.Refresh() end
end

local function StartItemPass()
    API.pending, API.pendingCount = {}, 0
    local queue, total = {}, 0
    for itemID in pairs(API.catalogByID) do
        total = total + 1
        if NeedsItemPass(itemID) then
            if ProcessItem(itemID) then
                -- already in the client cache
            else
                API.pending[itemID] = true
                API.pendingCount = API.pendingCount + 1
                queue[#queue + 1] = itemID
            end
        end
    end
    API.itemTotal = total
    if API.pendingCount == 0 then FinishRefresh(); return end

    local generation = (API.refreshGeneration or 0) + 1
    API.refreshGeneration = generation
    local cursor = 1
    local function RequestNextBatch()
        if not GF.State.loading or generation ~= API.refreshGeneration then return end
        local last = math.min(cursor + 39, #queue)
        for i = cursor, last do pcall(GF.Compat.RequestLoadItemData, queue[i]) end
        cursor = last + 1
        SetProgress("items", total - API.pendingCount, total, "Requesting item data from the server…")
        if cursor <= #queue and C_Timer and C_Timer.After then
            C_Timer.After(0.08, RequestNextBatch)
        elseif C_Timer and C_Timer.After then
            -- one-shot safety net, not a polling loop
            C_Timer.After(30, function() if generation == API.refreshGeneration then FinishRefresh(nil, true) end end)
        else
            FinishRefresh(nil, true)
        end
    end
    RequestNextBatch()
end

function API.Refresh()
    if GF.State.loading then return false, "Refresh already in progress" end
    GF.State.loading = true
    API.refreshGeneration = (API.refreshGeneration or 0) + 1
    SetProgress("journal", 0, 0, "Reading dungeons and raids from the Encounter Journal…")
    GF.Catalog.Scan(function(done, total, name)
        SetProgress("journal", done, total, "Reading the Encounter Journal: " .. tostring(name))
    end, function(ok, message)
        if not ok then FinishRefresh(message); return end
        SetProgress("items", 0, 0, "Journal read (" .. tostring(message) .. "). Loading item data…")
        StartItemPass()
    end)
    return true
end

function API.OnItemInfoReceived(itemID, success)
    itemID = tonumber(itemID)
    if not GF.State.loading or not itemID or not API.pending[itemID] then return end
    API.pending[itemID] = nil
    API.pendingCount = math.max(0, API.pendingCount - 1)
    if success ~= false then ProcessItem(itemID) end
    if API.pendingCount <= 0 then
        FinishRefresh()
    elseif API.itemTotal and API.pendingCount % 25 == 0 then
        SetProgress("items", API.itemTotal - API.pendingCount, API.itemTotal)
    end
end

-- ---------- Recommendations ----------
local function EquippedScore(slot, profile)
    local scores = {}
    for _, link in ipairs(GF.Character.GetEquippedLinks(slot)) do
        local score = GF.BiSScoring.ScoreLink(link, profile)
        if score then scores[#scores + 1] = score end
    end
    if #scores == 0 then return nil end
    -- A new ring/trinket only needs to beat the weaker of the two equipped items.
    if slot == "Finger" or slot == "Trinket" then
        local weakest = scores[1]
        for i = 2, #scores do if scores[i] < weakest then weakest = scores[i] end end
        return weakest
    end
    return scores[1]
end

-- Faction-only sources ("(Horde Quest)", "Alliance Only Quest", ...) are matched against the player's faction.
local playerFaction
function API.RecordFaction(record)
    local text = (tostring(record.boss or "") .. " " .. tostring(record.instanceName or "")):lower()
    local horde, alliance = text:find("horde") ~= nil, text:find("alliance") ~= nil
    if horde and not alliance then return "Horde" end
    if alliance and not horde then return "Alliance" end
end

-- Instances that are not in WoW Forever yet (classic raids without an announced date).
function API.IsInstanceUnavailable(instanceKey, name)
    local inst = API.instances and API.instances[instanceKey]
    local meta = GF.Data.GetInstanceMeta((inst and inst.name) or name or instanceKey)
    return meta and meta.unavailable == true or false
end

local function SourceAllowed(record, filter, loot, instanceKey)
    if API.IsInstanceUnavailable(record.instance, record.instanceName) then return false end
    local faction = API.RecordFaction(record)
    if faction and playerFaction and faction ~= playerFaction then return false end
    if instanceKey and record.instance ~= instanceKey then return false end
    if loot ~= "all" and API.RecordKind(record) ~= loot then return false end
    if filter == "dungeon" then return not record.isRaid end
    if filter == "raid" then return record.isRaid == true end
    return true
end

function API.RecalculateCached()
    local profile = GF.Specializations.GetProfile()
    local recommendations, eligible, rejected = {}, 0, 0
    local filter, ahead = API.GetSourceFilter(), API.GetLevelAhead()
    local lootFilter, instanceFilter = API.GetLootFilter(), API.GetInstanceFilter()
    playerFaction = UnitFactionGroup and UnitFactionGroup("player") or nil
    if playerFaction ~= "Horde" and playerFaction ~= "Alliance" then playerFaction = nil end
    local maxRequired = (tonumber(profile.level) or 1) + ahead
    profile.maxRequiredLevel = maxRequired
    local equippedBySlot = {}
    for _, slot in ipairs(GF.ItemFilter.SlotOrder) do recommendations[slot] = {} end
    local now = time and time() or 0

    for itemID, sourceRecords in pairs(API.catalogByID) do
        local usable = {}
        for _, record in ipairs(sourceRecords) do
            if SourceAllowed(record, filter, lootFilter, instanceFilter) then usable[#usable + 1] = record end
        end
        local record = usable[1]
        local cache = API.itemCache[itemID]
        if not record or not cache or not cache.name then
            rejected = rejected + 1
        else
            local item = MergeItemData(record)
            -- Quest rewards often carry no "Requires Level" line (they read as level 0/1); the quest itself
            -- needs about item level - 5, so estimate from the item level for anything clearly above that.
            if (item.requiredLevel or 0) <= 1 and (tonumber(item.itemLevel) or 0) >= 15 then
                item.requiredLevel = math.min(60, item.itemLevel - 5)
                item.levelEstimated = true
            end
            if item.requiredLevel > maxRequired then
                rejected = rejected + 1
            else
                local slot = item.slot
                local targetSlots = {}
                if slot then targetSlots[1] = slot end
                if slot == "Main Hand" and item.equipLoc == "INVTYPE_WEAPON"
                    and GF.ItemFilter.CanDualWield and GF.ItemFilter.CanDualWield(profile) then
                    targetSlots[#targetSlots + 1] = "Off Hand"
                end
                local score, breakdown, specProfile, confidence, hasUsefulStats = GF.BiSScoring.Score(item, profile)
                if hasUsefulStats then
                    -- Every source (filtered) with its tags, so the UI can show NEW / raid size / lock.
                    local sources, infos, instanceKeys = {}, {}, {}
                    local locked, isNew, isRaid = false, false, false
                    for _, rec in ipairs(usable) do
                        sources[#sources + 1] = SourceText(rec)
                        instanceKeys[#instanceKeys + 1] = rec.instance
                        local inst = API.instances[rec.instance] or {}
                        local isLocked = inst.unlock and now < inst.unlock or false
                        infos[#infos + 1] = { isRaid = rec.isRaid == true, size = inst.size, new = inst.new == true, locked = isLocked }
                        if inst.new then isNew = true end
                        if rec.isRaid then isRaid = true end
                        if isLocked then locked = true end
                    end
                    for _, targetSlot in ipairs(targetSlots) do
                        local candidate = CopyTable(item)
                        candidate.slot = targetSlot
                        if GF.ItemFilter.CanUse(candidate, profile) and recommendations[targetSlot] then
                            candidate.score, candidate.breakdown, candidate.specProfile, candidate.confidence = score, breakdown, specProfile, confidence
                            candidate.sources = sources
                            candidate.sourceInfo = infos
                            candidate.instanceKeys = instanceKeys
                            candidate.isNew, candidate.isRaid, candidate.locked = isNew, isRaid, locked
                            candidate.armorRank = GF.ItemFilter.ArmorRank(candidate, profile) or 0
                            if equippedBySlot[targetSlot] == nil then equippedBySlot[targetSlot] = EquippedScore(targetSlot, profile) or false end
                            local equipped = equippedBySlot[targetSlot] or nil
                            candidate.equippedScore = equipped
                            candidate.delta = equipped and (score - equipped) or nil
                            candidate.upgrade = (not equipped) or (score > equipped + 0.01)
                            table.insert(recommendations[targetSlot], candidate)
                            eligible = eligible + 1
                        else
                            rejected = rejected + 1
                        end
                    end
                else
                    rejected = rejected + 1
                end
            end
        end
    end

    local totalUpgrades, instanceCounts = 0, {}
    for slot, list in pairs(recommendations) do
        -- Keep the lower armor type (e.g. mail for a Paladin) only when no best-type item exists for the slot.
        local hasBest = false
        for _, candidate in ipairs(list) do if (candidate.armorRank or 0) == 0 then hasBest = true break end end
        if hasBest then
            local kept = {}
            for _, candidate in ipairs(list) do if (candidate.armorRank or 0) == 0 then kept[#kept + 1] = candidate end end
            list = kept
            recommendations[slot] = kept
        end
        table.sort(list, function(a, b)
            if a.score == b.score then
                if (a.itemLevel or 0) == (b.itemLevel or 0) then return tostring(a.name or a.id) < tostring(b.name or b.id) end
                return (a.itemLevel or 0) > (b.itemLevel or 0)
            end
            return a.score > b.score
        end)
        local upgrades = {}
        for _, candidate in ipairs(list) do if candidate.upgrade then upgrades[#upgrades + 1] = candidate end end
        recommendations[slot] = upgrades
        local best = upgrades[1]
        if best then
            totalUpgrades = totalUpgrades + 1
            instanceCounts[best.dungeonName] = (instanceCounts[best.dungeonName] or 0) + 1
        end
    end
    local bestInstance, bestCount = nil, 0
    for name, count in pairs(instanceCounts) do
        if count > bestCount then bestInstance, bestCount = name, count end
    end
    API.recommendations = recommendations
    GF.State.profile = profile
    GF.State.totalUpgrades = totalUpgrades
    GF.State.eligibleItemCount = eligible
    GF.State.filteredItemCount = rejected
    GF.State.bestDungeon = bestInstance
    GF.State.dungeonCounts = instanceCounts
    return recommendations
end

function API.GetRecommendations() return API.recommendations or {} end

-- Upgrade picks one instance offers for the current build: one entry per slot (its best item from
-- that instance), ranked by score gain. Used by the world-map pins.
function API.GetInstanceUpgrades(instanceKey)
    local out = {}
    for slot, list in pairs(API.recommendations or {}) do
        for _, candidate in ipairs(list) do
            local hit = false
            for _, key in ipairs(candidate.instanceKeys or {}) do if key == instanceKey then hit = true break end end
            if hit then out[#out + 1] = { slot = slot, item = candidate }; break end
        end
    end
    table.sort(out, function(a, b) return (a.item.delta or 1e9) > (b.item.delta or 1e9) end)
    return out
end
function API.GetBuild() return GF.Specializations.GetProfile() end

function API.SetSpecOverride(index)
    local profile = GF.Specializations.GetProfile()
    local names = GF.SpecNames[profile.class] or {}
    if index == nil then
        CharDB().specOverride = nil
    elseif tonumber(index) and tonumber(index) >= 1 and tonumber(index) <= #names then
        CharDB().specOverride = tonumber(index)
    else
        return false
    end
    API.RecalculateCached()
    if GF.UI and GF.UI.Refresh then GF.UI.Refresh() end
    return true
end
