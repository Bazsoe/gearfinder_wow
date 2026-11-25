-- Gearfinder for WoW Forever: class and talent-tree profiles (9 classes, 3 trees each).
-- Weights use the canonical stat keys from Core/Stats.lua. HIT and CRIT are in rating-equivalent units
-- (10 rating = 1% hit, 14 rating = 1% crit at level 60). The numbers are planning estimates, not a
-- simulator result, and are meant to be tuned as Forever itemization settles.
local GF = Gearfinder
GF.Specializations = GF.Specializations or {}
GF.SpecNames = {
    WARRIOR = { "Arms", "Fury", "Protection" },
    PALADIN = { "Holy", "Protection", "Retribution" },
    HUNTER = { "Beast Mastery", "Marksmanship", "Survival" },
    ROGUE = { "Assassination", "Combat", "Subtlety" },
    PRIEST = { "Discipline", "Holy", "Shadow" },
    SHAMAN = { "Elemental", "Enhancement", "Restoration" },
    MAGE = { "Arcane", "Fire", "Frost" },
    WARLOCK = { "Affliction", "Demonology", "Destruction" },
    DRUID = { "Balance", "Feral Combat (Cat)", "Restoration" },
}
GF.SpecRoles = {
    WARRIOR = { "Melee DPS", "Melee DPS", "Tank" },
    PALADIN = { "Healer", "Tank", "Melee DPS" },
    HUNTER = { "Ranged DPS", "Ranged DPS", "Ranged DPS" },
    ROGUE = { "Melee DPS", "Melee DPS", "Melee DPS" },
    PRIEST = { "Healer", "Healer", "Caster DPS" },
    SHAMAN = { "Caster DPS", "Melee DPS", "Healer" },
    MAGE = { "Caster DPS", "Caster DPS", "Caster DPS" },
    WARLOCK = { "Caster DPS", "Caster DPS", "Caster DPS" },
    DRUID = { "Caster DPS", "Melee DPS", "Healer" },
}

-- Shared weight templates, then per-spec overrides.
local function Make(base, override)
    local out = {}
    for k, v in pairs(base) do out[k] = v end
    for k, v in pairs(override or {}) do out[k] = v end
    return out
end
local CASTER = { SP = 1.00, HIT = 0.95, CRIT = 0.72, HASTE = 0.80, INT = 0.34, SPI = 0.06, MP5 = 0.12, STA = 0.12 }
local HEALER = { HEAL = 1.00, SP = 0.20, INT = 0.72, MP5 = 0.80, CRIT = 0.50, HASTE = 0.36, SPI = 0.30, STA = 0.14 }
local MELEE  = { AP = 0.50, HIT = 1.05, CRIT = 0.80, EXP = 1.00, WSKILL = 0.60, ARP = 0.50, HASTE = 0.60, DPS = 0.30, STA = 0.12 }
local TANK   = { STA = 1.00, ARMOR = 0.010, DEF = 1.00, DODGE = 0.80, PARRY = 0.80, BLOCK = 0.60, BLOCKVAL = 0.60, HIT = 0.38, EXP = 0.45, WSKILL = 0.30, STR = 0.26, AGI = 0.22 }
local RANGED = { RAP = 0.80, AP = 0.60, HIT = 1.10, CRIT = 0.86, HASTE = 0.70, ARP = 0.50, INT = 0.22, DPS = 0.30, STA = 0.12 }

