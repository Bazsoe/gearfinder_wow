-- Gearfinder compatibility layer.
-- Supports two clients with one code base:
--   * TBC Anniversary (Interface 20506): legacy globals (GetItemInfo, GetTalentTabInfo, ...)
--   * WoW: Forever 1.60.1 (Interface 16001): Mainline-family client, the old globals live in
--     C_Item / C_SpecializationInfo / ChatFrameUtil. Every call goes through here and falls
--     back from the modern namespace to the legacy global (or the other way round).
Gearfinder = Gearfinder or {}
local GF = Gearfinder
GF.Compat = GF.Compat or {}
local Compat = GF.Compat

local _, _, _, tocVersion = GetBuildInfo()
Compat.tocVersion = tonumber(tocVersion) or 0
-- Forever reports 16001 (1.60.1); the TBC Anniversary client reports 205xx.
Compat.isForever = Compat.tocVersion >= 16000 and Compat.tocVersion < 20000
Compat.isTBC = Compat.tocVersion >= 20000 and Compat.tocVersion < 30000
Compat.clientName = Compat.isForever and "WoW Forever" or "Unsupported client (built for WoW Forever)"

-- ---------- Item APIs ----------
function Compat.GetItemInfo(item)
    if C_Item and C_Item.GetItemInfo then return C_Item.GetItemInfo(item) end
    if _G.GetItemInfo then return _G.GetItemInfo(item) end
end

function Compat.GetItemInfoInstant(item)
    if C_Item and C_Item.GetItemInfoInstant then return C_Item.GetItemInfoInstant(item) end
    if _G.GetItemInfoInstant then return _G.GetItemInfoInstant(item) end
end

function Compat.GetItemStats(link)
    if C_Item and C_Item.GetItemStats then return C_Item.GetItemStats(link) end
    if _G.GetItemStats then return _G.GetItemStats(link) end
end

function Compat.RequestLoadItemData(itemID)
    if C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    else
        Compat.GetItemInfo(itemID)
    end
end

function Compat.HasItemInfo()
    return (C_Item and C_Item.GetItemInfo) ~= nil or _G.GetItemInfo ~= nil
end

function Compat.HasItemStats()
    return (C_Item and C_Item.GetItemStats) ~= nil or _G.GetItemStats ~= nil
end

-- ---------- Chat ----------
function Compat.InsertLink(link)
    if not link then return end
    if ChatFrameUtil and ChatFrameUtil.InsertLink then return ChatFrameUtil.InsertLink(link) end
    if _G.ChatEdit_InsertLink then return _G.ChatEdit_InsertLink(link) end
end

-- ---------- Talent APIs ----------
-- Which talent API this client offers (set lazily, shown in the diagnostics).
--   "legacy"   : GetNumTalentTabs / GetTalentTabInfo / GetNumTalents / GetTalentInfo (TBC Anniversary)
--   "spec"     : C_SpecializationInfo.GetSpecializationInfo / GetTalentInfo (Forever, Mainline-family)
Compat.talentAPI = "none"

local function CallSpecInfo(index)
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
        return pcall(C_SpecializationInfo.GetSpecializationInfo, index)
    end
    if _G.GetSpecializationInfo then
        return pcall(_G.GetSpecializationInfo, index)
    end
    return false
end

