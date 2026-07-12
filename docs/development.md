# Development and release

## Prerequisites

- Garry's Mod capable of loading the repository as an addon/gamemode.
- Counter-Strike: Source owned, installed, and mounted for required content.
- A server/client session for meaningful gameplay verification.
- On Windows: PowerShell and Garry's Mod `gmad.exe`/`gmpublish.exe`.
- On Linux: a POSIX shell, standard `find`/`cp` tools, and Garry's Mod's Linux GMad/GMPublish binaries.

The release scripts expect the repository at `GarrysMod/garrysmod/addons/<addon>`: the Garry's Mod `bin/` directory must therefore be three directories above the repository. On Linux, the scripts detect the tools in `bin/linux64`, `bin/linux32`, and the legacy `bin/gmad_linux`/`bin/gmpublish_linux` locations.

There is no package manager, dependency-install step, automated test suite, or repository-defined linter.

## Garry's Mod Lua constraints

This code targets Garry's Mod Lua, not stock Lua. Existing syntax includes `!`, `!=`, `&&`, `||`, and `//`. Do not run a generic Lua formatter or parser that rewrites/rejects those constructs without Garry's Mod support.

Preserve these boundaries:

- `sv_*.lua`: server realm;
- `cl_*.lua`: client realm;
- `sh_*.lua`, `shared.lua`, shared SWEPs: both realms, with explicit `SERVER`/`CLIENT` guards where needed;
- net payload field order: paired sender/receiver contract;
- explicit include order in `init.lua` and `cl_init.lua`: runtime dependency order.

## Change workflow

1. Use [the documentation index](README.md) to identify the owning subsystem.
2. Read the complete source entry point and search every caller/message counterpart before editing.
3. Make the smallest change in the existing owner; avoid a parallel helper or state path.
4. Inspect the diff and changed-file list.
5. Run the checks below and exercise the change in Garry's Mod when available.
6. Apply the documentation ownership rules before finishing.

Useful searches:

```sh
rg -n 'include|AddCSLuaFile' gamemodes/murder_custom/gamemode/{init,cl_init}.lua
rg -n 'util\.AddNetworkString|net\.(Start|Receive)' gamemodes/murder_custom
rg -n 'concommand\.Add|CreateConVar|CreateClientConVar' gamemodes/murder_custom
rg -n 'function GM:|FindMetaTable' gamemodes/murder_custom
```

## Validation

No local automated validation command is defined. Minimum checks for code changes:

1. Review `git diff --check` and the actual diff.
2. Search all references to changed hooks, meta methods, message names, commands, ConVars, and data paths.
3. Verify realm guards and include order against `init.lua` and `cl_init.lua`.
4. For a net change, compare every `net.Write*` with the receiver's `net.Read*` in exact order and type.
5. For gameplay/UI behavior, run a Garry's Mod server plus client and exercise the affected path when the environment is available.

Report only checks actually run. State plainly when Garry's Mod runtime verification was unavailable.

## Commands and configuration

`gamemodes/murder_custom/commands.txt` is the checked-in user/admin reference. The implementation is distributed across subsystem files, so search `concommand.Add`, `CreateConVar`, and `CreateClientConVar` before treating the text file as exhaustive.

When adding or changing a public command or ConVar:

- keep it beside its owning subsystem;
- preserve admin/permission checks;
- update `commands.txt` in the same change;
- update `murder_custom.txt` too if the setting is exposed through the gamemode menu.

## Packaging

`pack.ps1` (Windows) and `pack.sh` (Linux):

1. delete and recreate the local `pack/` staging directory;
2. copy addon content while excluding VCS/development files such as Markdown, release scripts, GMA, and license files;
3. invoke the platform's GMad tool to produce `packed.gma`.

Run from the repository root in the expected Garry's Mod directory layout:

```powershell
./pack.ps1
```

```sh
./pack.sh
```

Each script is destructive only to its generated `pack/` directory.

## Runtime Workshop dependencies

Random weapon cosmetics use these Garry's Mod Workshop addons:

| ID | Content used |
| --- | --- |
| `3140497953` | Butterfly Knife Emerald |
| `887833744` | Karambit Black Steel, Doppler, and Marble Fade |
| `3253745052` | Stiletto Knife |
| `1919238032` | M9 Bayonet Apophysis Fade |
| `1323286207` | Hunting Bow |
| `3282915356` | Minecraft Bow replacement |
| `1629312994` | Desert Eagle Blaze |
| `734953738` | USP-S Orion material replacement |
| `726752951` | Five-SeveN Monkey Business |

`resource.AddWorkshop` in `gamemode/init.lua` makes clients download individual items; it does not install them on the dedicated server. Put the same items in the collection passed through `+host_workshop_collection <collectionID>` so server-side model validation can enable them. Missing addon-specific models are excluded from random selection and the stock knife/magnum remain available.

For another variant, first inspect the addon rather than guessing paths: confirm it is an Addon rather than a save/demo, audit its Lua because mounted dependencies execute, and verify view/world models plus every configured animation sequence. Then add its item ID in `gamemode/init.lua` and its catalog entry in the owning SWEP. Avoid copying or republishing another Workshop addon's files.

## Publishing

`publish.ps1` (Windows) and `publish.sh` (Linux) invoke GMPublish with `packed.gma`. Both require the numeric Workshop item ID explicitly; replace the example ID with one owned by the publishing Steam account:

```powershell
./publish.ps1 -WorkshopId 1234567890
```

```sh
./publish.sh 1234567890
```

The Linux scripts set `LD_LIBRARY_PATH` to the selected tool directory and Garry's Mod `bin/` so the shipped Steam libraries can be found.

Publishing mutates the live Workshop item. Run it only when the user explicitly intends a release and only after a successful package plus runtime verification. `addon.json` supplies the addon title, type, and tags used for packaging.

## Documentation ownership

Before finishing every task, inspect `git diff --name-status` and update documentation according to this table.

| Changed area | Document to review/update |
| --- | --- |
| `shared.lua`, `init.lua`, `cl_init.lua`, `murder_custom.txt`, network contracts | [Architecture](architecture.md) |
| Any `sv_*.lua`, `cl_*.lua`, weapon, or entity responsibility/path | [Subsystems](subsystems.md) |
| `data_static/`, `gamemode/lang/`, `content/`, or loader precedence | [Data and localization](data.md) |
| Commands, ConVars, validation, dependencies, scripts, `addon.json`, release flow | This document and `gamemodes/murder_custom/commands.txt` where applicable |
| New/removed/renamed guide, subsystem, or top-level path | [Documentation index](README.md) plus every affected guide |
| `AGENTS.md` or `CLAUDE.md` instruction chain | Both root instruction files and the index import chain |

Do not edit docs merely because code changed. Update them when a documented path, responsibility, contract, workflow, or invariant changed. If the code disagrees with documentation, follow the code and repair the stale document in the same change.