GF.SpecProfiles = {
    WARRIOR = {
        [1] = { name = "Arms Warrior", priority = "Strength / Attack Power; Hit and Expertise; Crit; Weapon Skill.", weights = Make(MELEE, { STR = 1.20, AGI = 0.56 }) },
        [2] = { name = "Fury Warrior", priority = "Strength / Attack Power; Hit and Expertise; Crit; Haste.", weights = Make(MELEE, { STR = 1.18, AGI = 0.55, HIT = 1.15, HASTE = 0.78 }) },
        [3] = { name = "Protection Warrior", priority = "Stamina / Armor; Defense and avoidance; Block; threat stats.", weights = Make(TANK) },
    },
    PALADIN = {
        [1] = { name = "Holy Paladin", priority = "Bonus Healing; Intellect; Mp5; Crit (healing crits matter in Forever).", weights = Make(HEALER, { MP5 = 0.85, INT = 0.80 }) },
        [2] = { name = "Protection Paladin", priority = "Defense / Avoidance; Stamina; Bonus Damage for threat; Hit / Expertise.", weights = Make(TANK, { SP = 0.50, INT = 0.20, BLOCK = 0.80, BLOCKVAL = 0.70 }) },
        [3] = { name = "Retribution Paladin", priority = "Strength / Attack Power; Hit and Expertise; Crit; Weapon Skill.", weights = Make(MELEE, { STR = 1.16, AGI = 0.48, INT = 0.15 }) },
    },
    HUNTER = {
        [1] = { name = "Beast Mastery Hunter", priority = "Hit; Agility / Ranged Attack Power; Crit; Haste.", weights = Make(RANGED, { AGI = 1.12 }) },
        [2] = { name = "Marksmanship Hunter", priority = "Hit; Agility / Attack Power; Crit; Armor Penetration.", weights = Make(RANGED, { AGI = 1.16, CRIT = 0.96, ARP = 0.72 }) },
        [3] = { name = "Survival Hunter", priority = "Agility; Hit; Crit; Attack Power.", weights = Make(RANGED, { AGI = 1.35, RAP = 0.74, AP = 0.57, CRIT = 0.97, EXP = 0.40 }) },
    },
    ROGUE = {
        [1] = { name = "Assassination Rogue", priority = "Agility; Hit and Expertise; Attack Power; Crit.", weights = Make(MELEE, { AGI = 1.18, STR = 0.25, AP = 0.68 }) },
        [2] = { name = "Combat Rogue", priority = "Hit and Expertise; Agility / Attack Power; Weapon Skill; Haste.", weights = Make(MELEE, { AGI = 1.08, STR = 0.23, AP = 0.70, HIT = 1.20, WSKILL = 0.80, HASTE = 0.80 }) },
        [3] = { name = "Subtlety Rogue", priority = "Agility; Hit; Crit; Expertise and Attack Power.", weights = Make(MELEE, { AGI = 1.24, STR = 0.20, AP = 0.65, CRIT = 0.92 }) },
    },
    PRIEST = {
        [1] = { name = "Discipline Priest", priority = "Bonus Healing; Intellect; Mp5; Crit and Spirit.", weights = Make(HEALER, { INT = 0.88, CRIT = 0.62, SPI = 0.38 }) },
        [2] = { name = "Holy Priest", priority = "Bonus Healing; Intellect; Mp5 / Spirit; Haste and Crit.", weights = Make(HEALER, { HEAL = 1.05, SPI = 0.48, HASTE = 0.42 }) },
        [3] = { name = "Shadow Priest", priority = "Hit; Spell Damage; Crit / Haste; Intellect.", weights = Make(CASTER, { SPI = 0.18, HIT = 1.00 }) },
    },
    SHAMAN = {
        [1] = { name = "Elemental Shaman", priority = "Hit; Spell Damage; Crit; Intellect.", weights = Make(CASTER, { HIT = 1.00, MP5 = 0.20 }) },
        [2] = { name = "Enhancement Shaman", priority = "Expertise / Hit; Strength and Attack Power; Crit; Agility.", weights = Make(MELEE, { STR = 1.08, AGI = 0.74, AP = 0.70, INT = 0.18, HIT = 1.15, EXP = 1.10 }) },
        [3] = { name = "Restoration Shaman", priority = "Bonus Healing; Intellect; Mp5; Crit.", weights = Make(HEALER, { HEAL = 1.05, MP5 = 0.84, INT = 0.84 }) },
    },
    MAGE = {
        [1] = { name = "Arcane Mage", priority = "Hit; Spell Damage; Haste; Intellect and Crit.", weights = Make(CASTER, { HASTE = 1.00, CRIT = 0.70 }) },
        [2] = { name = "Fire Mage", priority = "Hit; Spell Damage; Crit; Haste and Intellect.", weights = Make(CASTER, { CRIT = 0.98, HASTE = 0.84, INT = 0.31 }) },
        [3] = { name = "Frost Mage", priority = "Hit; Spell Damage; Crit / Haste; Intellect.", weights = Make(CASTER, { CRIT = 0.82, HASTE = 0.86 }) },
    },
    WARLOCK = {
        [1] = { name = "Affliction Warlock", priority = "Hit; Spell Damage; Haste; Crit (DoTs can crit); Stamina.", weights = Make(CASTER, { CRIT = 0.70, HASTE = 0.92, STA = 0.18 }) },
        [2] = { name = "Demonology Warlock", priority = "Hit; Spell Damage; Crit / Haste; Intellect and Stamina.", weights = Make(CASTER, { STA = 0.20, CRIT = 0.76 }) },
        [3] = { name = "Destruction Warlock", priority = "Hit; Spell Damage; Haste; Crit; Intellect.", weights = Make(CASTER, { HIT = 1.05, CRIT = 0.88, HASTE = 0.95 }) },
    },
    DRUID = {
        [1] = { name = "Balance Druid", priority = "Hit; Crit; Spell Damage; Intellect.", weights = Make(CASTER, { CRIT = 0.90, INT = 0.42, SPI = 0.18 }) },
        [2] = { name = "Feral Combat Druid (Cat DPS)", priority = "Agility; Hit / Expertise; Strength; Crit and Attack Power.", weights = Make(MELEE, { AGI = 1.30, STR = 0.98, AP = 0.48, HIT = 1.10, EXP = 1.00, STA = 0.18 }) },
        [3] = { name = "Restoration Druid", priority = "Bonus Healing; Spirit; Mp5 / Intellect; Crit.", weights = Make(HEALER, { SPI = 0.82, INT = 0.66, MP5 = 0.62, CRIT = 0.40 }) },
    },
}

