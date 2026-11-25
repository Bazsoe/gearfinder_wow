GEARFINDER 2.14.0 — WOW FOREVER (1.60.1, Interface 16001)
=========================================================

MI EZ?
Dungeon- ÉS raid-gear tervező a WoW Foreverhez, talentfa-tudatos pontozással.
A TBC-s adatbázis teljesen ki lett véve: az adatot az addon a játék saját
Encounter Journaljából (Adventure Guide) olvassa, ezért az új Forever
instákat (Hall of Thanes, Ruins of Lordaeron, Excavation Site, City of Dalaran,
Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold, Shaper's
Terrace) és a raidket (Barrow Deeps, Hyjal Summit, Onyxia, MC, BWL, ZG, AQ,
Naxx) azonnal tudja, amint a kliens listázza őket.

REALTIME — A REFRESH GOMBRA
- Semmi nem fut időzítőn vagy másodpercenként. Az Encounter Journal
  kiolvasása és az itemek lekérdezése CSAK a Refresh gomb megnyomásakor történik.
- Az eredmény mentésre kerül (fiókszinten), így belépéskor azonnal ott van a lista.
- Ha a játék build száma változik, az Overview panel jelzi: nyomj Refresht.
- Tanult dropok: ha dungeonban/raidben lootolsz, az addon megjegyzi az itemet és
  a forrását (ha a journal még nem listázta). Ez csak loot-eseményre fut.

ELSŐ HASZNÁLAT
1. Másold a Gearfinder mappát a Forever kliens Interface/AddOns/ könyvtárába.
2. Játékban kattints a minimap ikonra (vagy a Character ablak Gearfinder
   gombjára), majd nyomd meg a Refresh gombot. Pár másodperc.
3. Slot kártyára kattintva a középső panelen a rangsorolt alternatívák látszanak
   (egérgörgővel görgethető). Kattintás = kiválasztás, Shift+kattintás = chat link.

FELÜLET
- Eszköztár: Spec (talentfa-profil), Source (Mind / Dungeon / Raid),
  Level (most / +5 szint / bármely), keresés, i (kliens- és adatinfo), Refresh.
- EQUIPMENT: slotonként a kiválasztott javaslat, minőségszínnel és pontkülönbséggel.
- UPGRADES: rangsorolt alternatívák; tag-ek: RAID méret, NEW in Forever,
  "opens Dec 9" (a roadmap szerint ekkor nyílik Barrow Deeps, Hyjal Summit, Onyxia).
- OVERVIEW: karakter, talentfa, legjobb következő insta, katalógus-statisztika.
- Térkép-pinek: a világtérképen a dungeon- és raid-bejáratok PONTOS helyén
  pin jelenik meg (a játék saját bejárat-adataiból, ugyanonnan, ahonnan az Adventure
  Guide), a rajta lévő szám az ott kapható upgrade-slotok száma. Egérrel fölé:
  instainfó és a legjobb itemek; bal klikk: Gearfinder; jobb klikk: waypoint.
  A Map pins gombbal ki/be kapcsolható.
- Minimap ikon: bal klikk ablak, jobb klikk info, húzással áthelyezhető.

FOREVER-SPECIFIKUS
- Talentrendszer: 3 fa, 7 sor. Az addon a C_SpecializationInfo-ból olvassa a
  fánkénti pontokat (AUTO), de kézzel is választhatsz profilt.
- Statok: a Hit és a Crit egy közös stat (10 rating = 1% hit, 14 rating = 1% crit
  60-as szinten), a Bonus Healing 1/3 Bonus Damage-et is ad. Az addon a statokat
  a klienstől kéri (C_Item.GetItemStats), és az API-ban nem szereplő "Equip:"
  hatásokat a tooltipből olvassa (angol szövegminták; más nyelven az API-statok
  maradnak).

FONTOS / KORLÁTOK
- Élő Forever kliensen NEM volt kipróbálva (nincs hozzáférésem). Dokumentáció és
  szimulált környezet alapján készült. Ha valami nem jelenik meg, jobb klikk a
  minimap ikonra, és küldd el a kiírt információt.
- Ha az Encounter Journal egy instához még nem ad lootot (a Forever bétában
  előfordult), a "tanult dropok" idővel kitöltik.
