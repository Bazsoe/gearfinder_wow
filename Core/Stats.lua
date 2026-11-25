-- Gearfinder stat normalisation for WoW Forever.
-- Forever merges spell/melee/ranged Hit into one stat and does the same for Crit, and bonus healing
-- also grants 1/3 bonus damage. Item stats are read from the live client (C_Item.GetItemStats) and,
-- for effects that the stat API does not expose ("Equip: Increases healing done ... by up to 42"),
-- from the item tooltip. Everything is converted to ONE canonical key set so the scoring weights are
-- independent of how the client spells a stat.
local GF = Gearfinder
GF.Stats = GF.Stats or {}
local Stats = GF.Stats

Stats.Labels = {
    STR = "Strength", AGI = "Agility", STA = "Stamina", INT = "Intellect", SPI = "Spirit",
    ARMOR = "Armor", AP = "Attack Power", RAP = "Ranged Attack Power",
    SP = "Spell Damage", HEAL = "Bonus Healing", HIT = "Hit", CRIT = "Critical Strike",
    HASTE = "Haste", EXP = "Expertise", ARP = "Armor Penetration", MP5 = "Mana per 5 sec",
    DEF = "Defense", DODGE = "Dodge", PARRY = "Parry", BLOCK = "Block", BLOCKVAL = "Block Value",
    WSKILL = "Weapon Skill", DPS = "Weapon DPS",
}

-- Rating-equivalent units. At level 60 the game files list 10 rating per 1% hit and 14 per 1% crit
-- (same for melee, ranged and spells). Percent values found in tooltips are converted to the same unit.
local PCT_TO_RATING = { HIT = 10, CRIT = 14, HASTE = 10, DODGE = 12, PARRY = 15, BLOCK = 5 }

-- Ordered: the first matching rule wins (longer / more specific names first).
local KEY_RULES = {
    { "RANGED_ATTACK_POWER", "RAP" }, { "ARMOR_PENETRATION", "ARP" }, { "ATTACK_POWER", "AP" },
    { "SPELL_HEALING_DONE", "HEAL" }, { "HEALING", "HEAL" },
    { "SPELL_DAMAGE_DONE", "SP" }, { "SPELL_POWER", "SP" },
    { "STRENGTH", "STR" }, { "AGILITY", "AGI" }, { "STAMINA", "STA" }, { "INTELLECT", "INT" }, { "SPIRIT", "SPI" },
    { "HIT", "HIT" }, { "CRIT", "CRIT" }, { "HASTE", "HASTE" }, { "EXPERTISE", "EXP" },
    { "MANA_REGENERATION", "MP5" }, { "DEFENSE", "DEF" }, { "DODGE", "DODGE" }, { "PARRY", "PARRY" },
    { "BLOCK_VALUE", "BLOCKVAL" }, { "BLOCK", "BLOCK" },
    { "DAMAGE_PER_SECOND", "DPS" }, { "WEAPON_SKILL", "WSKILL" },
    { "RESISTANCE0_NAME", "ARMOR" }, { "ARMOR", "ARMOR" },
}

local function Add(out, key, amount)
    amount = tonumber(amount)
    if key and amount and amount ~= 0 then out[key] = (out[key] or 0) + amount end
end

function Stats.CanonicalKey(rawKey)
    local upper = tostring(rawKey):upper()
    for _, rule in ipairs(KEY_RULES) do
        if upper:find(rule[1], 1, true) then return rule[2], upper end
    end
    return nil, upper
end

-- Converts the table returned by C_Item.GetItemStats into canonical stats.
function Stats.Normalize(raw)
    local out = {}
    if type(raw) ~= "table" then return out end
    for rawKey, amount in pairs(raw) do
        local key, upper = Stats.CanonicalKey(rawKey)
        if key then
            local value = tonumber(amount) or 0
            -- A few clients report chance stats as percentages instead of ratings.
            if PCT_TO_RATING[key] and (upper:find("PERCENT", 1, true) or upper:find("CHANCE", 1, true)) and not upper:find("RATING", 1, true) then
                value = value * PCT_TO_RATING[key]
            end
            -- Several keys can map to one canonical stat (melee/ranged/spell hit); never double count
            -- the same item: keep the largest value instead of the sum for the merged stats.
            if key == "HIT" or key == "CRIT" or key == "HASTE" then
                if value > (out[key] or 0) then out[key] = value end
            else
                Add(out, key, value)
            end
        end
    end
    return out
end

-- ---------- Tooltip scanning ----------
local scanTip
local function GetScanTip()
    if scanTip == nil then
        local ok, tip = pcall(CreateFrame, "GameTooltip", "GearfinderScanTooltip", UIParent, "GameTooltipTemplate")
        scanTip = ok and tip or false
    end
    return scanTip or nil
end