-- Feral is one talent tree with two PvE gear roles (cat DPS and bear tank).
GF.SpecProfiles.DRUID[4] = {
    name = "Feral Druid (Bear Tank)",
    priority = "Stamina and armor; Defense / avoidance; Agility; threat stats.",
    weights = Make(TANK, { STA = 1.05, ARMOR = 0.012, AGI = 0.68, STR = 0.44, DEF = 1.00, BLOCK = 0, BLOCKVAL = 0, PARRY = 0 }),
}

GF.StatLabels = GF.StatLabels or {}
for key, label in pairs((GF.Stats and GF.Stats.Labels) or {}) do GF.StatLabels[key] = label end


function GF.Specializations.ReadTalentTrees()
    local trees, bestIndex, bestPoints, total = {}, nil, -1, 0
    local read = GF.Compat and GF.Compat.ReadTalentTrees and GF.Compat.ReadTalentTrees() or nil
    for i = 1, 3 do
        local entry = read and read[i] or nil
        local name = entry and entry.name or nil
        local points = math.max(0, tonumber(entry and entry.points) or 0)
        trees[i] = { index = i, name = name, points = points }
        total = total + points
        if points > bestPoints then bestIndex, bestPoints = i, points end
    end
    if bestPoints <= 0 then bestIndex = nil end
    return trees, bestIndex, total
end

function GF.Specializations.GetProfile()
    local char = GF.Character.Get()
    local names = GF.SpecNames[char.class] or { "Tree 1", "Tree 2", "Tree 3" }
    local trees, detected, total = GF.Specializations.ReadTalentTrees()
    local saved = GearfinderCharDB and tonumber(GearfinderCharDB.specOverride) or nil
    if saved and (saved < 1 or saved > #names) then saved = nil end
    local index = saved or detected or 1
    local displayName = names[index] or names[1]
    local scoreIndex = index
    if char.class == "DRUID" and index == 2 and GearfinderCharDB and GearfinderCharDB.feralVariant == "Bear" then
        displayName = "Feral Combat (Bear Tank)"
        scoreIndex = 4
    end
    return {
        class = char.class, className = char.className, level = char.level,
        specIndex = index, scoreIndex = scoreIndex, specName = displayName,
        auto = saved == nil, detectedIndex = detected, trees = trees,
        totalTalentPoints = total, role = (scoreIndex == 4 and "Tank") or (((GF.SpecRoles[char.class] or {})[index]) or "General"),
    }
end

function GF.Specializations.CycleOverride()
    GearfinderCharDB = GearfinderCharDB or {}
    local profile = GF.Specializations.GetProfile()
    local names = GF.SpecNames[profile.class] or { "Tree 1", "Tree 2", "Tree 3" }
    local current = tonumber(GearfinderCharDB.specOverride)
    if not current then
        GearfinderCharDB.specOverride = 1
    elseif current < #names then
        GearfinderCharDB.specOverride = current + 1
    else
        GearfinderCharDB.specOverride = nil -- return to AUTO
    end
    return GF.Specializations.GetProfile()
end

function GF.Specializations.CycleFeralVariant()
    GearfinderCharDB = GearfinderCharDB or {}
    if GearfinderCharDB.feralVariant == "Bear" then
        GearfinderCharDB.feralVariant = "Cat"
    else
        GearfinderCharDB.feralVariant = "Bear"
    end
    return GF.Specializations.GetProfile()
end
