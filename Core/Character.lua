local GF = Gearfinder
GF.Character = GF.Character or {}

function GF.Character.Get()
    local localized, token = "Unknown", "WARRIOR"
    if UnitClass then localized, token = UnitClass("player") end
    return {
        className = localized or "Unknown",
        class = token or "WARRIOR",
        level = (UnitLevel and UnitLevel("player")) or 1,
        name = (UnitName and UnitName("player")) or "Player",
        faction = (UnitFactionGroup and UnitFactionGroup("player")) or nil,
    }
end

function GF.Character.GetEquippedItemID(slot)
    if type(GetInventoryItemID) ~= "function" then return nil end
    local inventory = {
        Head = { 1 }, Neck = { 2 }, Shoulder = { 3 }, Back = { 15 }, Chest = { 5 },
        Wrist = { 9 }, Hands = { 10 }, Waist = { 6 }, Legs = { 7 }, Feet = { 8 },
        Finger = { 11, 12 }, Trinket = { 13, 14 }, ["Main Hand"] = { 16 },
        ["Off Hand"] = { 17 }, ["Two-Hand"] = { 16 }, Ranged = { 18 }, Relic = { 18 },
    }
    local slots = inventory[slot] or {}
    for _, invSlot in ipairs(slots) do
        local id = GetInventoryItemID("player", invSlot)
        if id then return id end
    end
    return nil
end

function GF.Character.GetEquippedLink(slot)
    if type(GetInventoryItemLink) ~= "function" then return nil end
    local inventory = {
        Head = {1}, Neck = {2}, Shoulder = {3}, Back = {15}, Chest = {5}, Wrist = {9},
        Hands = {10}, Waist = {6}, Legs = {7}, Feet = {8}, Finger = {11,12},
        Trinket = {13,14}, ["Main Hand"] = {16}, ["Off Hand"] = {17},
        ["Two-Hand"] = {16}, Ranged = {18}, Relic = {18},
    }
    for _, invSlot in ipairs(inventory[slot] or {}) do
        local link = GetInventoryItemLink("player", invSlot)
        if link then return link end
    end
    return nil
end

function GF.Character.GetEquippedLinks(slot)
    if type(GetInventoryItemLink) ~= "function" then return {} end
    local inventory = {
        Head={1}, Neck={2}, Shoulder={3}, Back={15}, Chest={5}, Wrist={9}, Hands={10},
        Waist={6}, Legs={7}, Feet={8}, Finger={11,12}, Trinket={13,14},
        ["Main Hand"]={16}, ["Off Hand"]={17}, ["Two-Hand"]={16}, Ranged={18}, Relic={18},
    }
    local out = {}
    for _, invSlot in ipairs(inventory[slot] or {}) do
        local link = GetInventoryItemLink("player", invSlot)
        if link then out[#out+1] = link end
    end
    return out
end
