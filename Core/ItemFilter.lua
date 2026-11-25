local GF = Gearfinder
GF.ItemFilter = {}
GF.ItemFilter.SlotOrder = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet",
    "Finger", "Trinket", "Main Hand", "Off Hand", "Two-Hand", "Ranged", "Relic",
}

local WEAPONS = {
    WARRIOR = { [0]=true,[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[10]=true,[13]=true,[15]=true,[16]=true,[18]=true },
    PALADIN = { [0]=true,[1]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true },
    HUNTER  = { [0]=true,[1]=true,[2]=true,[3]=true,[6]=true,[7]=true,[8]=true,[10]=true,[13]=true,[15]=true,[18]=true },
    ROGUE   = { [2]=true,[3]=true,[4]=true,[7]=true,[13]=true,[15]=true,[16]=true,[18]=true },
    PRIEST  = { [4]=true,[10]=true,[15]=true,[19]=true },
    SHAMAN  = { [0]=true,[1]=true,[4]=true,[5]=true,[10]=true,[13]=true,[15]=true },
    MAGE    = { [7]=true,[10]=true,[15]=true,[19]=true },
    WARLOCK = { [7]=true,[10]=true,[15]=true,[19]=true },
    DRUID   = { [4]=true,[5]=true,[6]=true,[10]=true,[13]=true,[15]=true },
}
GF.ItemFilter.ClassWeapons = WEAPONS

local ENGLISH_CLASS_NAMES = {
    WARRIOR="warrior", PALADIN="paladin", HUNTER="hunter", ROGUE="rogue", PRIEST="priest",
    SHAMAN="shaman", MAGE="mage", WARLOCK="warlock", DRUID="druid",
}

-- True/false when the item tooltip carried a "Classes: ..." line (stored lower-case at scan time).
function GF.ItemFilter.ClassAllowed(item, profile)
    local text = item.classRestriction
    if type(text) ~= "string" or text == "" then return true end
    local names = { ENGLISH_CLASS_NAMES[profile.class] }
    if profile.className then names[#names + 1] = tostring(profile.className):lower() end
    for _, namesTable in ipairs({ _G.LOCALIZED_CLASS_NAMES_MALE or {}, _G.LOCALIZED_CLASS_NAMES_FEMALE or {} }) do
        if namesTable[profile.class] then names[#names + 1] = tostring(namesTable[profile.class]):lower() end
    end
    for _, name in ipairs(names) do
        if name ~= "" and text:find(name, 1, true) then return true end
    end
    return false
end

local function HasClass(list, class)
    if not list then return true end
    for _, value in ipairs(list) do if value == class then return true end end
    return false
end

local function HasShamanDualWieldTalent()
    local names = { "dual wield", "dual-wield", "doppelschlag", "ambidextrie", "beidhändigkeit", "dupla empunhadura", "doble empuñadura" }
    local rank = GF.Compat.FindTalentRank(2, names)
    return (tonumber(rank) or 0) > 0
end

local function CanDualWield(profile)
    local class, level = profile.class, profile.level or 1
    if class == "ROGUE" then return level >= 10 end
    if class == "WARRIOR" or class == "HUNTER" then return level >= 20 end
    if class == "SHAMAN" then
        return profile.specIndex == 2 and level >= 40 and HasShamanDualWieldTalent()
    end
    return false
end
GF.ItemFilter.CanDualWield = CanDualWield

function GF.ItemFilter.GetSlot(item)
    if item.slot then return item.slot end
    local map = {
        INVTYPE_HEAD="Head", INVTYPE_NECK="Neck", INVTYPE_SHOULDER="Shoulder", INVTYPE_CLOAK="Back",
        INVTYPE_CHEST="Chest", INVTYPE_ROBE="Chest", INVTYPE_WRIST="Wrist", INVTYPE_HAND="Hands",
        INVTYPE_WAIST="Waist", INVTYPE_LEGS="Legs", INVTYPE_FEET="Feet", INVTYPE_FINGER="Finger",
        INVTYPE_TRINKET="Trinket", INVTYPE_WEAPONMAINHAND="Main Hand", INVTYPE_WEAPONOFFHAND="Off Hand",
        INVTYPE_2HWEAPON="Two-Hand", INVTYPE_SHIELD="Off Hand", INVTYPE_HOLDABLE="Off Hand",
        INVTYPE_RANGED="Ranged", INVTYPE_RANGEDRIGHT="Ranged", INVTYPE_THROWN="Ranged", INVTYPE_RELIC="Relic",
    }
    if item.equipLoc == "INVTYPE_WEAPON" then return "Main Hand" end
    return map[item.equipLoc]
end

local function IsWearableArmor(item, profile)
    if item.itemClass ~= 4 then return true end
    local sub = tonumber(item.subclass)
    if not sub or sub == 0 then return true end
    -- Cloaks, rings, trinkets and neck items are not restricted by the primary armor subclass.
    if item.equipLoc == "INVTYPE_CLOAK" or item.equipLoc == "INVTYPE_NECK" or item.equipLoc == "INVTYPE_FINGER" or item.equipLoc == "INVTYPE_TRINKET" then return true end
    if sub == 1 then return true end -- cloth
    if sub == 2 then return profile.class ~= "MAGE" and profile.class ~= "PRIEST" and profile.class ~= "WARLOCK" end
    if sub == 3 then
        if profile.class == "WARRIOR" or profile.class == "PALADIN" then return true end
        return (profile.class == "HUNTER" or profile.class == "SHAMAN") and profile.level >= 40
    end
    if sub == 4 then return (profile.class == "WARRIOR" or profile.class == "PALADIN") and profile.level >= 40 end
    if sub == 6 then return profile.class == "WARRIOR" or profile.class == "PALADIN" or profile.class == "SHAMAN" end -- shield
    if sub == 7 then return profile.class == "PALADIN" end -- libram
    if sub == 8 then return profile.class == "DRUID" end -- idol
    if sub == 9 then return profile.class == "SHAMAN" end -- totem
    return true
end

-- ---------- armor type by class and level ----------
-- Armor subclasses: 1 cloth, 2 leather, 3 mail, 4 plate. A class only ever wants its best type that it can
-- wear at the item's level (rank 0); the next type down (rank 1) is kept only as a fallback for slots where
-- no best-type item exists. Everything else (cloth for a Paladin, leather for a Warrior...) is never shown.
local ARMOR_SLOT_LOCS = { INVTYPE_HEAD = true, INVTYPE_SHOULDER = true, INVTYPE_CHEST = true, INVTYPE_ROBE = true,
    INVTYPE_WRIST = true, INVTYPE_HAND = true, INVTYPE_WAIST = true, INVTYPE_LEGS = true, INVTYPE_FEET = true }
local ARMOR_LINE = {
    WARRIOR = { { 4, 40 }, { 3, 1 } },
    PALADIN = { { 4, 40 }, { 3, 1 } },
    HUNTER  = { { 3, 40 }, { 2, 1 } },
    SHAMAN  = { { 3, 40 }, { 2, 1 } },
    ROGUE   = { { 2, 1 } },
    DRUID   = { { 2, 1 } },
    PRIEST  = { { 1, 1 } },
    MAGE    = { { 1, 1 } },
    WARLOCK = { { 1, 1 } },
}
-- What the character can wear right now. Read from the armor skills the character has learned
-- (Plate Mail 750, Mail 8737, Leather 9077, Cloth 9078); when the client does not answer, the class/level table is used.
local ARMOR_SPELLS = { [4] = 750, [3] = 8737, [2] = 9077, [1] = 9078 }
local ARMOR_NAMES = { [4] = "Plate", [3] = "Mail", [2] = "Leather", [1] = "Cloth" }
local function SpellKnown(id)
    local fn = (C_SpellBook and C_SpellBook.IsSpellKnown) or _G.IsSpellKnown or _G.IsPlayerSpell
    if not fn then return nil end
    local ok, known = pcall(fn, id)
    if ok then return known and true or false end
end

function GF.ItemFilter.WearableArmor(profile)
    local known, detected = {}, false
    for sub, spell in pairs(ARMOR_SPELLS) do
        local value = SpellKnown(spell)
        if value ~= nil then detected = true end
        if value then known[sub] = true end
    end
    local line = ARMOR_LINE[profile.class] or {}
    local fromTable = {}
    for _, entry in ipairs(line) do if (tonumber(profile.level) or 1) >= entry[2] then fromTable[entry[1]] = true end end
    -- Only trust the spell check when it found at least one of the class's own armor types.
    local usable = false
    for _, entry in ipairs(line) do if known[entry[1]] then usable = true end end
    return (detected and usable) and known or fromTable, (detected and usable) and "learned skills" or "class table"
end

function GF.ItemFilter.WearableText(profile)
    local set = GF.ItemFilter.WearableArmor(profile)
    local names = {}
    for sub = 4, 1, -1 do
        -- only list types the class would ever wear as body armor (never cloth for a Paladin)
        local relevant = false
        for _, entry in ipairs(ARMOR_LINE[profile.class] or {}) do if entry[1] == sub then relevant = true end end
        if set[sub] and relevant then names[#names + 1] = ARMOR_NAMES[sub] end
    end
    local text = #names > 0 and table.concat(names, " / ") or "?"
    local line = ARMOR_LINE[profile.class] or {}
    if line[1] and (tonumber(profile.level) or 1) < line[1][2] and line[1][2] > 1 then
        text = text .. "  (" .. ARMOR_NAMES[line[1][1]] .. " from level " .. line[1][2] .. ")"
    end
    return text
end

-- Returns 0 (best type), 1 (fallback type) or nil (never for this class). Items that are not body armor return 0.
function GF.ItemFilter.ArmorRank(item, profile)
    if item.itemClass ~= 4 or not ARMOR_SLOT_LOCS[item.equipLoc or ""] then return 0 end
    local sub = tonumber(item.subclass)
    if not sub or sub < 1 or sub > 4 then return 0 end
    local line = ARMOR_LINE[profile.class]
    if not line then return 0 end
    local at = math.max(tonumber(profile.level) or 1, tonumber(item.requiredLevel) or 0)
    local rank = 0
    if at <= (tonumber(profile.level) or 1) then
        -- item is usable now: go by what the character has actually learned
        local set = GF.ItemFilter.WearableArmor(profile)
        for _, entry in ipairs(line) do
            if set[entry[1]] then
                if entry[1] == sub then return rank end
                rank = rank + 1
            end
        end
        return nil
    end
    for _, entry in ipairs(line) do
        if at >= entry[2] then
            if entry[1] == sub then return rank end
            rank = rank + 1
        end
    end
    return nil
end

-- Spec-dependent weapon layout: a Retribution Paladin wants a two-hander, a Protection/Holy Paladin a one-hander
-- (and shield); a Protection Warrior does not use two-handers.
function GF.ItemFilter.SlotAllowedForSpec(slot, profile)
    local role = profile.role
    if profile.class == "PALADIN" then
        if role == "Melee DPS" then return slot ~= "Main Hand" and slot ~= "Off Hand" end
        return slot ~= "Two-Hand"
    end
    if profile.class == "WARRIOR" and role == "Tank" then return slot ~= "Two-Hand" end
    return true
end

-- ---------- stat fit: does the item's stat line belong to this class and spec? ----------
-- Physical specs (warriors, rogues, hunters, melee/tank paladins, shamans and druids in melee or bear form) never get
-- spell-power / Intellect / Spirit / mana-regen gear; casters and healers never get Strength / Agility / Attack Power /
-- tank gear; damage specs never get pure tank gear (Defense, Block). An item with a mix keeps its slot if the
-- spec's own primary stat is on it.
local CASTER_STATS = { "INT", "SP", "HEAL", "SPI", "MP5" }
local PHYSICAL_STATS = { "STR", "AGI", "AP", "RAP", "ARP", "EXP", "WSKILL" }
local TANK_STATS = { "DEF", "BLOCK", "BLOCKVAL" }
local DEFENSIVE_STATS = { "DODGE", "PARRY" }

local function Has(stats, list)
    for _, key in ipairs(list) do if (tonumber(stats[key]) or 0) > 0 then return true end end
    return false
end

-- Class decides first, spec only refines. Pure casters never want Strength/Agility/Attack Power, even mixed in.
local CLASS_ROLE = { WARRIOR = "Melee DPS", ROGUE = "Melee DPS", HUNTER = "Ranged DPS", PRIEST = "Healer", MAGE = "Caster DPS", WARLOCK = "Caster DPS" }
local PURE_CASTER = { PRIEST = true, MAGE = true, WARLOCK = true }
local PHYSICAL_PRIMARY = { "STR", "AGI", "AP", "RAP" }

-- Returns true, or false plus a short reason.
function GF.ItemFilter.StatsFit(item, profile)
    local stats = item.stats
    if type(stats) ~= "table" or next(stats) == nil then return true end
    local role = profile.role
    if not role or role == "General" then role = CLASS_ROLE[profile.class] or "General" end
    if PURE_CASTER[profile.class] and Has(stats, PHYSICAL_PRIMARY) then return false, "Strength/Agility/Attack Power on a caster class" end
    local caster, physical = Has(stats, CASTER_STATS), Has(stats, PHYSICAL_STATS)
    local tank = Has(stats, TANK_STATS)
    if role == "Melee DPS" or role == "Ranged DPS" or role == "Tank" then
        if caster and not physical and not tank then return false, "Caster stats only" end
        -- Intellect-only or Spirit items for physical specs
        if (tonumber(stats.SP) or 0) > 0 or (tonumber(stats.HEAL) or 0) > 0 then
            if not physical then return false, "Spell power for a physical spec" end
        end
        if role ~= "Tank" and tank and not physical then return false, "Tank-only stats" end
        if role == "Ranged DPS" and (tonumber(stats.STR) or 0) > 0 and not Has(stats, { "AGI", "AP", "RAP" }) then
            return false, "Strength-only item for a Hunter"
        end
    elseif role == "Caster DPS" or role == "Healer" then
        if (physical or tank or Has(stats, DEFENSIVE_STATS)) and not caster then return false, "Melee stats only" end
        if (tonumber(stats.AP) or 0) > 0 and (tonumber(stats.SP) or 0) == 0 and (tonumber(stats.HEAL) or 0) == 0 then
            return false, "Attack power item for a caster"
        end
    end
    return true
end

function GF.ItemFilter.CanUse(item, profile)
    if not item or not profile then return false, "Missing item/profile" end
    local levelLimit = profile.maxRequiredLevel or profile.level
    if item.requiredLevel and item.requiredLevel > levelLimit then return false, "Requires level " .. item.requiredLevel end
    if not GF.ItemFilter.ClassAllowed(item, profile) then return false, "Item tooltip restricts this class" end
    local weaponLocations = {
        INVTYPE_WEAPON=true, INVTYPE_WEAPONMAINHAND=true, INVTYPE_WEAPONOFFHAND=true,
        INVTYPE_2HWEAPON=true, INVTYPE_RANGED=true, INVTYPE_RANGEDRIGHT=true, INVTYPE_THROWN=true,
    }
    if weaponLocations[item.equipLoc] and (item.itemClass ~= 2 or item.subclass == nil) then
        return false, "Weapon metadata missing; press Refresh"
    end
    if item.itemClass == 2 then
        -- Fail closed for weapon records whose subtype is not yet known. The manual refresh
        -- fills subclass/equipLoc from the TBC client item cache; guessing here could recommend
        -- a weapon this class cannot train or equip.
        if item.subclass == nil then return false, "Weapon subtype unknown; press Refresh" end
        local allowed = WEAPONS[profile.class]
        if allowed and not allowed[tonumber(item.subclass)] then return false, "Weapon type not usable by this class" end
        if profile.class == "SHAMAN" and (tonumber(item.subclass) == 1 or tonumber(item.subclass) == 5) then
            local twoHandRank = GF.Compat.FindTalentRank(2, nil, function(lowerName)
                return lowerName:find("two%-handed") and (lowerName:find("axe") or lowerName:find("mace"))
            end)
            local hasTwoHandTalent = (tonumber(twoHandRank) or 0) > 0
            if not hasTwoHandTalent then return false, "Shaman needs the Two-Handed Axes and Maces talent" end
        end
        if item.equipLoc == "INVTYPE_WEAPONOFFHAND" and not CanDualWield(profile) then return false, "Off-hand weapon requires dual wield" end
        if item.equipLoc == "INVTYPE_WEAPON" and not CanDualWield(profile) and profile.class ~= "WARRIOR" then
            -- A generic one-handed item is still valid in main hand; it is not duplicated into off hand.
        end
        if item.subclass == 19 and not (profile.class == "MAGE" or profile.class == "PRIEST" or profile.class == "WARLOCK") then
            return false, "Wands are not usable by this class"
        end
        if item.slot == "Off Hand" and item.equipLoc == "INVTYPE_WEAPON" and not CanDualWield(profile) then
            return false, "Off-hand weapon requires dual wield"
        end
    end
    if not IsWearableArmor(item, profile) then return false, "Armor proficiency restriction" end
    if GF.ItemFilter.ArmorRank(item, profile) == nil then return false, "Armor type is not for this class" end
    do
        local fits, reason = GF.ItemFilter.StatsFit(item, profile)
        if not fits then return false, reason end
    end
    if item.slot and not GF.ItemFilter.SlotAllowedForSpec(item.slot, profile) then return false, "Not used by this spec" end
    if item.equipLoc == "INVTYPE_SHIELD" and not (profile.class == "WARRIOR" or profile.class == "PALADIN" or profile.class == "SHAMAN") then
        return false, "Cannot use shields"
    end
    if item.equipLoc == "INVTYPE_HOLDABLE" and not (profile.class == "MAGE" or profile.class == "PRIEST" or profile.class == "WARLOCK" or profile.class == "DRUID" or profile.class == "SHAMAN" or profile.class == "PALADIN") then
        return false, "Cannot use off-hand held items"
    end
    return true
end
