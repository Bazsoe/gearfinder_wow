local GF = Gearfinder
GF.UI.ItemTooltip = {}

function GF.UI.ItemTooltip.Show(owner, item, alternativeIndex, alternativeCount)
    if not GameTooltip or not owner then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    if not item then
        GameTooltip:AddLine("No upgrade found for this slot", 1, 0.82, 0)
        GameTooltip:AddLine("Press Refresh to read the live dungeon and raid loot, or relax the filters.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
        return
    end
    local shown = false
    local link = item.link or ("item:" .. tostring(item.id))
    if GameTooltip.SetHyperlink then shown = pcall(GameTooltip.SetHyperlink, GameTooltip, link) end
    if not shown then GameTooltip:AddLine(item.name or "Unknown item", 1, 0.82, 0) end

    GameTooltip:AddLine(" ")
    if alternativeCount and alternativeCount > 1 and alternativeIndex and alternativeIndex > 0 then
        GameTooltip:AddLine("Alternative " .. tostring(alternativeIndex) .. " of " .. tostring(alternativeCount), 1, 0.82, 0)
    end
    if item.sources and #item.sources > 0 then
        GameTooltip:AddLine("Drops from", 0.7, 0.9, 1)
        for i = 1, math.min(4, #item.sources) do GameTooltip:AddLine(item.sources[i], 0.82, 0.88, 0.94, true) end
        if #item.sources > 4 then GameTooltip:AddLine("…and " .. (#item.sources - 4) .. " more source(s)", 0.65, 0.65, 0.65) end
    end
    if item.locked then GameTooltip:AddLine("This content opens on December 9 (Forever roadmap).", 1, 0.82, 0.3, true) end
    if item.specProfile then
        GameTooltip:AddLine("Build: " .. item.specProfile.name, 0.4, 1, 0.4, true)
    end
    GameTooltip:AddLine("Gearfinder score: " .. string.format("%.2f", item.score or 0), 0.4, 1, 0.4)
    if item.delta then
        GameTooltip:AddLine("Compared with equipped gear: " .. (item.delta >= 0 and "+" or "") .. string.format("%.2f", item.delta),
            item.delta >= 0 and 0.4 or 1, item.delta >= 0 and 1 or 0.4, 0.4)
    end
    if item.breakdown and #item.breakdown > 0 then
        GameTooltip:AddLine("Score breakdown", 1, 0.82, 0)
        for i = 1, math.min(5, #item.breakdown) do
            local stat = item.breakdown[i]
            GameTooltip:AddDoubleLine(stat.label, string.format("%g × %.2f = %.2f", stat.amount, stat.weight, stat.contribution), 0.9, 0.9, 0.9, 0.4, 1, 0.4)
        end
    end
    GameTooltip:AddLine("Shift-click to link in chat. Estimated score, not a simulator.", 0.65, 0.65, 0.65, true)
    GameTooltip:Show()
end

function GF.UI.ItemTooltip.Hide()
    if GameTooltip then GameTooltip:Hide() end
end
