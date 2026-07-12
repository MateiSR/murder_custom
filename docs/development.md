# Development and release

## Prerequisites

- Garry's Mod capable of loading the repository as an addon/gamemode.
- Counter-Strike: Source owned, installed, and mounted for required content.
- A server/client session for meaningful gameplay verification.
- Windows PowerShell and Garry's Mod `gmad.exe`/`gmpublish.exe` at the paths expected by the release scripts when packaging.

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

`pack.ps1`:

1. deletes and recreates the local `pack/` staging directory;
2. copies addon content while excluding VCS/development files such as Markdown, PowerShell, GMA, and license files;
3. invokes `gmad.exe create` to produce `packed.gma`.

Run from the repository root in the expected Garry's Mod directory layout:

```powershell
./pack.ps1
```

The script is destructive only to its generated `pack/` directory.

## Publishing

`publish.ps1` invokes `gmpublish.exe update` with `packed.gma` and the fixed Workshop item ID `187073946`:

```powershell
./publish.ps1
```

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
