-- Reads dungeon/raid loot from an installed AtlasLoot (Classic / Classic Forever) at Refresh time.
-- Nothing is copied into Gearfinder: the data is read from the other addon in memory, so it is always as
-- current as that addon. Used when the game's own Encounter Journal is empty (as in WoW Forever).
-- The reader is deliberately tolerant about AtlasLoot's table layout:
--   instance = a table with an `items` list and a name; boss = an entry of `items` with a name and
--   one or more item lists whose rows look like { slot, itemID, ... }.
local GF = Gearfinder
GF.AtlasLoot = GF.AtlasLoot or {}
local AL = GF.AtlasLoot

local function Str(value)
    if type(value) == "string" then return value end
    if type(value) == "function" then
        local ok, result = pcall(value)
        if ok and type(result) == "string" then return result end
    end
end

-- ---------- name cleaning ----------
-- AtlasLoot embeds colour codes and icon escapes in names ("|cffffffff|TInterface\\...|t|r") and uses
-- CamelCase keys for some instances. These helpers return plain, readable names.
function AL.CleanText(text)
    text = tostring(text or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|H.-|h", ""):gsub("|h", "")
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local PRETTY = {
    blackrockdepths = "Blackrock Depths", moltencore = "Molten Core", blackwinglair = "Blackwing Lair",
    onyxia = "Onyxia's Lair", onyxiaslair = "Onyxia's Lair", naxxramas = "Naxxramas",
    theruinsofahnqiraj = "Ruins of Ahn'Qiraj", ruinsofahnqiraj = "Ruins of Ahn'Qiraj",
    thetempleofahnqiraj = "Temple of Ahn'Qiraj", templeofahnqiraj = "Temple of Ahn'Qiraj",
    ["thetempleofatal'hakkar"] = "Temple of Atal'Hakkar", ["templeofatal'hakkar"] = "Temple of Atal'Hakkar",
    razorfendowns = "Razorfen Downs", ["zul'gurub"] = "Zul'Gurub", worldbosses = "World Bosses",
}
local RAIDS = { ["molten core"] = true, ["blackwing lair"] = true, ["onyxia's lair"] = true, ["naxxramas"] = true,
    ["ruins of ahn'qiraj"] = true, ["temple of ahn'qiraj"] = true, ["zul'gurub"] = true, ["world bosses"] = true,
    ["barrow deeps"] = true, ["hyjal summit"] = true }

function AL.PrettyInstance(raw)
    local clean = AL.CleanText(raw)
    local squashed = clean:lower():gsub("%s+", "")
    local name = PRETTY[squashed] or clean
    return name, RAIDS[name:lower()] == true
end

local NOT_A_BOSS = { "^trash", "^keys?$", "^all bosses$", "sets$", "^plans$", "^class books$", "^ahn'qiraj scarabs$",
    "^ahn'qiraj enchants$", "^aq opening$", "^tier %d" }
function AL.CleanBoss(raw)
    local name = AL.CleanText(raw)
    local lower = name:lower()
    for _, pattern in ipairs(NOT_A_BOSS) do
        if lower:find(pattern) then return "Trash / other drops" end
    end
    return name
end

local function Canon(name) return GF.Data.CanonicalName and GF.Data.CanonicalName(name) or tostring(name):lower() end

function AL.ModuleNames()
    local names = {}
    local getNum = (C_AddOns and C_AddOns.GetNumAddOns) or _G.GetNumAddOns
    local getInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or _G.GetAddOnInfo
    if not (getNum and getInfo) then return names end
    for i = 1, getNum() do
        local ok, a = pcall(getInfo, i)
        local name = ok and (type(a) == "table" and a.name or a) or nil
        if type(name) == "string" and name:lower():find("^atlasloot") then names[#names + 1] = name end
    end
    return names
end

function AL.Load()
    local loader = (C_AddOns and C_AddOns.LoadAddOn) or _G.LoadAddOn
    if not loader then return end
    for _, name in ipairs(AL.ModuleNames()) do pcall(loader, name) end
end

local function Roots()
    local roots = {}
    local atlas = _G.AtlasLoot
    if type(atlas) ~= "table" then return roots end
    -- Only the dungeons-and-raids module: crafting, factions, sets, world drops etc. are not instances.
    local storage = type(atlas.ItemDB) == "table" and atlas.ItemDB.Storage
    if type(storage) == "table" then
        for key, module in pairs(storage) do
            local k = tostring(key):lower()
            if type(module) == "table" and (k:find("dungeon") or k:find("raid") or k:find("instance")) then roots[#roots + 1] = module end
        end
    end
    if #roots == 0 and type(storage) == "table" then
        for _, module in pairs(storage) do if type(module) == "table" then roots[#roots + 1] = module end end
    end
    return roots
end

local function LooksLikeItemRow(row)
    return type(row) == "table" and type(row[1]) == "number" and type(row[2]) == "number" and row[2] > 0
end

local function BossRows(boss)
    local out, seen = {}, {}
    for key, list in pairs(boss) do
        if key ~= "name" and type(list) == "table" then
            for _, row in ipairs(list) do
                if LooksLikeItemRow(row) and not seen[row[2]] then seen[row[2]] = true; out[#out + 1] = row[2] end
            end
        end
    end
    return out
end

local function ReadInstance(tbl, fallbackName, items, meta, isRaidFlag)
    local rawName = Str(tbl.name) or Str(tbl.Name) or (type(tbl.GetName) == "function" and Str(tbl.GetName)) or fallbackName
    if not rawName then return 0 end
    local name, prettyRaid = AL.PrettyInstance(rawName)
    isRaidFlag = isRaidFlag or prettyRaid
    local key = "al:" .. Canon(name)
    local hint = GF.Data.GetInstanceMeta(name) or {}
    local bosses, count = {}, 0
    for index, boss in ipairs(tbl.items) do
        if type(boss) == "table" then
            local bossName = AL.CleanBoss(Str(boss.name) or ("Boss " .. index))
            local ids = BossRows(boss)
            if #ids > 0 then
                local listed = false
                for _, b in ipairs(bosses) do if b == bossName then listed = true break end end
                if not listed and bossName ~= "Trash / other drops" then bosses[#bosses + 1] = bossName end
                for _, itemID in ipairs(ids) do
                    local list = items[itemID]
                    if not list then list = {}; items[itemID] = list end
                    local dup = false
                    for _, src in ipairs(list) do if src.inst == key and src.boss == bossName then dup = true break end end
                    if not dup then list[#list + 1] = { inst = key, boss = bossName }; count = count + 1 end
                end
            end
        end
    end
    if count == 0 then return 0 end
    if not meta[key] then
        meta[key] = { id = key, name = name, isRaid = (isRaidFlag or hint.raid) and true or false, bosses = bosses,
            size = hint.size, new = hint.new, min = hint.min, max = hint.max, unlock = hint.unlock, fromAtlasLoot = true }
    else
        for _, b in ipairs(bosses) do meta[key].bosses[#meta[key].bosses + 1] = b end
    end
    return count
end

-- Returns items, meta, instanceCount (or nil when AtlasLoot isn't there / has no readable data).
function AL.Import()
    AL.Load()
    local roots = Roots()
    if #roots == 0 then return nil, nil, 0, "AtlasLoot is not installed or has no data tables." end
    local items, meta, seen, instances = {}, {}, {}, 0
    local function Visit(tbl, key, depth)
        if depth > 7 or seen[tbl] then return end
        seen[tbl] = true
        if type(tbl.items) == "table" and (tbl.name or tbl.Name or tbl.MapID or tbl.ContentType or tbl.GetName) then
            local raidFlag = tostring(tbl.ContentType or ""):lower():find("raid") ~= nil
            if ReadInstance(tbl, type(key) == "string" and key or nil, items, meta, raidFlag) > 0 then instances = instances + 1 end
            return
        end
        local ok = pcall(function()
            for k, v in pairs(tbl) do
                if type(v) == "table" and k ~= "__index" then Visit(v, k, depth + 1) end
            end
        end)
        return ok
    end
    for _, root in ipairs(roots) do Visit(root, nil, 0) end
    if instances == 0 then return nil, nil, 0, "AtlasLoot is loaded, but no readable loot tables were found." end
    return items, meta, instances
end
