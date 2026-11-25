-- Gearfinder scoring: canonical stats x per-spec weights.
local GF = Gearfinder
GF.BiSScoring = {}

local FALLBACK = { STR = 0.2, AGI = 0.2, INT = 0.2, STA = 0.15 }

local function WeightsFor(profile)
    local profiles = GF.SpecProfiles[profile.class]
    local specProfile = profiles and profiles[profile.scoreIndex or profile.specIndex]
    return (specProfile and specProfile.weights) or FALLBACK, specProfile
end

function GF.BiSScoring.Score(item, profile)
    local weights, specProfile = WeightsFor(profile)
    local stats = item.stats or {}
    local score, contributions, weightedStatCount = 0, {}, 0
    for key, weight in pairs(weights) do
        local amount = tonumber(stats[key]) or 0
        if amount ~= 0 and weight ~= 0 then
            local value = amount * weight
            score = score + value
            weightedStatCount = weightedStatCount + 1
            contributions[#contributions + 1] = {
                key = key, label = GF.StatLabels[key] or key,
                amount = amount, weight = weight, contribution = value,
            }
        end
    end
    local itemLevel = tonumber(item.itemLevel) or 0
    local hasUsefulStats = weightedStatCount > 0
    local confidence = hasUsefulStats and "Estimated from live client stats" or "No stats match this build"
    if hasUsefulStats then score = score + itemLevel * 0.015 else score = itemLevel * 0.04 end
    table.sort(contributions, function(a, b) return a.contribution > b.contribution end)
    return score, contributions, specProfile, confidence, hasUsefulStats
end

-- Score of an equipped item link (local data only, never requests anything from the server).
function GF.BiSScoring.ScoreLink(link, profile)
    if not link then return nil end
    local weights = WeightsFor(profile)
    local stats = GF.Stats.FromLink(link)
    local itemID = tonumber(tostring(link):match("item:(%d+)"))
    local known = itemID and GF.API and GF.API.itemCache and GF.API.itemCache[itemID] or nil
    local itemLevel = known and tonumber(known.itemLevel) or 0
    if next(stats) == nil and known and type(known.stats) == "table" then stats = known.stats end
    local score = 0
    for key, weight in pairs(weights) do score = score + (tonumber(stats[key]) or 0) * weight end
    return score + itemLevel * 0.015
end
