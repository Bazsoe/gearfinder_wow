-- Gearfinder main window for WoW Forever.
-- Built on the Mainline PortraitFrameTemplate that Forever shares with modern WoW (falls back to the
-- basic frame template if a client does not have it). Three panels:
--   EQUIPMENT   – one card per gear slot with the currently selected recommendation
--   UPGRADES    – ranked alternatives for the selected slot (scroll with the mouse wheel)
--   OVERVIEW    – character, talent tree, best next instance, catalogue and refresh info
local GF = Gearfinder
GF.UI = GF.UI or {}
GF.UI.MainWindow = GF.UI.MainWindow or {}
local UI = GF.UI

local ICON = "Interface\\AddOns\\Gearfinder\\Media\\MinimapIcon"
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
local WHITE = "Interface\\Buttons\\WHITE8X8"

local SLOT_DEFS = {
    { key = "Head", label = "Head", icon = "Interface\\Icons\\INV_Helmet_03" },
    { key = "Neck", label = "Neck", icon = "Interface\\Icons\\INV_Jewelry_Necklace_01" },
    { key = "Shoulder", label = "Shoulders", icon = "Interface\\Icons\\INV_Shoulder_02" },
    { key = "Back", label = "Back", icon = "Interface\\Icons\\INV_Misc_Cape_11" },
    { key = "Chest", label = "Chest", icon = "Interface\\Icons\\INV_Chest_Cloth_17" },
    { key = "Wrist", label = "Wrists", icon = "Interface\\Icons\\INV_Bracer_07" },
    { key = "Hands", label = "Hands", icon = "Interface\\Icons\\INV_Gauntlets_04" },
    { key = "Waist", label = "Waist", icon = "Interface\\Icons\\INV_Belt_03" },
    { key = "Legs", label = "Legs", icon = "Interface\\Icons\\INV_Pants_06" },
    { key = "Feet", label = "Feet", icon = "Interface\\Icons\\INV_Boots_05" },
    { key = "Finger", label = "Ring", icon = "Interface\\Icons\\INV_Jewelry_Ring_03" },
    { key = "Trinket", label = "Trinket", icon = "Interface\\Icons\\INV_Misc_ArmorKit_03" },
    { key = "Main Hand", label = "Main Hand", icon = "Interface\\Icons\\INV_Sword_04" },
    { key = "Off Hand", label = "Off Hand", icon = "Interface\\Icons\\INV_Shield_04" },
    { key = "Two-Hand", label = "Two-Hand", icon = "Interface\\Icons\\INV_Weapon_Halberd_01" },
    { key = "Ranged", label = "Ranged / Wand", icon = "Interface\\Icons\\INV_Weapon_Bow_05" },
    { key = "Relic", label = "Relic", icon = "Interface\\Icons\\INV_Misc_Book_11" },
}
local SLOT_BY_KEY = {}
for _, def in ipairs(SLOT_DEFS) do SLOT_BY_KEY[def.key] = def end
local LEFT_SLOTS = { "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs" }
local RIGHT_SLOTS = { "Feet", "Finger", "Trinket", "Main Hand", "Off Hand", "Two-Hand", "Ranged", "Relic" }

local COLOR = {
    window = { 0.040, 0.045, 0.060, 0.62 },
    panel = { 0.070, 0.078, 0.100, 0.55 },
    card = { 0.095, 0.105, 0.130, 0.70 },
    cardHover = { 0.135, 0.150, 0.190, 0.85 },
    edge = { 0.26, 0.23, 0.16, 1 },
    edgeSelected = { 1.00, 0.82, 0.35, 1 },
    gold = { 1.00, 0.82, 0.35 },
    text = { 0.93, 0.91, 0.86 },
    dim = { 0.60, 0.60, 0.58 },
    good = { 0.38, 0.92, 0.45 },
    bad = { 1.00, 0.42, 0.36 },
    accent = { 0.38, 0.68, 1.00 },
    warn = { 1.00, 0.65, 0.20 },
}

local window, content
local ui = {}            -- widgets
local cards = {}         -- slot cards by key
local rows = {}          -- alternative rows
local selectedSlot
local scrollOffset = 0
local ROW_COUNT, ROW_HEIGHT = 8, 56

-- ---------- helpers ----------
local function QualityColor(quality)
    quality = tonumber(quality) or 1
    local entry = _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[quality]
    if entry and entry.r then return entry.r, entry.g, entry.b end
    local fallback = { [0] = { 0.62, 0.62, 0.62 }, [1] = { 1, 1, 1 }, [2] = { 0.12, 1, 0 }, [3] = { 0, 0.44, 0.87 }, [4] = { 0.64, 0.21, 0.93 }, [5] = { 1, 0.5, 0 } }
    local c = fallback[quality] or fallback[1]
    return c[1], c[2], c[3]
