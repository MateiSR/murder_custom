# Data and localization

## Data model

Bundled map data lives under `data_static/murder/<map>/`, where `<map>` is the exact Garry's Mod map name. Loot and spawn files contain JSON even though their extension is `.txt`.

Runtime admin commands write to Garry's Mod's writable `DATA` mount. They do not update `data_static/` in this repository. Shipping an in-game edit therefore requires deliberately copying the generated file into the matching repository path and reviewing the resulting JSON.

## Spawn data

| Item | Value |
| --- | --- |
| Owner | `gamemodes/murder_custom/gamemode/sv_spawns.lua` |
| Bundled path | `data_static/murder/<map>/spawns/spawns.txt` |
| Runtime path | `data/murder/<map>/spawns/spawns.txt` |
| Structure | JSON table keyed by numeric IDs; values are serialized Garry's Mod vectors |

`GM:LoadSpawns()` calls `file.ReadDataAndContent`, defined in `gamemode/init.lua`. That helper reads writable `DATA` first, then `data_static/` through the `GAME` mount. Runtime data therefore overrides bundled data.

Spawn administration uses the `mu_spawn_*` commands documented in `gamemodes/murder_custom/commands.txt`; saves always target `DATA`.

## Loot data

| Item | Value |
| --- | --- |
| Owner | `gamemodes/murder_custom/gamemode/sv_loot.lua` |
| Bundled path | `data_static/murder/<map>/loot.txt` |
| Runtime path | `data/murder/<map>/loot.txt` |
| Structure | JSON table keyed by numeric IDs; records contain model, position, angle, and optional material |

The loot loader takes the first file found in this order:

1. `data/murder/<map>/loot.txt`
2. `gamemodes/murder/content/data/murder/<map>/loot.txt`
3. `data_static/murder/<map>/loot.txt`

The second path is the literal compatibility path currently used by `sv_loot.lua`; do not silently rewrite it while making unrelated data changes.

During a round, automatic loot makes an immediate spawn attempt after reset and then another every 12 seconds. Unoccupied authored positions are used first. When none are available, the server falls back to a bounded pool of world-floor positions recently traversed by living players, revalidating clearance and player distance before each spawn. These generated positions are round-local and are never written to `DATA`. Automatic spawning pauses at a target between 5 and 12 according to the number of living bystanders; it does not cull existing or admin-respawned loot.

Loot administration uses the `mu_loot_*` commands. `mu_loot_reload` can force `--data`, `--embedded`, or `--static`; saves target `DATA`.

## Map list

`gamemode/sv_rounds.lua` owns map rotation.

1. `file.ReadDataAndContent("murder/maplist.txt")` checks writable `data/murder/maplist.txt`, then bundled `data_static/murder/maplist.txt` if one exists.
2. If neither exists, the code filters its hard-coded default list to installed BSP files.
3. Generated/saved map lists go to writable `DATA`.

MapVote is used when its global integration is present; otherwise the code rotates through the loaded list and calls `changelevel`.

## Gameplay translations

`gamemodes/murder_custom/gamemode/sh_translate.lua` dynamically discovers and loads `gamemode/lang/*.lua`. The server's `mu_language` ConVar selects the language and networks it to clients. Missing keys fall back to `english.lua`.

When adding user-visible gameplay text:

1. Add the key to `gamemode/lang/english.lua`.
2. Add the same key to the other language files when a translation is available; English fallback makes partial rollout safe.
3. Use the existing `translate` or `translate.table` API at the call site.
4. Preserve placeholder names used by `Translator:VarTranslate`/`AdvVarTranslate`.

## Resource localization

`gamemodes/murder_custom/content/resource/localization/<language>/murder.properties` is a separate Garry's Mod resource-localization set. It does not replace the Lua gameplay tables in `gamemode/lang/`.

Update the family actually consumed by the changed feature. If both systems expose the same user-visible concept, keep both synchronized.

## Materials and downloadable assets

Shipped assets live under `gamemodes/murder_custom/content/`. Current material families include:

- `materials/murder/` for gamemode branding;
- `materials/thieves/` for footprint rendering.

Server registrations are explicit `resource.AddFile(...)` calls in `gamemode/init.lua`. When adding an asset that clients must download, put it under `content/`, reference the mounted runtime path in code, and add/verify its resource registration.

Weapon cosmetic variants use external Workshop addons instead of copying their model and material files into this repository. `gamemode/init.lua` registers each item with `resource.AddWorkshop(...)`; the server must also mount the same items through its Workshop collection. The USP-S Orion and Minecraft Bow items replace existing mounted material/model paths globally, while the other variants use addon-specific paths. See [Development and release](development.md#runtime-workshop-dependencies) for the current IDs and deployment requirements.

## Data-change checks

- Confirm the directory uses the exact map name.
- Confirm `.txt` content parses as JSON and retains Garry's Mod vector/angle data.
- Check whether a local `DATA` override masks the bundled file during testing.
- For renamed translation keys, search all code and every language file.
- For removed assets, search code, VMT dependencies, and `resource.AddFile` before deletion.
