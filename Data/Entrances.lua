-- Built-in FALLBACK entrance positions (zone-map coordinates, 0..1). These are approximate and are only
-- used when neither the game's own entrance data nor an entrance you have walked into yourself is
-- available for that map. Zones are matched by NAME (not map ID), so they work whatever IDs the client
-- uses. New Forever dungeons are listed only where two or more public guides agree; the rest appear on the
-- map as soon as the game reports them or you enter them once.
local GF = Gearfinder
GF.Data = GF.Data or {}
GF.Data.Entrances = {
    -- New in Forever
    { name = "Hall of Thanes",          zone = "Ironforge",           x = 0.435, y = 0.520 },
    { name = "Blackmaw Hold",           zone = "Azshara",             x = 0.387, y = 0.334 },
    -- Classic dungeons
    { name = "Ragefire Chasm",          zone = "Orgrimmar",           x = 0.520, y = 0.490 },
    { name = "Wailing Caverns",         zone = "The Barrens",         x = 0.464, y = 0.364 },
    { name = "Deadmines",               zone = "Westfall",            x = 0.430, y = 0.720 },
    { name = "Shadowfang Keep",         zone = "Silverpine Forest",   x = 0.448, y = 0.678 },
    { name = "Blackfathom Deeps",       zone = "Ashenvale",           x = 0.142, y = 0.142 },
    { name = "Stormwind Stockade",      zone = "Stormwind City",      x = 0.406, y = 0.558 },
    { name = "Razorfen Kraul",          zone = "The Barrens",         x = 0.408, y = 0.904 },
    { name = "Gnomeregan",              zone = "Dun Morogh",          x = 0.312, y = 0.386 },
    { name = "Scarlet Monastery",       zone = "Tirisfal Glades",     x = 0.850, y = 0.308 },
    { name = "Razorfen Downs",          zone = "The Barrens",         x = 0.495, y = 0.945 },
    { name = "Uldaman",                 zone = "Badlands",            x = 0.424, y = 0.126 },
    { name = "Zul'Farrak",              zone = "Tanaris",             x = 0.390, y = 0.210 },
    { name = "Maraudon",                zone = "Desolace",            x = 0.292, y = 0.628 },
    { name = "Temple of Atal'Hakkar",   zone = "Swamp of Sorrows",    x = 0.696, y = 0.539 },
    { name = "Blackrock Depths",        zone = "Searing Gorge",       x = 0.350, y = 0.845 },
    { name = "Lower Blackrock Spire",   zone = "Searing Gorge",       x = 0.350, y = 0.845 },
    { name = "Dire Maul",               zone = "Feralas",             x = 0.625, y = 0.306 },
    { name = "Scholomance",             zone = "Western Plaguelands", x = 0.698, y = 0.728 },
    { name = "Stratholme",              zone = "Eastern Plaguelands", x = 0.310, y = 0.155 },
    -- Raids
    { name = "Molten Core",             zone = "Searing Gorge",       x = 0.350, y = 0.845, raid = true },
    { name = "Blackwing Lair",          zone = "Searing Gorge",       x = 0.350, y = 0.845, raid = true },
    { name = "Onyxia's Lair",           zone = "Dustwallow Marsh",    x = 0.529, y = 0.770, raid = true },
    { name = "Zul'Gurub",               zone = "Stranglethorn Vale",  x = 0.537, y = 0.174, raid = true },
    { name = "Ruins of Ahn'Qiraj",      zone = "Silithus",            x = 0.286, y = 0.924, raid = true },
    { name = "Temple of Ahn'Qiraj",     zone = "Silithus",            x = 0.286, y = 0.924, raid = true },
    { name = "Naxxramas",               zone = "Eastern Plaguelands", x = 0.395, y = 0.260, raid = true },
}