end

local function SetBox(frame, bg, edge)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(edge[1], edge[2], edge[3], edge[4] or 1)
end

local function Text(parent, font, x, y, width, justify, color)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then fs:SetWidth(width) end
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    if color then fs:SetTextColor(color[1], color[2], color[3]) end
    return fs
end

local function Panel(parent, x, y, width, height, title)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetSize(width, height)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    SetBox(panel, COLOR.panel, COLOR.edge)
    if title then
        local fs = Text(panel, "GameFontNormal", 10, -8, width - 20, "LEFT", COLOR.gold)
        fs:SetText(title)
        local line = panel:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(COLOR.edge[1], COLOR.edge[2], COLOR.edge[3], 0.9)
        line:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -26)
        line:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -26)
        line:SetHeight(1)
        panel.title = fs
    end
    return panel
end

local function Button(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetText(text or "")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", onClick)
    return button
end

local function Tip(widget, title, ...)
    local lines = { ... }
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(title, 1, 0.82, 0)
        for _, line in ipairs(lines) do GameTooltip:AddLine(line, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function GetSelectionStore()
    GearfinderCharDB = GearfinderCharDB or {}
    GearfinderCharDB.selectedAlternativesBySlot = GearfinderCharDB.selectedAlternativesBySlot or {}
    return GearfinderCharDB.selectedAlternativesBySlot
end

local function ScoreText(value)
    return string.format("%.1f", tonumber(value) or 0)
end

local function DeltaText(delta)
    if delta == nil then return "new slot", COLOR.accent end
    if delta >= 0 then return "+" .. ScoreText(delta), COLOR.good end
    return ScoreText(delta), COLOR.bad
end

-- ---------- slot cards ----------
local function SelectSlot(slot)
    selectedSlot = slot
    if window then window.slotChosenOnce = true end
    scrollOffset = 0
    UI.Refresh()
end

local function CreateSlotCard(parent, def, x, y)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(158, 46)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    SetBox(card, COLOR.card, COLOR.edge)
    card.def = def

    card.iconFrame = CreateFrame("Frame", nil, card, "BackdropTemplate")
    card.iconFrame:SetSize(38, 38)
    card.iconFrame:SetPoint("LEFT", card, "LEFT", 4, 0)
    SetBox(card.iconFrame, { 0, 0, 0, 1 }, COLOR.edge)
    card.icon = card.iconFrame:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(34, 34)
    card.icon:SetPoint("CENTER", card.iconFrame, "CENTER")
    card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    card.icon:SetTexture(def.icon)

    card.slotText = Text(card, "GameFontNormalSmall", 46, -5, 70, "LEFT", COLOR.gold)
    card.slotText:SetText(def.label:upper())
    card.countText = Text(card, "GameFontDisableSmall", 100, -5, 54, "RIGHT")
    card.itemText = Text(card, "GameFontHighlightSmall", 46, -18, 108, "LEFT", COLOR.text)
    card.deltaText = Text(card, "GameFontNormalSmall", 46, -31, 108, "LEFT", COLOR.dim)

    card:SetScript("OnClick", function(self) SelectSlot(self.def.key) end)
    card:SetScript("OnEnter", function(self)
        if self.selected then return end
        self:SetBackdropColor(COLOR.cardHover[1], COLOR.cardHover[2], COLOR.cardHover[3], COLOR.cardHover[4])
        if self.candidate then GF.UI.ItemTooltip.Show(self, self.candidate, self.selectedIndex, self.altCount) end
    end)
    card:SetScript("OnLeave", function(self)
        if not self.selected then self:SetBackdropColor(COLOR.card[1], COLOR.card[2], COLOR.card[3], COLOR.card[4]) end
        GF.UI.ItemTooltip.Hide()
    end)
    return card
end

local function UpdateSlotCard(card, candidate, alternatives, selectedIndex)
    card.candidate, card.selectedIndex, card.altCount = candidate, selectedIndex, #alternatives
    card.selected = (card.def.key == selectedSlot)
    local edge = card.selected and COLOR.edgeSelected or COLOR.edge
    card:SetBackdropBorderColor(edge[1], edge[2], edge[3], 1)
    card:SetBackdropColor(COLOR.card[1], COLOR.card[2], COLOR.card[3], COLOR.card[4])
    if candidate then
        card.icon:SetTexture(candidate.texture or QUESTION)
        card.icon:SetDesaturated(false)
        local r, g, b = QualityColor(candidate.quality)
        card.iconFrame:SetBackdropBorderColor(r, g, b, 1)
        card.itemText:SetText(candidate.name or "?")
        card.itemText:SetTextColor(r, g, b)
        local text, color = DeltaText(candidate.delta)
        card.deltaText:SetText(text .. "  •  " .. ((candidate.requiredLevel or 0) > 0 and ("Lv" .. candidate.requiredLevel) or ("i" .. tostring(candidate.itemLevel or 0))))
        card.deltaText:SetTextColor(color[1], color[2], color[3])
        card.countText:SetText(#alternatives > 1 and ("+" .. (#alternatives - 1)) or "")
    else
        card.icon:SetTexture(card.def.icon)
        card.icon:SetDesaturated(true)
        card.iconFrame:SetBackdropBorderColor(COLOR.edge[1], COLOR.edge[2], COLOR.edge[3], 1)
        card.itemText:SetText("No upgrade found")
        card.itemText:SetTextColor(COLOR.dim[1], COLOR.dim[2], COLOR.dim[3])
        card.deltaText:SetText("")
        card.countText:SetText("")
    end
end

-- ---------- alternative rows ----------
local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(parent:GetWidth() - 16, ROW_HEIGHT - 4)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -34 - (index - 1) * ROW_HEIGHT)
    SetBox(row, COLOR.card, COLOR.edge)

    row.rank = Text(row, "GameFontDisableSmall", 4, -6, 16, "CENTER")
    row.iconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.iconFrame:SetSize(40, 40)
    row.iconFrame:SetPoint("LEFT", row, "LEFT", 22, 0)
    SetBox(row.iconFrame, { 0, 0, 0, 1 }, COLOR.edge)
    row.icon = row.iconFrame:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(36, 36)
    row.icon:SetPoint("CENTER", row.iconFrame, "CENTER")
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local textWidth = parent:GetWidth() - 22 - 40 - 90
    row.name = Text(row, "GameFontNormal", 68, -6, textWidth, "LEFT", COLOR.text)
    row.source = Text(row, "GameFontDisableSmall", 68, -22, textWidth, "LEFT", COLOR.dim)
    row.tags = Text(row, "GameFontNormalSmall", 68, -35, textWidth, "LEFT", COLOR.accent)
    row.score = Text(row, "GameFontNormalLarge", 0, -8, 76, "RIGHT", COLOR.text)
    row.score:ClearAllPoints()
    row.score:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -8)
    row.delta = Text(row, "GameFontNormalSmall", 0, -28, 76, "RIGHT", COLOR.dim)
    row.delta:ClearAllPoints()
    row.delta:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -30)

    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(COLOR.cardHover[1], COLOR.cardHover[2], COLOR.cardHover[3], COLOR.cardHover[4])
        if self.item then GF.UI.ItemTooltip.Show(self, self.item, self.position, self.total) end
    end)
    row:SetScript("OnLeave", function(self)
        local bg = self.chosen and COLOR.cardHover or COLOR.card
        self:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
        GF.UI.ItemTooltip.Hide()
    end)
    row:SetScript("OnClick", function(self)
        if not self.item then return end
        if IsShiftKeyDown and IsShiftKeyDown() and self.item.link then
            GF.Compat.InsertLink(self.item.link)
            return
        end
        GetSelectionStore()[selectedSlot] = self.item.id
        UI.Refresh()
    end)
    return row
