# Subsystems

Use this guide to find the owner of a behavior. Read the start file, its paired realm file, and all callers of the changed method/message before editing.

## Core gameplay

| Area | Server owner | Client/shared counterpart | Notes |
| --- | --- | --- | --- |
| Round lifecycle and map rotation | `gamemode/sv_rounds.lua` | `cl_rounds.lua`, `cl_endroundboard.lua`, `weightedrandom.lua` | State transitions, win checks, murderer selection, round limit, map list |
| Murderer state and reveal | `gamemode/sv_murderer.lua`, disguise methods in `sv_player.lua` | `cl_murderer.lua`, `cl_hud.lua` | Role flag, weighted chance reset, fog reveal, lost-knife recovery, and corpse model/color/name disguise |
| Player lifecycle | `gamemode/sv_player.lua` | `cl_player.lua` | Join/spawn, teams, models, loadout, weapon-cosmetic picker, death, pickup, chat/voice visibility |
| Bystander identity | `gamemode/sv_bystandername.lua` | Player state consumed by HUD, chat, and voice panels | Generated names, disguise identity, and admin player listing; `mu_show_player_names` controls aim-target labels |
| Team-kill penalty | `gamemode/sv_tker.lua` plus `sv_player.lua` | `cl_init.lua` | Penalty state and weapon restrictions |
| Spectating | `gamemode/sv_spectate.lua` | `cl_spectate.lua` | Custom target/mode selection and client display |
| Respawning | `gamemode/sv_respawn.lua` | `cl_respawn.lua` | Eligibility and death/respawn overlays |
| Ragdolls | `gamemode/sv_ragdoll.lua` | `cl_ragdoll.lua` | Death ragdoll creation and cleanup |
| Corpse inspection | `gamemode/sv_player.lua` | `cl_hud.lua` | Living bystanders press `+use` on a nearby death ragdoll to see victim, elapsed death time, cause, and drag evidence |

Round flow starts in `GM:StartNewRound()` in `sv_rounds.lua`. It cleans the map, resets players, selects a murderer through `WeightedRandom`, gives a random bystander the magnum, and networks the new state plus the optional `mu_roundtime` deadline. Player death handling routes from `sv_player.lua` back into round win checks; an expired deadline gives the bystanders the win.

## Loot and map spawns

| Area | Server owner | Client/entity counterpart | Notes |
| --- | --- | --- | --- |
| Loot data and rewards | `gamemode/sv_loot.lua` | `cl_rounds.lua`, `entities/entities/mu_loot/` | Loads/saves positions, periodically spawns loot, grants magnums at thresholds |
| Player spawn positions | `gamemode/sv_spawns.lua` | `cl_spawns.lua` | Loads/saves spawn lists and supports admin visualization |

The data locations and precedence rules are documented in [Data and localization](data.md). Runtime admin edits are written to Garry's Mod `DATA`; they do not modify repository files automatically.

## Interface and feedback

| Area | Owner | Related code |
| --- | --- | --- |
| Main HUD and round-start overlay | `gamemode/cl_hud.lua` | `cl_rounds.lua`, `cl_respawn.lua`, `cl_flashlight.lua` |
| Scoreboard | `gamemode/cl_scoreboard.lua` | `sv_adminpanel.lua`, `cl_adminpanel.lua` |
| End-round board | `gamemode/cl_endroundboard.lua` | `sv_rounds.lua`, `sv_player.lua`, `cl_rounds.lua`, `init.lua`; renders up to three server-selected round highlights |
| Structured chat | `gamemode/sv_chattext.lua`, `cl_chattext.lua` | Callers constructing `ChatText` messages |
| Voice panels | `gamemode/cl_voicepanels.lua` | Voice visibility rules in `sv_player.lua` |
| Radial Q menu | `gamemode/cl_qmenu.lua` | Taunts in `sv_taunt.lua` |
| Footprint clues | `gamemode/sv_footsteps.lua`, `cl_footsteps.lua` | Footprint material under `content/materials/thieves/` |
| Halos | `gamemode/cl_halos.lua` | Loot, dropped magnum, and knife entities |
| Flashlight battery | `gamemode/sv_flashlight.lua`, `cl_flashlight.lua` | `mu_flashlight_battery` ConVar |
| Admin panel | `gamemode/sv_adminpanel.lua`, `cl_adminpanel.lua` | Permission snapshot networked with round state |

## Weapons and entities

| Path | Responsibility |
| --- | --- |
| `entities/weapons/weapon_mers_base.lua` | Shared scripted-weapon behavior and networked cosmetic-variant application used by Murder weapons |
| `entities/weapons/weapon_mu_hands.lua` | Unarmed prop carrying; ragdoll `+use` pickup is disabled, only the living murderer can drag one with secondary attack, and moving a corpse at least 32 units records drag evidence |
| `entities/weapons/weapon_mu_knife.lua` | Murderer melee attack, charged throw, and expandable knife variant catalog |
| `entities/weapons/weapon_mu_magnum.lua` | Bystander one-shot weapon behavior and expandable visual/sound variant catalog |
| `entities/entities/mu_knife/` | Thrown knife world entity; preserves the originating knife variant through recovery and tags player hits as slash damage |
| `entities/entities/mu_loot/` | Collectible loot world entity |
| `entities/entities/ttt_traitor_button/` | Compatibility with map-authored TTT traitor buttons |

Weapon files are shared and branch internally on `SERVER`/`CLIENT`. Preserve prediction and lag-compensation paths when changing attacks. World behavior for a thrown/dropped object belongs in its entity, not only in the SWEP.

Variants remain instances of `weapon_mu_knife` or `weapon_mu_magnum`; role restrictions, loot rewards, halos, drops, and team-kill penalties therefore continue using the existing class checks. Players choose archived preferences through `cl_player.lua`; `weapon_mers_base.lua` validates and applies them when the weapon is equipped. Add a variant to the owning SWEP's `SWEP.Variants` table and add any new Workshop item ID to the download list in `gamemode/init.lua`.

## Translation

`gamemode/sh_translate.lua` loads all `gamemode/lang/*.lua` files in both realms, networks the selected language, and falls back to English for missing keys. See [Data and localization](data.md) before adding or renaming user-visible strings.

## Commands and ConVars

`gamemodes/murder_custom/commands.txt` is the user-facing reference. Implementations live with their owning subsystem. Locate the complete current set before changing one:

```sh
rg -n 'concommand\.Add|CreateConVar|CreateClientConVar' gamemodes/murder_custom
```

When a public command or ConVar changes, update `commands.txt` and [Development and release](development.md) if the workflow or navigation also changes.