- A pontozás becslés (talentfánkénti súlyozás), nem szimulátor. A hit/expertise
  capet, setbónuszokat és procokat nem modellezi.
- A raid-instákat a kliens listázza; a "opens Dec 9" jelzés a Blizzard roadmap
  dátumán alapul.

--- 2.2.0 ---
- Térkép-jelölők: natív kék "Dungeon" / zöld "Raid" ikon (Blizzard atlasz), ha nincs, a címer ikon a tartalék.
- Pozíció-források: 1) a játék saját adata (csak felfedezett bejáratok), 2) amit te magad bejártál (automatikusan megjegyzi),
  3) kis beépített, közelítő tábla (Data/Entrances.lua). A nem ismert helyek maguktól megjelennek, ha egyszer bemész.
- Ablak: átlátszó háttér, a panelek már nem lógnak ki (az ablak 990x642).
- Nem tudtam játékban tesztelni, a beépített koordináták közelítők.

--- 2.2.1 ---
- Új parancs: /gf probe (diagnosztika: mit ad vissza a Kalandnapló), /gf info, /gf (ablak). Az "i" gomb is kiírja.
- A Kalandnapló olvasása tier 0-val is próbálkozik.

--- 2.3.0 ---
- A Foreverben nincs Kalandnapló-adat, ezért a Refresh az AtlasLoot (Classic Forever) adatbázisát olvassa ki.
  Telepítsd az AtlasLoot Classic Forever-t, majd nyomj Refresh-t. Semmi nincs belemásolva, mindig az aktuális adatot olvassa.
- /gf probe kiírja: az AtlasLoot modulokat, hány instát és itemet talált.
- Ha a Kalandnapló mégis ad adatot, azt használja az addon.

--- 2.3.1 ---
- /gf refresh : azonnali frissítés parancsból (ugyanaz, mint a Refresh gomb).
- Belépés után 8 mp-cel egyszer automatikusan frissít, de csak ha a katalógus üres vagy új a játék-build. /gf auto off kikapcsolja.

--- 2.4.0 ---
- Item ikonok megjelennek (a keret fekete háttere eddig eltakarta őket).
- A szint az itemek "Requires Level" sorából is kiolvasódik (Forever-ben az API néha 0-t adott), ezért a "Level: now" valóban csak
  a karaktered szintjén használható cuccokat mutatja. A listában és a kártyákon "Level N" látszik.
- AtlasLoot import: csak a Dungeons/Raids modul (nincs több szakma/reputáció az insták között).
- Az első belépéskor egyszer újraolvas (a régi katalógus formátuma elavult).

--- 2.5.0 ---
- Beépített katalógus (Data/Loot.lua): ha nincs Kalandnapló és nincs AtlasLoot, ezt használja. Jelenleg üres; a mentésfájlodból
  (WTF/Account/<fiók>/SavedVariables/Gearfinder.lua) generálható, utána az addon AtlasLoot nélkül is önállóan működik.

--- 2.6.0 ---
- Beépített katalógus: 37 instance (29 dungeon, 8 raid), 1983 item, az AtlasLoot Classic Forever adatából (a te mentésedből).
  AtlasLoot nélkül is működik, belépés után magától betölti (8 mp), utána az item adatok a játékból jönnek.
- Tiszta instance- és bossnevek (nincs színkód / ikon-escape, rendes nevek: Blackrock Depths, Molten Core stb.).
- Ha az AtlasLoot telepítve van, az továbbra is elsőbbséget élvez (frissebb adat). Törölhető.

--- 2.7.0 ---
- Csak a kasztnak megfelelő páncéltípus: Warrior/Paladin lemez (40-től; előtte mail), Hunter/Shaman mail (40-től; előtte leather),
  Rogue/Druid leather, Priest/Mage/Warlock cloth. A kisebb típus (pl. mail Paladinnak) csak akkor jelenik meg, ha arra a slotra
  nincs a legjobb típusból item. Köpeny, nyaklánc, gyűrű, trinket nincs korlátozva.
- Spec-függő fegyverek: Ret Paladin kétkezes, Holy/Prot Paladin egykezes + pajzs, Prot Warrior nem kap kétkezest.
- Minden karakterre és specre külön számol (a profil karakterenként és specenként készül).

