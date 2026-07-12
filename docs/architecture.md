# Architecture

## Runtime model

MurderCustom is a Garry's Mod gamemode written in Garry's Mod Lua. The server is authoritative for rounds, roles, player state, loot, spawns, and map rotation. Clients own HUD/VGUI and visual effects. State crosses the boundary through `net` messages and networked entity/player values.

Counter-Strike: Source content is required for maps, textures, and models.

## Gamemode discovery

`gamemodes/murder_custom/murder_custom.txt` registers the gamemode:

- base gamemode: `base`;
- title: `MurderCustom`;
- normal map prefixes: `md_`, `mu_`, and `murder_`.

`gamemodes/murder_custom/gamemode/shared.lua` defines metadata, teams, and round constants used in both realms.

## Realm entry points

### Server

`gamemode/init.lua` is the server entry point. It:

1. Recursively calls `AddCSLuaFile` for `cl_`, `sh_`, and shared Lua files.
2. Explicitly includes `sh_translate.lua`, `shared.lua`, `weightedrandom.lua`, then each `sv_` subsystem.
3. Creates server ConVars and registers global lifecycle hooks.
4. On initialization, loads spawn data, starts round state, loads loot, and loads the map list.
5. On each server tick, dispatches round, murderer, loot, and flashlight work.

Server execution order is the explicit `include(...)` list, not filename order. Adding a server subsystem requires adding it to this list in the correct dependency position.

### Client

`gamemode/cl_init.lua` is the client entry point. It explicitly includes translation/shared files and each `cl_` subsystem, creates client ConVars, and owns top-level client initialization, tick, and rendering hooks.

Adding a client subsystem requires adding it to the explicit include list. A file being sent with `AddCSLuaFile` does not execute it.

### Shared

Files prefixed `sh_` and `shared.lua` execute in both realms. Keep server-only APIs behind `SERVER` and client-only rendering/VGUI behind `CLIENT`. Gameplay authority stays server-side.

## Round state machine

Round constants live in `shared.lua`; transitions live in `sv_rounds.lua` and are mirrored to clients by `SetRound`.

| State | Value | Meaning |
| --- | ---: | --- |
| `NotEnoughPlayers` | 0 | Waiting for at least two active players |
| `Playing` | 1 | Active round |
| `RoundEnd` | 2 | Winner declared; waiting to restart |
| `MapSwitch` | 4 | Round limit reached; waiting for map change |
| `RoundStarting` | 5 | Enough players; countdown before start |

`GM:StartNewRound()` cleans the map, chooses a weighted murderer, respawns/freezes players, assigns one initial magnum, resets per-round state, and enters `Playing`. `GM:RoundCheckForWin()` ends the round when the murderer wins, dies, or leaves.

## Network contracts

Payload write/read order is an API. Change the sender and receiver in the same edit.

| Message | Server side | Client side | Purpose |
| --- | --- | --- | --- |
| `SetRound`, `DeclareWinner` | `sv_rounds.lua` | `cl_rounds.lua`, `cl_endroundboard.lua` | Round state and result |
| `your_are_a_murderer` | `sv_murderer.lua` | `cl_murderer.lua` | Local role state |
| `GrabLoot`, `SetLoot` | `sv_loot.lua` | `cl_rounds.lua` | Local loot count |
| `spectating_status` | `sv_spectate.lua` | `cl_spectate.lua` | Custom spectate state |
| `mu_death` | `sv_player.lua` | `cl_respawn.lua` | Death overlay timing |
| `mu_weapon_variant` | `sv_player.lua` | `cl_player.lua` | Validated live weapon-cosmetic selection |
| `add_footstep`, `clear_footsteps` | `sv_footsteps.lua` | `cl_footsteps.lua` | Murderer footprint clues |
| `chattext_msg`, `msg_clients` | `sv_chattext.lua` | `cl_chattext.lua` | Structured/system chat |
| `flashlight_charge` | `sv_flashlight.lua` | `cl_flashlight.lua` | Battery state |
| `Spawns_View`, `Spawns_ViewChange` | `sv_spawns.lua` | `cl_spawns.lua` | Admin spawn visualization |
| `mu_adminpanel_details` | `sv_adminpanel.lua` | `cl_adminpanel.lua` | Admin detail requests/results |
| `mu_tker` | `sv_tker.lua` | `cl_init.lua` | Team-kill penalty state |
| `reopen_round_board` | `init.lua` | `cl_endroundboard.lua` | Reopen result board |
| `mers_base_holdtype` | `weapon_mers_base.lua` server branch | Same shared SWEP, client branch | Weapon hold-type synchronization |
| `mu_knife_charge` | `weapon_mu_knife.lua` | Same shared SWEP | Thrown-knife charge UI |
| `TTT_ConfirmUseTButton` | `entities/entities/ttt_traitor_button/init.lua` | `shared.lua` client branch in the same entity | Successful map-button feedback |
| `translator_language` | `sh_translate.lua` server branch | Same file, client branch | Selected gameplay language |

`weapon_mers_base.lua` also defines an integer `Variant` network variable for its SWEP instances. When a player equips a knife or magnum, the server validates and applies that player's archived user-info selection; clients then apply the matching view model, world model, skin, material, animations, and sounds. The thrown `mu_knife` entity carries its own integer `Variant` so throwing and recovering a knife preserves its appearance until it is equipped again.

Player disguise state uses the `murderDisguiseModel` and `murderDisguiseOriginalModel` networked strings. `sv_player.lua` owns the values; the server `Think` in `init.lua` re-asserts the disguised model each tick and `cl_player.lua` applies it before rendering, so model-selector addons in either realm cannot hide the disguise from other players or from the murderer's third-person view.

Find every registration, sender, and receiver with:

```sh
rg -n 'util\.AddNetworkString|net\.(Start|Receive)' gamemodes/murder_custom
```

## Extension boundaries

- Use existing `GM` hooks and player meta methods before adding parallel state.
- Use `weapon_mers_base.lua` for shared SWEP behavior.
- Keep client UI observational; it must not decide roles, wins, inventory awards, or permissions.
- Treat network names, field order, round values, and persistent-data paths as compatibility contracts.