end

local function SourceLine(item)
    local sources = item.sources or {}
    local text = sources[1] or "Unknown source"
    if #sources > 1 then text = text .. "  (+" .. (#sources - 1) .. " more)" end
    return text
end

local function TagLine(item)
    local bits = {}
    if (item.requiredLevel or 0) > 0 then bits[#bits + 1] = "|cffffffffLevel " .. (item.levelEstimated and "~" or "") .. item.requiredLevel .. "|r" end
    if (item.itemLevel or 0) > 0 then bits[#bits + 1] = "iLvl " .. item.itemLevel end
    local info = item.sourceInfo and item.sourceInfo[1]
    if info then
        if info.isRaid then bits[#bits + 1] = "|cffff9a3cRAID" .. (info.size and (" " .. info.size) or "") .. "|r" end
        if info.new then bits[#bits + 1] = "|cff5df06eNEW in Forever|r" end
        if info.locked then bits[#bits + 1] = "|cffffd24dopens Dec 9|r" end
    end
    return table.concat(bits, "  •  ")
end

local function UpdateRows(alternatives)
    local total = #alternatives
    local maxOffset = math.max(0, total - ROW_COUNT)
    if scrollOffset > maxOffset then scrollOffset = maxOffset end
    if scrollOffset < 0 then scrollOffset = 0 end
    local chosenID = tonumber(GetSelectionStore()[selectedSlot])
    for i = 1, ROW_COUNT do
        local row = rows[i]
        local position = scrollOffset + i
        local item = alternatives[position]
        row.item, row.position, row.total = item, position, total
        if item then
            local r, g, b = QualityColor(item.quality)
            row.icon:SetTexture(item.texture or QUESTION)
            row.iconFrame:SetBackdropBorderColor(r, g, b, 1)
            row.name:SetText(item.name or "?")
            row.name:SetTextColor(r, g, b)
            row.source:SetText(SourceLine(item))
            row.tags:SetText(TagLine(item))
            row.rank:SetText(tostring(position))
            row.score:SetText(ScoreText(item.score))
            local text, color = DeltaText(item.delta)
            row.delta:SetText(text)
            row.delta:SetTextColor(color[1], color[2], color[3])
            row.chosen = (chosenID and tonumber(item.id) == chosenID) or (not chosenID and position == 1)
            local edge = row.chosen and COLOR.edgeSelected or COLOR.edge
            row:SetBackdropBorderColor(edge[1], edge[2], edge[3], 1)
            local bg = row.chosen and COLOR.cardHover or COLOR.card
            row:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
            row:Show()
        else
            row:Hide()
        end
    end
    if ui.scrollText then
        if total > ROW_COUNT then
            ui.scrollText:SetText("Showing " .. (scrollOffset + 1) .. "–" .. math.min(total, scrollOffset + ROW_COUNT) .. " of " .. total .. "  •  mouse wheel to scroll")
        else
            ui.scrollText:SetText(total > 0 and (total .. " alternative" .. (total == 1 and "" or "s")) or "")
        end
    end
end

-- ---------- progress bar ----------
local function UpdateProgress()
    if not ui.progress then return end
    local state = GF.State.progress
    local width = ui.progress:GetWidth() - 2
    if state and (state.total or 0) > 0 then
        local pct = math.max(0.02, math.min(1, (state.done or 0) / state.total))
        ui.progressFill:SetWidth(math.max(1, width * pct))
        ui.progressFill:SetColorTexture(COLOR.accent[1], COLOR.accent[2], COLOR.accent[3], 0.85)
    elseif GF.State.loading then
        ui.progressFill:SetWidth(math.max(1, width * 0.08))
        ui.progressFill:SetColorTexture(COLOR.accent[1], COLOR.accent[2], COLOR.accent[3], 0.85)
    else
        ui.progressFill:SetWidth(1)
    end
end

-- ---------- build ----------
local function BuildOverview(parent)
    local panel = Panel(parent, 0, 0, 218, 500, "OVERVIEW")
    panel:ClearAllPoints()
    ui.overview = panel
    local function Pair(key, label, y, height)
        local l = Text(panel, "GameFontDisableSmall", 12, y, 194, "LEFT")
        l:SetText(label)
        local v = Text(panel, "GameFontHighlightSmall", 12, y - 13, 194, "LEFT", COLOR.text)
        v:SetWordWrap(true)
        v:SetHeight(height or 14)
        ui[key] = v
    end
    Pair("ovChar", "CHARACTER", -36)
    Pair("ovSpec", "TALENT TREE", -72)
    Pair("ovArmor", "CAN WEAR", -108, 28)
    Pair("ovBest", "BEST NEXT INSTANCE", -152, 28)
    Pair("ovUpg", "RECOMMENDED UPGRADES", -200)
    Pair("ovCat", "LIVE CATALOGUE", -236, 28)
    Pair("ovRefresh", "LAST REFRESH", -284, 28)
    Pair("ovPriority", "STAT PRIORITY", -332, 56)
    ui.ovNote = Text(panel, "GameFontDisableSmall", 12, -404, 194, "LEFT", COLOR.dim)
    ui.ovNote:SetWordWrap(true)
    ui.ovNote:SetHeight(60)
    return panel
end

function UI.Create()
    if window then return end
    local ok, frame = pcall(CreateFrame, "Frame", "GearfinderMainFrame", UIParent, "PortraitFrameTemplate")
    if not ok or not frame then
        frame = CreateFrame("Frame", "GearfinderMainFrame", UIParent, "BasicFrameTemplateWithInset")
    end
    window = frame
    window:SetSize(990, 642)
    window:SetPoint("CENTER")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetClampedToScreen(true)
    window:SetFrameStrata("HIGH")
    window:Hide()
    if _G.UISpecialFrames then table.insert(_G.UISpecialFrames, "GearfinderMainFrame") end
    GF.Compat.SetFrameTitle(window, "Gearfinder  ·  WoW Forever")
    pcall(function()
        local logo = GF.UI.GetLogo and GF.UI.GetLogo() or ICON
        if window.SetPortraitToAsset then window:SetPortraitToAsset(logo)
        elseif window.portrait then window.portrait:SetTexture(logo) end
    end)

    -- clicking the portrait switches the logo (golden runes <-> arcane blue)
    pcall(function()
        local holder = window.PortraitContainer or window.portrait
        if not holder then return end
        local hit = CreateFrame("Button", nil, window)
        hit:SetAllPoints(holder)
        hit:SetFrameLevel(window:GetFrameLevel() + 20)
        hit:SetScript("OnClick", function() GF.UI.SetLogo() end)
        hit:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Gearfinder logo", 1, 0.82, 0)
            GameTooltip:AddLine("Click to switch: golden runes / arcane blue.", 1, 1, 1, true)
            GameTooltip:AddLine("Also: /gf logo 1  or  /gf logo 2", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        hit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end)

    -- make the stock frame art see-through so the game world shows behind the window
    pcall(function()
        for _, key in ipairs({ "Bg", "TitleBg", "TopTileStreaks" }) do
            if window[key] then window[key]:SetAlpha(0.35) end
        end
        if window.Inset and window.Inset.Bg then window.Inset.Bg:SetAlpha(0) end
        if window.NineSlice and window.NineSlice.Center then window.NineSlice.Center:SetAlpha(0.35) end
    end)

    content = CreateFrame("Frame", nil, window, "BackdropTemplate")
    content:SetPoint("TOPLEFT", window, "TOPLEFT", 8, -62)
    content:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -8, 8)
    SetBox(content, COLOR.window, COLOR.edge)

    -- toolbar
    ui.specButton = Button(content, "Spec", 250, function(_, mouseButton)
        local profile = GF.Specializations.GetProfile()
        if mouseButton == "RightButton" then
            if profile.class == "DRUID" and profile.specIndex == 2 then GF.Specializations.CycleFeralVariant() end
        else
            GF.Specializations.CycleOverride()
        end
        GF.API.RecalculateCached()
        UI.Refresh()
    end)
    ui.specButton:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -8)
    Tip(ui.specButton, "Talent tree profile", "AUTO reads your talent points (WoW Forever: 3 trees, 7 rows).",
        "Left click: cycle profiles. The last click returns to AUTO.", "Druid Feral: right-click switches Cat DPS / Bear Tank.")

    ui.sourceButton = Button(content, "Source: All", 112, function()
        local mode = GF.API.GetSourceFilter()
        GF.API.SetSourceFilter(mode == "all" and "dungeon" or (mode == "dungeon" and "raid" or "all"))
    end)
    ui.sourceButton:SetPoint("LEFT", ui.specButton, "RIGHT", 6, 0)
    Tip(ui.sourceButton, "Source filter", "Click to cycle: All → Dungeons → Raids.", "Raids: Molten Core, Onyxia, Blackwing Lair and the new Barrow Deeps / Hyjal Summit, as far as the journal lists them.")

    ui.levelButton = Button(content, "Level: now", 112, function()
        local current = GF.API.GetLevelAhead()
        GF.API.SetLevelAhead(current == 0 and 5 or (current == 5 and 99 or 0))
    end)
    ui.levelButton:SetPoint("LEFT", ui.sourceButton, "RIGHT", 6, 0)
    Tip(ui.levelButton, "Level window", "How far above your level an item's required level may be.", "Click to cycle: now → +5 levels → any level (plan for 60).")

    ui.pinsButton = Button(content, "Map pins: On", 112, function()
        GF.UI.MapPins.SetEnabled(not GF.UI.MapPins.IsEnabled())
        UI.Refresh()
    end)
    ui.pinsButton:SetPoint("LEFT", ui.levelButton, "RIGHT", 6, 0)
    Tip(ui.pinsButton, "World map pins", "Shows the exact dungeon and raid entrances on the world map,", "with the number of upgrade slots each one offers you.", "Right-click a pin to set a waypoint.")

    ui.refreshButton = Button(content, "Refresh", 112, function() GF.API.Refresh() end)
    ui.refreshButton:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -8)
    Tip(ui.refreshButton, "Refresh from the live client", "Reads every dungeon and raid from the Encounter Journal, then loads the items.",
        "Runs only when you press this button, never on a timer.")

    ui.infoButton = Button(content, "i", 26, function()
        GF.UI.Minimap.PrintInfo()
    end)
    ui.infoButton:SetPoint("RIGHT", ui.refreshButton, "LEFT", -6, 0)
    Tip(ui.infoButton, "Client & data info", "Prints client build, API and catalogue details to the chat.")

    local searchBox = CreateFrame("EditBox", "GearfinderSearchBox", content, "InputBoxTemplate")
    searchBox:SetSize(132, 22)
    searchBox:SetPoint("RIGHT", ui.infoButton, "LEFT", -12, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(40)
    searchBox:SetScript("OnEnterPressed", function(self)
        local query = (self:GetText() or ""):gsub("^%s*(.-)%s*$", "%1")
        self:ClearFocus()
        if query ~= "" then UI.PrintSearch(query) end
    end)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    Tip(searchBox, "Search the catalogue", "Item, instance or boss name (or an item ID), then Enter.", "Results are listed in the chat frame.")

    -- progress / status bar
    ui.progress = CreateFrame("Frame", nil, content, "BackdropTemplate")
    ui.progress:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -38)
    ui.progress:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -38)
    ui.progress:SetHeight(18)
    SetBox(ui.progress, { 0.03, 0.035, 0.045, 0.7 }, COLOR.edge)
    ui.progressFill = ui.progress:CreateTexture(nil, "ARTWORK")
    ui.progressFill:SetPoint("TOPLEFT", ui.progress, "TOPLEFT", 1, -1)
    ui.progressFill:SetPoint("BOTTOMLEFT", ui.progress, "BOTTOMLEFT", 1, 1)
    ui.progressFill:SetWidth(1)
    ui.progressFill:SetColorTexture(COLOR.accent[1], COLOR.accent[2], COLOR.accent[3], 0.85)
    ui.status = ui.progress:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.status:SetPoint("LEFT", ui.progress, "LEFT", 8, 0)
    ui.status:SetPoint("RIGHT", ui.progress, "RIGHT", -8, 0)
    ui.status:SetJustifyH("LEFT")
    ui.status:SetWordWrap(false)

    -- equipment panel
    local equipment = Panel(content, 8, -64, 346, 502, "EQUIPMENT")
    for i, slot in ipairs(LEFT_SLOTS) do
        cards[slot] = CreateSlotCard(equipment, SLOT_BY_KEY[slot], 8, -34 - (i - 1) * 52)
    end
    for i, slot in ipairs(RIGHT_SLOTS) do
        cards[slot] = CreateSlotCard(equipment, SLOT_BY_KEY[slot], 180, -34 - (i - 1) * 52)
    end

    -- alternatives panel
    local list = Panel(content, 360, -64, 388, 502, "UPGRADES")
    ui.listPanel = list
    ui.listTitle = list.title
    ui.listTitle:SetWidth(130)

    -- per-instance filters, in the panel header: [Loot: All/Boss/Trash] [Dungeon: All / one instance]
    local function SmallButton(text, width, onClick)
        local b = Button(list, text, width, onClick)
        b:SetHeight(20)
        if b:GetFontString() then b:GetFontString():SetWidth(width - 12); b:GetFontString():SetWordWrap(false) end
        return b
    end
    ui.dungeonButton = SmallButton("All instances", 150, function(self, mouseButton)
        local list = GF.API.GetInstanceList()
        local current = GF.API.GetInstanceFilter()
        if mouseButton ~= "RightButton" and _G.MenuUtil and MenuUtil.CreateContextMenu then
            local ok = pcall(MenuUtil.CreateContextMenu, self, function(_, root)
                root:CreateTitle("Show upgrades from")
                root:CreateRadio("All instances", function() return current == nil end, function() GF.API.SetInstanceFilter(nil) end)
                local lastRaid
                for _, inst in ipairs(list) do
                    if inst.isRaid ~= lastRaid then root:CreateDivider(); root:CreateTitle(inst.isRaid and "Raids" or "Dungeons"); lastRaid = inst.isRaid end
                    local label = inst.name .. (inst.min and ("  |cff888888" .. inst.min .. "+|r") or "")
                    root:CreateRadio(label, function() return current == inst.key end, function() GF.API.SetInstanceFilter(inst.key) end)
                end
            end)
            if ok then return end
        end
        -- fallback (no menu API) and right-click: step through the list
        local index = 0
        for i, inst in ipairs(list) do if inst.key == current then index = i end end
        index = index + (mouseButton == "RightButton" and -1 or 1)
        if index > #list then index = 0 elseif index < 0 then index = #list end
        GF.API.SetInstanceFilter(index > 0 and list[index].key or nil)
    end)
    ui.dungeonButton:SetPoint("TOPRIGHT", list, "TOPRIGHT", -6, -4)
    Tip(ui.dungeonButton, "Instance", "Left click: pick one dungeon or raid (or all of them).", "Right click: step back through the list.",
        "Combined with the Loot button you see e.g. only the boss drops of one dungeon.")

    ui.lootButton = SmallButton("Loot: All", 92, function(_, mouseButton)
        local mode = GF.API.GetLootFilter()
        local order = { "all", "boss", "trash", "quest" }
        local i = 1
        for n, m in ipairs(order) do if m == mode then i = n end end
        i = i + (mouseButton == "RightButton" and -1 or 1)
        if i > #order then i = 1 elseif i < 1 then i = #order end
        GF.API.SetLootFilter(order[i])
    end)
    ui.lootButton:SetPoint("RIGHT", ui.dungeonButton, "LEFT", -4, 0)
    Tip(ui.lootButton, "Loot type", "Click to cycle: All → Boss drops → Trash drops → Quest rewards.",
        "Trash = drops from normal mobs in the instance (not tied to a boss).")
    for i = 1, ROW_COUNT do rows[i] = CreateRow(list, i) end
    ui.scrollText = Text(list, "GameFontDisableSmall", 10, -34 - ROW_COUNT * ROW_HEIGHT - 2, 368, "CENTER", COLOR.dim)
    ui.emptyText = list:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.emptyText:SetPoint("TOPLEFT", list, "TOPLEFT", 24, -150)
    ui.emptyText:SetPoint("TOPRIGHT", list, "TOPRIGHT", -24, -150)
    ui.emptyText:SetJustifyH("CENTER")
    ui.emptyText:SetWordWrap(true)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        scrollOffset = scrollOffset - delta
        UI.Refresh()
    end)

    -- overview panel
    local overview = BuildOverview(content)
    overview:SetPoint("TOPLEFT", content, "TOPLEFT", 754, -64)
    overview:SetSize(218, 502)

    window:SetScript("OnShow", function() UI.Refresh() end)
    GF.API.RecalculateCached()
    UI.Refresh()
end

function UI.Refresh()
    if not window or not content then return end
    local profile = GF.Specializations.GetProfile()
    local info = GF.Catalog.GetInfo()
    local recs = GF.API.GetRecommendations()
    local loading = GF.State.loading

    ui.specButton:SetText("Spec: " .. profile.specName .. (profile.auto and "  [AUTO]" or "  [MANUAL]"))
    local source = GF.API.GetSourceFilter()
    ui.sourceButton:SetText("Source: " .. (source == "dungeon" and "Dungeons" or (source == "raid" and "Raids" or "All")))
    local ahead = GF.API.GetLevelAhead()
    ui.levelButton:SetText(ahead == 0 and "Level: now" or (ahead >= 99 and "Level: any" or ("Level: +" .. ahead)))
    local loot = GF.API.GetLootFilter()
    ui.lootButton:SetText(loot == "boss" and "Loot: Boss" or (loot == "trash" and "Loot: Trash" or (loot == "quest" and "Loot: Quest" or "Loot: All")))
    local instKey = GF.API.GetInstanceFilter()
    local instName = instKey and GF.API.instances[instKey] and GF.API.instances[instKey].name or "All instances"
    if #instName > 20 then instName = instName:sub(1, 19) .. "…" end
    ui.dungeonButton:SetText(instName)
    ui.pinsButton:SetText("Map pins: " .. (GF.UI.MapPins.IsEnabled() and "On" or "Off"))
    if GF.UI.MapPins.Update then GF.UI.MapPins.Update() end
    if loading then ui.refreshButton:SetText("Loading…"); ui.refreshButton:Disable()
    else ui.refreshButton:SetText("Refresh"); ui.refreshButton:Enable() end
    ui.status:SetText(GF.State.status or "")
    UpdateProgress()

    -- selected slot: default to the first slot that has something to show
    if not selectedSlot or not SLOT_BY_KEY[selectedSlot] then selectedSlot = "Head" end
    local anyFirst
    for _, def in ipairs(SLOT_DEFS) do
        if (recs[def.key] and #recs[def.key] > 0) then anyFirst = anyFirst or def.key end
    end
    if anyFirst and not window.slotChosenOnce and not (recs[selectedSlot] and #recs[selectedSlot] > 0) then
        selectedSlot = anyFirst
    end

    local store = GetSelectionStore()
    for slot, card in pairs(cards) do
        local alternatives = recs[slot] or {}
        local chosenID = tonumber(store[slot])
        local index, candidate = 0, nil
        if #alternatives > 0 then
            index = 1
            if chosenID then
                for i, option in ipairs(alternatives) do
                    if tonumber(option.id) == chosenID then index = i break end
                end
            end
            candidate = alternatives[index]
        end
        UpdateSlotCard(card, candidate, alternatives, index)
    end

    local alternatives = recs[selectedSlot] or {}
    local def = SLOT_BY_KEY[selectedSlot]
    ui.listTitle:SetText(def and def.label:upper() or "UPGRADES")
    UpdateRows(alternatives)
    if #alternatives == 0 then
        local message
        if not info.hasScan and info.learned == 0 then
            message = "No data yet.\n\nPress |cffffd24dRefresh|r to read every dungeon and raid from the game's Encounter Journal. It takes a few seconds and is saved for next time."
        elseif loading then
            message = "Reading data…"
        else
            message = "No upgrade for this slot with the current filters.\n\nTry |cffffd24dLevel: +5|r, |cffffd24dSource: All|r, |cffffd24dLoot: All|r, |cffffd24dAll instances|r, or another talent tree."
        end
        ui.emptyText:SetText(message)
        ui.emptyText:Show()
    else
        ui.emptyText:Hide()
    end

    -- overview
    ui.ovChar:SetText((profile.className or "?") .. " " .. tostring(profile.level) .. " • " .. ((UnitName and UnitName("player")) or "Player"))
    ui.ovSpec:SetText(profile.specName .. " • " .. tostring(profile.totalTalentPoints) .. " pts")
    ui.ovArmor:SetText(GF.ItemFilter.WearableText(profile))
    ui.ovBest:SetText(GF.State.bestDungeon or (info.hasScan and "No upgrade in the catalogue" or "Press Refresh"))
    ui.ovUpg:SetText(tostring(GF.State.totalUpgrades or 0) .. " slot(s) with a candidate")
    ui.ovCat:SetText(tostring(info.items) .. " items • " .. tostring(info.dungeons) .. " dungeons • " .. tostring(info.raids) .. " raids" ..
        (info.learned > 0 and ("\n+ " .. info.learned .. " learned from your drops") or ""))
    if info.time and info.time > 0 and date then
        local text = date("%Y-%m-%d %H:%M", info.time)
        local saved = GearfinderDB and GearfinderDB.catalog
        if saved and saved.build then text = text .. "  •  build " .. tostring(saved.build) end
        if info.outdated then text = text .. "\n|cffffa033new client build: press Refresh|r" end
        ui.ovRefresh:SetText(text)
    else
        ui.ovRefresh:SetText("never")
    end
    local spec = GF.SpecProfiles[profile.class] and GF.SpecProfiles[profile.class][profile.scoreIndex or profile.specIndex]
    ui.ovPriority:SetText(spec and spec.priority or "Assign talents or select a profile.")
    ui.ovNote:SetText("Shift-click an upgrade to link it in chat.\nClient details: /gf info")
end

function UI.PrintSearch(query)
    local results = GF.API.Search(query) or {}
    if #results == 0 then
        print("|cffd9b15fGearfinder|r no catalogue item matches '" .. tostring(query) .. "'.")
        return
    end
    local shown = math.min(12, #results)
    print("|cffd9b15fGearfinder|r search '" .. tostring(query) .. "': " .. #results .. " match(es), showing " .. shown .. ":")
    for i = 1, shown do
        local item = results[i]
        local ilvl = (tonumber(item.itemLevel) or 0) > 0 and (" • i" .. item.itemLevel) or ""
        print("  |cffffff00" .. tostring(item.name) .. "|r (#" .. tostring(item.id) .. ")" .. ilvl .. " — " .. tostring((item.sources or {})[1] or "?"))
    end
    if #results > shown then print("  …and " .. (#results - shown) .. " more. Refine the search to narrow it.") end
end

function UI.Toggle()
    if not window then UI.Create() end
    if window:IsShown() then window:Hide() else window:Show() end
end

function UI.CreateCharacterButton()
    local CharacterFrame = _G.CharacterFrame
    if not CharacterFrame or CharacterFrame.GearfinderButton then return end
    local button = CreateFrame("Button", "GearfinderCharacterButton", CharacterFrame, "UIPanelButtonTemplate")
    button:SetSize(90, 22)
    button:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -10, 6)
    button:SetText("Gearfinder")
    button:SetFrameLevel(CharacterFrame:GetFrameLevel() + 10)
    button:SetScript("OnClick", function() UI.Toggle() end)
    Tip(button, "Gearfinder", "Open the dungeon and raid gear planner.")
    CharacterFrame.GearfinderButton = button
end