--- 2.8.0 ---
- Az addon érzékeli, mit hordhat a karakter: a megtanult páncél-képzettségekből (Plate Mail, Mail, Leather), ha az nem elérhető,
  a kaszt/szint táblából. Az Overview "CAN WEAR" sora mutatja (pl. "Mail (Plate from level 40)").

--- 2.9.0 ---
- Stat szerinti szűrés kasztra és specre: fizikai specek (Warrior, Rogue, Hunter, Ret/Prot Paladin, Enhancement Shaman, Feral Druid)
  nem kapnak spell power / Intellect / Spirit cuccot; casterek és healerek nem kapnak Strength / Agility / Attack Power / tank cuccot;
  a damage specek nem kapnak tisztán tank (Defense / Block) cuccot. Hunter nem kap csak-Strength itemet.
  Ha az item vegyes, de van rajta a spec saját fő statja, bent marad.

--- 2.9.1 ---
- A kaszt mindig számít, a spectől függetlenül: Priest / Mage / Warlock soha nem kap Strength / Agility / Attack Power-es itemet
  (vegyesen sem). Ha a spec nem derül ki, a kaszt alapszerepe (Warrior/Rogue = fizikai, Hunter = távoli, Priest/Mage/Warlock = caster) érvényes.

--- 2.10.0 ---
- Az UPGRADES panel fejlécében két új gomb:
  * Loot: All / Boss / Trash  (bal klikk előre, jobb klikk vissza) – csak boss dropok vagy csak trash dropok.
  * Instance választó: bal klikk = lista (Dungeons / Raids, szint szerint), jobb klikk = léptetés visszafelé.
  A kettő együtt működik: pl. csak a Deadmines boss lootja, vagy csak a Stratholme trash lootja. Karakterenként mentődik.

--- 2.11.0 ---
- Frakció-szűrés: az addon felismeri, hogy Alliance vagy Horde a karakter, és kihagyja a másik frakció quest-jutalmait
  (pl. "(Horde Quest)", "Alliance Only Quest").
- Quest-jutalmaknál, ahol nincs "Requires Level" sor, a szintet az item szintjéből becsüli (~ jellel látszik), így egy
  alacsony szintű karakter nem kap 55-ös iLvl-ű questitemet "Level 1"-ként.

--- 2.12.0 ---
- Adatbázis-frissítés (2026-11-13-i állapot, forrás: timesaver.gg, Wowhead item ID-kkal): 208 sor, 7 új Forever dungeon.
  Új: The Drowned City, Alcaz Prison, Blackmaw Hold, The Shaper's Terrace. Kiegészítve: Hall of Thanes, Ruins of Lordaeron,
  Excavation Site: Wetlands (boss loot, trash loot, quest-jutalmak frakcióval). Data/LootUpdate.lua, minden adatforrásra ráfésülődik.
- Loot gomb negyedik állása: Quest (quest-jutalmak). A Boss és a Trash már nem keveri bele a quest-jutalmakat.
- Krol'dok Stronghold és City of Dalaran: nincs ID-s forrás, ezeket továbbra is az addon tanulja meg lootoláskor.
- Belépéskor egyszer automatikusan újraolvas, hogy az új itemek adatai betöltődjenek.

--- 2.13.0 ---
- Új logó: rúna-medál, benne a G-ből kinövő kis f. Két változat:
  * Arany rúnák (alap) – ez az addon-listában is.
  * Arcane kék – választható.
  Váltás: Shift + bal klikk a minimap gombon, kattintás az ablak bal felső logójára, vagy /gf logo 1 | /gf logo 2.
  A választás mentődik (minden karakteren ugyanaz).

--- 2.14.0 (2026-11-25, kliens 1.60.1.70938, interface 16001 – változatlan) ---
- Raidek a Forever szerint: dec. 9-én Barrow Deeps, Hyjal Summit, Onyxia's Lair nyílik. A Molten Core, Blackwing Lair,
  Zul'Gurub, Ahn'Qiraj (20/40) és Naxxramas még nincs a Foreverben (nincs bejelentett dátum), ezért ezek itemjeit
  az addon nem ajánlja, az instance-listából és a térképről is kimaradnak.
- Adatbázis: Krol'dok Stronghold (25 sor) és City of Dalaran (42 sor) teljes loot-táblája item ID-kkal,
  boss loot + frakciós quest-jutalmak. Mind a 9 új Forever dungeon benne van.