-- Returns a list of { name=, points= } for up to 3 trees, or nil when no readable talent API exists.
function Compat.ReadTalentTrees()
    -- 1) Legacy Classic API.
    if type(_G.GetNumTalentTabs) == "function" and type(_G.GetTalentTabInfo) == "function" then
        local okCount, count = pcall(_G.GetNumTalentTabs)
        count = okCount and tonumber(count) or 3
        local out = {}
        for i = 1, math.min(3, count) do
            local ok, a, b, c, d, e = pcall(_G.GetTalentTabInfo, i)
            local name, points = nil, 0
            if ok then
                if type(a) == "number" and type(b) == "string" then
                    -- id, name, description, icon, pointsSpent, ...
                    name, points = b, tonumber(e) or tonumber(c) or 0
                else
                    -- name, icon, pointsSpent, background
                    name, points = (type(a) == "string" and a or nil), tonumber(c) or 0
                end
            end
            out[i] = { name = name, points = math.max(0, points or 0) }
        end
        Compat.talentAPI = "legacy"
        return out
    end

    -- 2) C_SpecializationInfo / GetSpecializationInfo (Forever). The Classic trees are exposed as
    -- "specializations"; the 7th return value (pointsSpent) is the points put into that tree.
    local count = 3
    local getNum = (C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializations) or _G.GetNumSpecializations
    if type(getNum) == "function" then
        local okCount, n = pcall(getNum)
        if okCount and tonumber(n) and tonumber(n) > 0 then count = tonumber(n) end
    end
    local out, anyReadable = {}, false
    for i = 1, math.min(3, count) do
        local ok, specId, name, _, _, _, _, pointsSpent = CallSpecInfo(i)
        if ok and (name ~= nil or specId ~= nil) then anyReadable = true end
        out[i] = { name = ok and type(name) == "string" and name or nil, points = math.max(0, tonumber(ok and pointsSpent or 0) or 0) }
    end
    if anyReadable then
        Compat.talentAPI = "spec"
        return out
    end
    return nil
end

-- Reads one talent of a tree: returns name, rank (or nil when unreadable).
local function ReadTalent(tab, index)
    if type(_G.GetTalentInfo) == "function" and type(_G.GetNumTalents) == "function" then
        local ok, name, _, _, _, rank = pcall(_G.GetTalentInfo, tab, index)
        if ok and type(name) == "string" then return name, tonumber(rank) or 0 end
        return nil
    end
    if C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo then
        local ok, info = pcall(C_SpecializationInfo.GetTalentInfo, { specializationIndex = tab, talentIndex = index })
        if ok and type(info) == "table" and type(info.name) == "string" then
            return info.name, tonumber(info.rank) or (info.known and 1) or 0
        end
    end
    return nil
end

-- Returns a list of { name=, rank= } for a talent tree, or nil when there is no readable talent API.
function Compat.GetTalents(tab)
    local list = {}
    local limit = 80
    if type(_G.GetNumTalents) == "function" then
        local ok, n = pcall(_G.GetNumTalents, tab)
        limit = ok and tonumber(n) or 0
    elseif not (C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo) then
        return nil
    end
    for i = 1, limit do
        local name, rank = ReadTalent(tab, i)
        if name then list[#list + 1] = { name = name, rank = rank } end
    end
    return list
end

-- Rank of the first talent whose lower-cased name contains one of the given lower-case needles.
function Compat.FindTalentRank(tab, needles, matcher)
    local list = Compat.GetTalents(tab)
    if not list then return nil end
    for _, talent in ipairs(list) do
        local lower = talent.name:lower()
        if matcher then
            if matcher(lower) then return talent.rank end
        else
            for _, needle in ipairs(needles or {}) do
                if lower:find(needle, 1, true) then return talent.rank end
            end
        end
    end
    return 0
end

-- ---------- Window helpers ----------
function Compat.SetFrameTitle(frame, text)
    if frame.SetTitle then pcall(frame.SetTitle, frame, text); return end
    if frame.TitleText then frame.TitleText:SetText(text)
    elseif frame.TitleContainer and frame.TitleContainer.TitleText then frame.TitleContainer.TitleText:SetText(text) end
end

-- Mainline-family clients need BackdropTemplate; the Classic client accepts it too.
Compat.BackdropTemplate = "BackdropTemplate"

-- ---------- Diagnostics ----------
function Compat.Describe()
    local version, build = GetBuildInfo()
    return string.format("%s • client %s (%s) • interface %d • item API: %s • talent API: %s",
        Compat.clientName, tostring(version), tostring(build), Compat.tocVersion,
        (C_Item and C_Item.GetItemInfo) and "C_Item" or "legacy", Compat.talentAPI)
end
