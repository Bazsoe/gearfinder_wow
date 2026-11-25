-- Static, hand-maintained hints about WoW Forever (1.60.1) instances. This is NOT the loot database:
-- the loot always comes live from the game's Encounter Journal when you press Refresh. These hints only
-- add labels (NEW, raid size, level range, unlock date) to instances the journal reports by name.
-- Sources: Warcraft Wiki "World of Warcraft: Forever" and Blizzard's Forever roadmap (Oct/Nov 2026).
local GF = Gearfinder
GF.Data = GF.Data or {}

-- Dec 9 2026, 00:00 UTC: the roadmap date when Barrow Deeps, Hyjal Summit and Onyxia's Lair open.
local RAID_UNLOCK = 1796774400

local D = {
    -- New Forever dungeons
    ["hall of thanes"]          = { min = 13, max = 18, new = true },
    ["ruins of lordaeron"]      = { min = 15, max = 22, new = true },
    ["excavation site wetlands"] = { min = 24, max = 29, new = true },
    ["city of dalaran"]         = { min = 28, max = 33, new = true },
    ["drowned city"]            = { min = 35, max = 40, new = true },
    ["krol'dok stronghold"]     = { min = 40, max = 45, new = true, size = 10 },
    ["alcaz prison"]            = { min = 48, max = 53, new = true },
    ["blackmaw hold"]           = { min = 55, max = 60, new = true },
    ["shaper's terrace"]        = { min = 58, max = 60, new = true },
    -- Classic dungeons (ranges from the Forever wiki list)
    ["ragefire chasm"]          = { min = 13, max = 19 },
    ["deadmines"]               = { min = 18, max = 24 },
    ["wailing caverns"]         = { min = 19, max = 25 },
    ["shadowfang keep"]         = { min = 23, max = 29 },
    ["uldaman"]                 = { min = 44, max = 50 },
    ["zul'farrak"]              = { min = 45, max = 51 },
    ["maraudon"]                = { min = 48, max = 54 },
    ["temple of atal'hakkar"]   = { min = 52, max = 58 },
    ["blackrock depths"]        = { min = 52, max = 60 },
    ["warpwood quarter"]        = { min = 55, max = 60 },
    ["lower blackrock spire"]   = { min = 55, max = 60 },
    ["capital gardens"]         = { min = 58, max = 60 },
    ["scholomance"]             = { min = 58, max = 60 },
    -- New Forever raids
    ["barrow deeps"]            = { raid = true, size = 10, new = true, unlock = RAID_UNLOCK },
    ["hyjal summit"]            = { raid = true, size = 20, new = true, unlock = RAID_UNLOCK },
    -- Classic raids. Only Onyxia's Lair opens on Dec 9; Blizzard has given no Forever date for the others
    -- (checked 25 Nov 2026), so their loot is left out ("unavailable") until they are announced.
    ["onyxia's lair"]           = { raid = true, size = 40, unlock = RAID_UNLOCK },
    ["molten core"]             = { raid = true, size = 40, unavailable = true },
    ["blackwing lair"]          = { raid = true, size = 40, unavailable = true },
    ["zul'gurub"]               = { raid = true, size = 20, unavailable = true },
    ["ruins of ahn'qiraj"]      = { raid = true, size = 20, unavailable = true },
    ["temple of ahn'qiraj"]     = { raid = true, size = 40, unavailable = true },
    ["ahn'qiraj temple"]        = { raid = true, size = 40, unavailable = true },
    ["naxxramas"]               = { raid = true, size = 40, unavailable = true },
}
-- Alternative spellings the client or community use for the same place.
local ALIAS = {
    ["the hall of thanes"] = "hall of thanes",
    ["excavation site"] = "excavation site wetlands",
    ["the drowned city"] = "drowned city",
    ["krol'dor stronghold"] = "krol'dok stronghold",
    ["alcaz island prison"] = "alcaz prison",
    ["the deadmines"] = "deadmines",
    ["sunken temple"] = "temple of atal'hakkar",
    ["the temple of atal'hakkar"] = "temple of atal'hakkar",
    ["dire maul east"] = "warpwood quarter",
    ["dire maul west"] = "capital gardens",
}

local function Normalize(name)
    local n = tostring(name or ""):lower()
    n = n:gsub("\226\128\153", "'"):gsub("[:%-]", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return n
end

GF.Data.RaidUnlockTime = RAID_UNLOCK

-- Canonical lower-case key for an instance name (aliases resolved), used to match the same place
-- coming from the journal, the map API, the built-in table and your own entrances.
function GF.Data.CanonicalName(name)
    local n = Normalize(name)
    if ALIAS[n] then n = ALIAS[n] end
    local noThe = n:gsub("^the ", "")
    if D[noThe] or ALIAS[noThe] then n = ALIAS[noThe] or noThe end
    return n
end

function GF.Data.GetInstanceMeta(name)
    local n = Normalize(name)
    if ALIAS[n] then n = ALIAS[n] end
    if D[n] then return D[n] end
    local noThe = n:gsub("^the ", "")
    return D[noThe] or D[ALIAS[noThe] or ""]
end
