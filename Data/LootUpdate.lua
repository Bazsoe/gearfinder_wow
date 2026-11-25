-- Fresh loot for the new WoW Forever dungeons: item IDs and sources as published by timesaver.gg
-- (13 Nov 2026), plus Krol'dok Stronghold and City of Dalaran from mmonster.co (25 Nov 2026). Merged on top of the built-in catalogue at load; trash mobs are grouped
-- as "Trash / other drops", quest rewards keep their quest name and faction.
local GF = Gearfinder
GF.Data = GF.Data or {}
GF.Data.LootUpdate = {
  date = "2026-11-25",
  instances = {
    { name = "The Drowned City", min = 30, max = 37, new = true, items = {
        { 274603, "Captain Dreadrise" }, -- Dreadfrost Saber
        { 274604, "Captain Dreadrise" }, -- Frosty Blunderbuss
        { 274605, "Captain Dreadrise" }, -- Briny Sash
        { 274614, "Deathless Marrow" }, -- Knucklebone Ring
        { 274607, "Deathless Marrow" }, -- Viscera Spaulders
        { 274606, "Deathless Marrow" }, -- Bloodspine Staff
        { 274608, "Min'loth the Serpent" }, -- Maw of Min'loth
        { 274609, "Min'loth the Serpent" }, -- Serpentbane Crown
        { 274610, "Min'loth the Serpent" }, -- Ritual-Binder's Gloves
        { 274611, "Primeval Elemental" }, -- Robe of the Drowned
        { 274612, "Primeval Elemental" }, -- Waterlogged Burial Shroud
        { 274615, "Primeval Elemental" }, -- Heart of the Primeval
        { 274601, "Var'Taka" }, -- Harpoon of Command
        { 274602, "Var'Taka" }, -- Brinebelly Leggings
        { 274613, "Var'Taka" }, -- Priestess Cloak
        { 274598, "Zul'Alai" }, -- Bloodslash Axe
        { 274599, "Zul'Alai" }, -- Oathbound Bracers
        { 274600, "Zul'Alai" }, -- Berserker Shackles
        { 286649, "Gill (Rare)" }, -- Tidebound Dagger
        { 286646, "Gill (Rare)" }, -- Gill's Gills
        { 286658, "Umbra (Rare)" }, -- Umbral Scaled Belt
        { 286662, "Umbra (Rare)" }, -- Deep-Dweller's Grips
        { 287002, "Trash / other drops" }, -- Risen Sentry's Links
        { 279930, "Quest: Shady Saltseers" }, -- Saltseer's Helm
        { 279882, "Quest: Shady Saltseers" }, -- Rusted Troll War Belt
        { 279889, "Quest: The Only Good Brinescale... (Horde)" }, -- Naga Priestess's Mantle
        { 279888, "Quest: The Only Good Brinescale... (Horde)" }, -- Tidesoaked Leggings
        { 279883, "Quest: The Saltseer Captain" }, -- Mutinous Cuffs
        { 279884, "Quest: The Saltseer Captain" }, -- South Seas Shroud
    } },
    { name = "Alcaz Prison", min = 44, max = 50, new = true, items = {
        { 276744, "Blazeroar" }, -- Zarla's Snack Pouch
        { 276746, "Blazeroar" }, -- Defias Enforcer's Legguards
        { 276745, "Blazeroar" }, -- Beastbond Robe
        { 276738, "Katerina the Cleaner" }, -- Katerina's Shanker
        { 276739, "Katerina the Cleaner" }, -- Cutthroat Chestguard
        { 276740, "Katerina the Cleaner" }, -- Sentimental Locket
        { 276732, "Overseer Wrex" }, -- Alcaz Willcrusher
        { 276734, "Overseer Wrex" }, -- Wrex's Pinky Ring
        { 276733, "Overseer Wrex" }, -- Grips of Control
        { 276741, "The Questioner" }, -- Defias Enforcer's Shoulderpads
        { 276742, "The Questioner" }, -- Girdle of Extracted Answers
        { 276743, "The Questioner" }, -- Fingerbreaker Stamp
        { 276735, "Tidemistress Ca'zass" }, -- Tidesong Wand
        { 276737, "Tidemistress Ca'zass" }, -- Cloak of the Tidemistress
        { 276736, "Tidemistress Ca'zass" }, -- Seascale Bracers
        { 14267, "Trash / other drops" }, -- Bloodwoven Jerkin
        { 287023, "Trash / other drops" }, -- Iron-Wrought Cuffs
        { 13089, "Trash / other drops" }, -- Skibi's Pendant
        { 15639, "Trash / other drops" }, -- Ironhide Bracers
        { 287024, "Trash / other drops" }, -- Mark of Captivity
        { 287025, "Trash / other drops" }, -- Enchantresses' Spire
        { 15642, "Trash / other drops" }, -- Ironhide Greaves
        { 15388, "Trash / other drops" }, -- Jadefire Belt
        { 15622, "Trash / other drops" }, -- Gryphon Mail Breastplate
        { 279829, "Quest: A Bit of Wet Work (Alliance)" }, -- Naga Scale Spaulders
        { 279826, "Quest: A Bit of Wet Work (Alliance)" }, -- Marshdweller's Pants
        { 279825, "Quest: A Bit of Wet Work (Alliance)" }, -- Theramore Defender's Gauntlets
        { 279829, "Quest: A Little Payback (Horde)" }, -- Naga Scale Spaulders
        { 279826, "Quest: A Little Payback (Horde)" }, -- Marshdweller's Pants
        { 279824, "Quest: A Little Payback (Horde)" }, -- Kor'kron Battle Gauntlets
        { 279448, "Quest: Blood Red Bandanas (Horde)" }, -- Bloodsplattered Bandana
        { 279473, "Quest: Blood Red Bandanas (Horde)" }, -- Makeshift Belt
        { 279831, "Quest: Thrall Needs to Know (Horde)" }, -- Fatebound Buckler
        { 279833, "Quest: Thrall Needs to Know (Horde)" }, -- Courier's Clasp
        { 279474, "Quest: Thrall Needs to Know (Horde)" }, -- Dustwallow Dirk
    } },
    { name = "Blackmaw Hold", min = 45, max = 57, new = true, items = {
        { 15390, "Trash / other drops" }, -- Jadefire Chestguard
        { 14938, "Trash / other drops" }, -- Heroic Bracers
        { 14930, "Trash / other drops" }, -- Lofty Shield
        { 15662, "Trash / other drops" }, -- Impenetrable Gauntlets
        { 287033, "Trash / other drops" }, -- Furbolg Berserker's Boots
        { 280059, "Bonesnout the Unbroken" }, -- Tuskblade Halberd
        { 280060, "Bonesnout the Unbroken" }, -- Lucky Shovelnose Tuft
        { 280061, "Bonesnout the Unbroken" }, -- Spike Crested Bracers
        { 280070, "Elder Shaman Bloodmane" }, -- Veilpiercer Girdle
        { 280069, "Elder Shaman Bloodmane" }, -- Shamanic Wristguards
        { 280068, "Elder Shaman Bloodmane" }, -- Bloody Claws of Attack
        { 280057, "Impaan the Imprisoner" }, -- Robes of Dark Summons
        { 280058, "Impaan the Imprisoner" }, -- Impish Chain Hood
        { 280056, "Impaan the Imprisoner" }, -- Flameslash Crescent
        { 280073, "Unbound Spirit" }, -- Burnished Pridescales
        { 280072, "Unbound Spirit" }, -- Cowl of Dark Ambition
        { 280071, "Unbound Spirit" }, -- Flamebreak Talisman
        { 280074, "Varrox Bleakhoof" }, -- Scalding Flamehoof
        { 280076, "Varrox Bleakhoof" }, -- Horns of Varrox
        { 280075, "Varrox Bleakhoof" }, -- Bleak Eye Shoulderplates
        { 280063, "Withermaw" }, -- Bloodfur Bulwark
        { 280064, "Withermaw" }, -- Withering Grips
        { 280062, "Withermaw" }, -- Cloak of the Fleshborer
        { 280080, "Moontouched Wanderer (Rare)" }, -- Claymore of Two Moons
        { 280079, "Moontouched Wanderer (Rare)" }, -- Lunarlight Robe
        { 280085, "Tunnelweb Matriarch (Rare)" }, -- Tunnelweb Pincer
        { 280086, "Tunnelweb Matriarch (Rare)" }, -- Octofinger Gauntlets
        { 13022, "Trash / other drops" }, -- Gryphonwing Long Bow
        { 15179, "Trash / other drops" }, -- Praetorian Padded Armor
        { 14857, "Trash / other drops" }, -- Vanguard Sabatons
        { 14855, "Trash / other drops" }, -- Vanguard Gauntlets
        { 12045, "Trash / other drops" }, -- Swamp Pendant
        { 279893, "Quest: A Lost Memento" }, -- Nama's Cherished Necklace
        { 260217, "Quest: Blackmaw Reclamation" }, -- Eagle's Head Signet
        { 260216, "Quest: Blackmaw Reclamation" }, -- Ouroboros Ring
        { 260219, "Quest: Blackmaw Reclamation" }, -- Engraved Band
        { 260218, "Quest: Blackmaw Reclamation" }, -- Malefactor's End
        { 260215, "Quest: Claws That Rend, Tusks that Gore" }, -- Wild Malleus
        { 260213, "Quest: Claws That Rend, Tusks that Gore" }, -- Great Bear Claw
        { 260214, "Quest: Claws That Rend, Tusks that Gore" }, -- Staff of Wild Beasts
        { 21316, "Quest: Deadwood of the North" }, -- Leggings of the Ursa
        { 21317, "Quest: Deadwood of the North" }, -- Helm of the Pathfinder
        { 15822, "Quest: Runecloth" }, -- Shadowskin Spaulders
        { 15823, "Quest: Runecloth" }, -- Bricksteel Gauntlets
        { 279892, "Quest: The Twin Bears" }, -- Wisdom of Ursol
        { 279891, "Quest: The Twin Bears" }, -- Guidance of Ursoc
        { 21318, "Quest: Winterfall Activity" }, -- Earth Warder's Gloves
        { 21319, "Quest: Winterfall Activity" }, -- Gloves of the Pathfinder
        { 21320, "Quest: Winterfall Activity" }, -- Vest of the Den Watcher
        { 21322, "Quest: Winterfall Activity" }, -- Ursa's Embrace
    } },
    { name = "The Shaper's Terrace", min = 55, max = 58, new = true, items = {
        { 280032, "Vitrix" }, -- Bolt's Charged Eyeball
        { 280027, "Vitrix" }, -- Crownroar Chestplate
        { 280026, "Vitrix" }, -- Albinofur Grips
        { 280028, "Cinder" }, -- Heartflame Gauntlets
        { 280029, "Cinder" }, -- Cinderedge Crescent
        { 279906, "Quest: Crystalline Elements (Horde)" }, -- Potent Treads
        { 279904, "Quest: Crystalline Elements (Horde)" }, -- Crystalline Pauldrons
        { 279931, "Quest: Digestible Research (Alliance)" }, -- Lost Researcher's Hood
        { 279901, "Quest: Digestible Research (Alliance)" }, -- Expeditionary Legplates
        { 279932, "Quest: Essence of Seeping Slimes (Horde)" }, -- Slime-Resistant Shroud
        { 279902, "Quest: Essence of Seeping Slimes (Horde)" }, -- Reinforced Muck Protectors
        { 279910, "Quest: Mapping the Way Forward (Alliance)" }, -- Beastslayer's Trident
        { 279908, "Quest: Mapping the Way Forward (Alliance)" }, -- Crystal-Infused Cleaver
        { 279912, "Quest: Mapping the Way Forward (Alliance)" }, -- Faintly Glowing Orb
        { 279903, "Quest: Panic at the Digsite (Alliance)" }, -- Diemetradon Scale Spaulders
        { 279905, "Quest: Panic at the Digsite (Alliance)" }, -- Ravasaur Hide Footpads
        { 279910, "Quest: The Dark Crystal (Horde)" }, -- Beastslayer's Trident
        { 279908, "Quest: The Dark Crystal (Horde)" }, -- Crystal-Infused Cleaver
        { 279912, "Quest: The Dark Crystal (Horde)" }, -- Faintly Glowing Orb
    } },
    { name = "Hall of Thanes", min = 9, max = 13, new = true, items = {
        { 270256, "Durgen Dirgehammer" }, -- Durgen's Crescent Axe
        { 270261, "Durgen Dirgehammer" }, -- Robes of the Disgraced Thane
        { 270260, "Durgen Dirgehammer" }, -- Direhammer Leggings
        { 270227, "Faldrim Anvilmar" }, -- Ephemeral Choker
        { 271097, "Faldrim Anvilmar" }, -- Spiritwraith Drape
        { 271096, "Faldrim Anvilmar" }, -- Aetherwisp Bracers
        { 271095, "Magmatus" }, -- Fang of Magmatus
        { 270231, "Magmatus" }, -- Flamefist Grips
        { 270230, "Magmatus" }, -- Kindlegem Girdle
        { 270228, "Plunder" }, -- Golemheart Stave
        { 271098, "Plunder" }, -- Golemguard Chest
        { 270229, "Plunder" }, -- Treads of the Protector Golem
        { 279899, "Quest: An Ancient Grudge" }, -- Catacomb Cloak
        { 279900, "Quest: An Ancient Grudge" }, -- Deepgrave Trousers
        { 279898, "Quest: Important Heirlooms (Alliance)" }, -- Dwarven Tome
        { 280096, "Quest: Important Heirlooms (Alliance)" }, -- Tomb Robber's Gloves
        { 279895, "Quest: Old Ironforge Incursion (Alliance)" }, -- Ironforge Greathammer
        { 279896, "Quest: Old Ironforge Incursion (Alliance)" }, -- Deepblaze
        { 279894, "Quest: Old Ironforge Incursion (Alliance)" }, -- Calibrated Blunderbuss
        { 279897, "Quest: The Restless Dead (Alliance)" }, -- Dusty Belt
        { 280095, "Quest: The Restless Dead (Alliance)" }, -- Cryptwalker Bracers
    } },
    { name = "Ruins of Lordaeron", min = 15, max = 19, new = true, items = {
        { 271209, "Bjork" }, -- Bonerust Leggings
        { 271210, "Bjork" }, -- Tuskwrap Belt
        { 271217, "Bjork" }, -- Corpse Chopper
        { 271214, "Rath'mael" }, -- Rotmender's Treads
        { 271213, "Rath'mael" }, -- Mirror of Rath'mael
        { 271215, "Rath'mael" }, -- Coldspire Staff
        { 271216, "The Abandoned" }, -- Scepter of the Abandoned
        { 271207, "The Abandoned" }, -- Rotmender's Leggings
        { 271208, "The Abandoned" }, -- Grip of Fear
        { 271206, "The Baron" }, -- Leftover Abomination Skin
        { 271205, "The Baron" }, -- Abomination Bones
        { 271204, "The Baron" }, -- Meathook Slicer
        { 271218, "Viktor the Vile" }, -- Vileblood Scimitar
        { 271212, "Viktor the Vile" }, -- Bloodied Chestwraps
        { 271211, "Viktor the Vile" }, -- Vilewalkers
        { 271202, "Witherfang" }, -- Witherbite Bracers
        { 271201, "Witherfang" }, -- Atrophic Girdle
        { 271203, "Witherfang" }, -- Segmented Spider Leg
        { 251486, "Quest: A Frightened Request (Horde)" }, -- Tabitha's Cuffs
        { 251485, "Quest: A Frightened Request (Horde)" }, -- Edward's Knife
        { 279867, "Quest: Abominable Creatures (Alliance)" }, -- Slain Baron's Signet
        { 279865, "Quest: Abominable Creatures (Alliance)" }, -- Grave Shroud
        { 279864, "Quest: Abominable Creatures (Alliance)" }, -- Monstrous Cleaver
        { 279868, "Quest: Bloodied Insignia (Alliance)" }, -- Duty Bound Leggings
        { 279869, "Quest: Bloodied Insignia (Alliance)" }, -- Remembrance Armor
        { 279875, "Quest: Light's Justice (Horde)" }, -- Spare Part Bindings
        { 279874, "Quest: Light's Justice (Horde)" }, -- The Stitcher
        { 279877, "Quest: The New Plague (Horde)" }, -- Blight Gloves
        { 279876, "Quest: The New Plague (Horde)" }, -- Plaguefang
        { 251533, "Quest: The Wrath of Rath'mael (Horde)" }, -- Forsaken Greataxe
        { 251534, "Quest: The Wrath of Rath'mael (Horde)" }, -- Gnarled Necromancer's Staff
    } },
    { name = "Excavation Site: Wetlands", min = 24, max = 28, new = true, items = {
        { 273028, "Relic Guardian" }, -- Reliquary Mantle
        { 273030, "Relic Guardian" }, -- Ring of Power Regulation
        { 273029, "Relic Guardian" }, -- Golemsight Long Gun
        { 273022, "Saltspine" }, -- Supple Bellyskin Leggings
        { 273024, "Saltspine" }, -- Glinteye Slippers
        { 273023, "Saltspine" }, -- Saltscale Girdle
        { 273026, "Shadetooth" }, -- Garb of Florid Feathers
        { 273027, "Shadetooth" }, -- Raptor's Gaze
        { 273025, "Shadetooth" }, -- Raptorclaw Greaves
        { 280805, "Quest: Changing Tastes (Horde)" }, -- Serrated Raptor Claw
        { 271766, "Quest: Earthen Echo (Horde)" }, -- Heavehammer
        { 271767, "Quest: Earthen Echo (Horde)" }, -- Healer's Staff
        { 271719, "Quest: Earthen Echo (Horde)" }, -- Furs of the Earthen Ring
        { 271769, "Quest: Fallen in the Fen (Alliance)" }, -- Daewyn's Girdle
        { 271768, "Quest: Fallen in the Fen (Alliance)" }, -- Songblade Stabilizer
        { 271664, "Quest: Horrors in the Highland (Alliance)" }, -- Hornbeam Heft
        { 271667, "Quest: Horrors in the Highland (Alliance)" }, -- Ironwood Destroyer
        { 271670, "Quest: Horrors in the Highland (Alliance)" }, -- Curl of Life
        { 271740, "Quest: Open the Maw (Horde)" }, -- Knife-Polishing Rag
        { 271732, "Quest: Open the Maw (Horde)" }, -- Dirt-Heavy Bracers
        { 271766, "Quest: Prehistoric Prism (Alliance)" }, -- Heavehammer
        { 271767, "Quest: Prehistoric Prism (Alliance)" }, -- Healer's Staff
        { 271716, "Quest: Prehistoric Prism (Alliance)" }, -- Explorer's League Dustcover
    } },
    { name = "Krol'dok Stronghold", min = 40, max = 45, new = true, items = {
        { 274996, "Slavecrusher Grox" }, -- Resistance Breaker Spaulder
        { 274997, "Slavecrusher Grox" }, -- Chain of Binding
        { 274995, "Slavecrusher Grox" }, -- Slavecrusher Scepter
        { 275000, "Twilight Commander Zarmok" }, -- Zarmok's Plated Signet
        { 274998, "Twilight Commander Zarmok" }, -- Shadowlight Athame
        { 274999, "Twilight Commander Zarmok" }, -- Shadecaster's Leggings
        { 275001, "War Handler Ashka" }, -- Bloodied Gutslicer
        { 275002, "War Handler Ashka" }, -- War Handler's Gaze
        { 275003, "War Handler Ashka" }, -- Worgbinder's Treads
        { 275004, "Nar'gurk" }, -- Chain of the Corruptor
        { 275005, "Nar'gurk" }, -- Krol'dok Warplate Chest
        { 275006, "Nar'gurk" }, -- Krol'dok Warplate Helmet
        { 275009, "Overlord Mugg" }, -- Emblem of Slamming
        { 275007, "Overlord Mugg" }, -- Mugg's Jabber
        { 275010, "Overlord Mugg" }, -- Strongly Scented Hood
        { 275008, "Overlord Mugg" }, -- Mugg's Crosser
        { 279852, "Quest: Eye of Mugg" }, -- Rock on Stick
        { 279853, "Quest: Eye of Mugg" }, -- Stick No Rock
        { 279480, "Quest: Eye of Mugg" }, -- Bigger Rock on Bigger Stick
        { 279854, "Quest: Tome of Twilight (Alliance)" }, -- Twilight Initiate's Belt
        { 279855, "Quest: Tome of Twilight (Alliance)" }, -- Torn Cultist Cloak
        { 279859, "Quest: Tome of Twilight (Horde)" }, -- Indoctrinated Choker
        { 279860, "Quest: Tome of Twilight (Horde)" }, -- Convert's Bindings
        { 267090, "Quest: A Token of Vengeance (Horde)" }, -- Semblance of Twilight
        { 279850, "Quest: Curios of Curiosity (Alliance)" }, -- Curio-Adorned Necklace
    } },
    { name = "City of Dalaran", min = 28, max = 34, new = true, items = {
        { 273036, "Atrexis the Grave Knight" }, -- Graveweave Bindings
        { 273032, "Atrexis the Grave Knight" }, -- Bonebinder's Signet
        { 273033, "Atrexis the Grave Knight" }, -- Gravespike Repeater
        { 273034, "Arcane Anomaly" }, -- Ephemeral Grips
        { 273031, "Arcane Anomaly" }, -- Runemender's Seal
        { 273035, "Arcane Anomaly" }, -- Mana-Warped Chain Shirt
        { 273041, "Mana Devourer" }, -- Slitherwrap Girdle
        { 273042, "Mana Devourer" }, -- Manascale Treads
        { 273040, "Mana Devourer" }, -- Spine of the Devourer
        { 273038, "Fel Ancient" }, -- Garb of Fallen Felbark
        { 273039, "Fel Ancient" }, -- Blightleaf Rope
        { 273037, "Fel Ancient" }, -- Felbough Arm
        { 273047, "Unstable Sentinel" }, -- Unstable Crystalline Shoulderpads
        { 273046, "Unstable Sentinel" }, -- Guardian's Dualblade
        { 273048, "Unstable Sentinel" }, -- Refractory Scaleguards
        { 273045, "Arcanic Enigma" }, -- Drape of Shifting Energy
        { 273044, "Arcanic Enigma" }, -- Violet Sorcerer's Robes
        { 273043, "Arcanic Enigma" }, -- Wand of Mana Concentration
        { 273049, "Shade of the Archmage" }, -- Archmagister's Faceted Pendant
        { 273051, "Shade of the Archmage" }, -- Violet Sorcerer's Mantle
        { 273052, "Shade of the Archmage" }, -- Ponderous Orb
        { 273054, "Lyn the Ignored" }, -- Cartilage Shapers
        { 273055, "Lyn the Ignored" }, -- Bonepile Gaze
        { 273053, "Lyn the Ignored" }, -- Tendonscraper Dagger
        { 279839, "Quest: Heart of Disruption (Alliance)" }, -- Spellguard Pauldrons
        { 279840, "Quest: Heart of Disruption (Alliance)" }, -- Renewing Footpads
        { 279841, "Quest: Heart of Disruption (Alliance)" }, -- Defender of Dalaran
        { 279837, "Quest: Starving Arcane (Alliance)" }, -- Fallen Guard's Pendant
        { 279838, "Quest: Starving Arcane (Alliance)" }, -- Arcane Infused Rod
        { 251962, "Quest: Power Overwhelming (Alliance)" }, -- Violet Sash
        { 279849, "Quest: Power Overwhelming (Alliance)" }, -- Runebound Gloves
        { 279835, "Quest: A Green Sample (Alliance)" }, -- Vine Pruner's Cloak
        { 279836, "Quest: A Green Sample (Alliance)" }, -- Thorn Protecting Girdle
        { 279842, "Quest: Heart of Disruption (Horde)" }, -- Battle Spaulders
        { 279843, "Quest: Heart of Disruption (Horde)" }, -- Enchanted Sandals
        { 279844, "Quest: Heart of Disruption (Horde)" }, -- Striking Staff
        { 251963, "Quest: The Grave Knight (Horde)" }, -- Gravewalker Boots
        { 251965, "Quest: The Grave Knight (Horde)" }, -- Undead Knight's Bracers
        { 279847, "Quest: Source of Power (Horde)" }, -- Unstable Power Core
        { 279848, "Quest: Source of Power (Horde)" }, -- Construct Cloak
        { 279845, "Quest: Opportunistic Education (Horde)" }, -- Solid Gold Band
        { 279846, "Quest: Opportunistic Education (Horde)" }, -- Larcenist's Belt
    } },
  },
}
