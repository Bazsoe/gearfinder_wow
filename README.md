# Gearfinder – WoW Forever

Dungeon and raid gear planner for **World of Warcraft: Forever** (client 1.60.1, interface 16001).

- Shows the best upgrade for every slot from dungeons and raids, scored for your class, talent tree and level.
- Knows what your class can wear (cloth / leather / mail / plate by level) and which stats your spec wants.
- Separates Alliance and Horde quest rewards; filters boss loot, trash loot and quest rewards; one-instance view.
- Map pins on dungeon and raid entrances with the number of upgrades inside.
- Built-in loot database for all nine new Forever dungeons; learns new drops while you play.

Commands: `/gf` (window), `/gf refresh`, `/gf probe`, `/gf logo 1|2`, `/gf auto on|off`.

## Publishing a new version (maintainer)
1. Change the code, add a line to `CHANGELOG.md`, commit and push.
2. On GitHub: **Releases → Draft a new release → Choose a tag** → type a new tag such as `v2.15.0` → **Publish release**.
3. The *Release to CurseForge* action packages the addon and uploads it. CurseForge app users get the update automatically.