-- Returns the left-hand text lines of an item tooltip (local data only, no server request).
function Stats.ReadTooltipLines(link)
    local lines = {}
    if not link then return lines end
    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
        if ok and type(data) == "table" and type(data.lines) == "table" then
            for _, line in ipairs(data.lines) do
                if type(line.leftText) == "string" then lines[#lines + 1] = line.leftText end
            end
            if #lines > 0 then return lines end
        end
    end
    local tip = GetScanTip()
    if not tip then return lines end
    pcall(tip.SetOwner, tip, UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    if not pcall(tip.SetHyperlink, tip, link) then tip:Hide(); return lines end
    for i = 1, (tip:NumLines() or 0) do
        local fs = _G["GearfinderScanTooltipTextLeft" .. i]
        local text = fs and fs:GetText()
        if type(text) == "string" then lines[#lines + 1] = text end
    end
    tip:Hide()
    return lines
end

-- English tooltip patterns for effects that the stat API does not report. A stat that the API
-- already returned is never overwritten, so a localized client simply falls back to the API values.
function Stats.ParseLines(lines, stats)
    stats = stats or {}
    local restriction, reqLevel
    local template = type(_G.ITEM_CLASSES_ALLOWED) == "string" and _G.ITEM_CLASSES_ALLOWED or "Classes: %s"
    local prefix = (template:match("^(.-)%%s") or "Classes: "):lower()
    for _, original in ipairs(lines) do
        local line = original:lower():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        if prefix ~= "" and line:sub(1, #prefix) == prefix then restriction = line:sub(#prefix + 1) end
        local n
        if not reqLevel then
            n = line:match("^requires level (%d+)") or line:match("^requires lvl (%d+)")
            if n then reqLevel = tonumber(n) end
        end
        if not stats.HEAL then
            n = line:match("healing done by spells and effects by up to (%d+)") or line:match("(%d+) bonus healing")
            if n then Add(stats, "HEAL", n) end
        end
        if not stats.SP then
            n = line:match("damage done by spells and effects by up to (%d+)") or line:match("(%d+) bonus damage")
                or line:match("(%d+) spell damage")
            if n then Add(stats, "SP", n) end
            n = line:match("damage and healing done by magical spells and effects by up to (%d+)")
            if n then Add(stats, "SP", n); if not stats.HEAL then Add(stats, "HEAL", n) end end
        end
        if not stats.AP then
            n = line:match("increases attack power by (%d+)") or line:match("%+(%d+) attack power")
            if n and not line:find("ranged", 1, true) then Add(stats, "AP", n) end
        end
        if not stats.RAP then
            n = line:match("ranged attack power by (%d+)") or line:match("%+(%d+) ranged attack power")
            if n then Add(stats, "RAP", n) end
        end
        if not stats.MP5 then
            n = line:match("restores (%d+) mana per 5") or line:match("(%d+) mana per 5 sec")
            if n then Add(stats, "MP5", n) end
        end
        if not stats.HIT then
            n = line:match("hit rating by (%d+)")
            if n then Add(stats, "HIT", n) else
                n = line:match("chance to hit by (%d+)%%") or line:match("hit chance by (%d+)%%")
                if n then Add(stats, "HIT", tonumber(n) * PCT_TO_RATING.HIT) end
            end
        end
        if not stats.CRIT then
            n = line:match("critical strike rating by (%d+)")
            if n then Add(stats, "CRIT", n) else
                n = line:match("critical strike by (%d+)%%") or line:match("critical strike chance by (%d+)%%")
                if n then Add(stats, "CRIT", tonumber(n) * PCT_TO_RATING.CRIT) end
            end
        end
        if not stats.DEF then
            n = line:match("increased defense %+(%d+)") or line:match("defense rating by (%d+)") or line:match("defense by (%d+)")
            if n then Add(stats, "DEF", n) end
        end
        if not stats.DODGE then
            n = line:match("dodge an attack by (%d+)%%") or line:match("dodge chance by (%d+)%%")
            if n then Add(stats, "DODGE", tonumber(n) * PCT_TO_RATING.DODGE) end
        end
        if not stats.PARRY then
            n = line:match("parry an attack by (%d+)%%") or line:match("parry chance by (%d+)%%")
            if n then Add(stats, "PARRY", tonumber(n) * PCT_TO_RATING.PARRY) end
        end
        if not stats.EXP then
            n = line:match("expertise by (%d+)") or line:match("(%d+) expertise")
            if n then Add(stats, "EXP", n) end
        end
        if not stats.WSKILL then
            n = line:match("skill with .- by (%d+)") or line:match("weapon skill by (%d+)")
            if n then Add(stats, "WSKILL", n) end
        end
    end
    return stats, restriction, reqLevel
end

-- Full stat read for one item link: API stats first, tooltip effects as a supplement.
function Stats.FromLink(link)
    local stats = {}
    if GF.Compat.HasItemStats() then
        local ok, raw = pcall(GF.Compat.GetItemStats, link)
        if ok then stats = Stats.Normalize(raw) end
    end
    local lines = Stats.ReadTooltipLines(link)
    local restriction, reqLevel
    stats, restriction, reqLevel = Stats.ParseLines(lines, stats)
    return stats, restriction, reqLevel
end
