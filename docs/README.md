# Project documentation

Start here in every new session. This index routes work to the smallest relevant set of documents and source files; the source remains authoritative.

## Guides

| Guide | Owns |
| --- | --- |
| [Architecture](architecture.md) | Runtime topology, realms, entry points, load order, round states, network contracts |
| [Subsystems](subsystems.md) | Gameplay/UI responsibilities and the source files that implement them |
| [Data and localization](data.md) | Persistent and bundled map data, translations, materials, resource files |
| [Development and release](development.md) | Syntax constraints, search/validation workflow, packaging, publishing, documentation maintenance |

Claude Code loads the complete guide set through these imports. Other agents should follow the table above and read the guides relevant to the task.

@architecture.md
@subsystems.md
@data.md
@development.md

## Fast task routing

| Task | Read first | Source entry point |
| --- | --- | --- |
| Startup, load order, realm, or network change | [Architecture](architecture.md) | `gamemodes/murder_custom/gamemode/init.lua`, `cl_init.lua`, `shared.lua` |
| Round, role, player, UI, entity, or weapon behavior | [Subsystems](subsystems.md) | Matching subsystem row in that guide |
| Map loot/spawns, translations, or assets | [Data and localization](data.md) | `data_static/murder/`, `gamemode/lang/`, or `content/` |
| Command, ConVar, validation, package, or release work | [Development and release](development.md) | `commands.txt`, `pack.ps1`/`pack.sh`, `publish.ps1`/`publish.sh`, `addon.json` |
| New, removed, or renamed subsystem/path | All affected guides | Update this index as part of the same change |

## Repository at a glance

| Path | Purpose |
| --- | --- |
| `gamemodes/murder_custom/gamemode/` | Gamemode entry points and gameplay/UI subsystems |
| `gamemodes/murder_custom/entities/weapons/` | Hands, knife, magnum, and the shared SWEP base |
| `gamemodes/murder_custom/entities/entities/` | Loot, thrown knife, and TTT traitor-button entities |
| `gamemodes/murder_custom/content/` | Shipped materials and resource localization |
| `data_static/murder/` | Bundled per-map loot and spawn data |
| `addon.json` | Workshop addon metadata |
| `pack.ps1`/`pack.sh`, `publish.ps1`/`publish.sh` | Windows and Linux package/Workshop release scripts |

## Documentation rule

Documentation changes are part of the implementation. Before finishing any task, compare the changed files with the ownership table in [Development and release](development.md), update the affected guide, and fix this index if navigation changed. Internal edits that do not alter a documented route or contract need no documentation churn.
