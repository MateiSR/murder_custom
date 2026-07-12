# Repository instructions

Read `docs/README.md` before changing code or data. It is the canonical documentation index: use its task-routing table to open only the relevant guides, then inspect the implementation and its callers before editing.

@docs/README.md

## Working rules

- Preserve Garry's Mod realm boundaries: `sv_` is server-only, `cl_` is client-only, and `sh_`/shared files run in both realms.
- This is Garry's Mod Lua, not stock Lua. Keep the repository's existing syntax and engine APIs.
- Keep changes narrow and reuse the existing subsystem and network path.
- Treat code as authoritative if documentation is stale, then fix the documentation in the same change.
- Do not claim runtime verification unless the change was exercised in Garry's Mod. Record the checks actually run.

## Keep the map current

Update the owning document listed in `docs/README.md` in the same change when you add, remove, rename, or materially change:

- an entry point, subsystem, realm boundary, or load-order dependency;
- a console command, ConVar, network contract, or persistent-data path;
- a build, packaging, publishing, dependency, or validation workflow.

Internal edits that do not change navigation or a listed contract do not require a documentation edit.

Before finishing every task, inspect the changed-file list and apply the rules above. Documentation maintenance is part of the change, not a follow-up task.
