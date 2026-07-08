# AGENTS

## Project Context
- Project: `love-life`
- Purpose: Conway's Game of Life in Lua using LÖVE.
- **Current phase:** Milestone 3-B next (controls + docs).
- **Active branch:** `main`

## Execution Order
Complete phases in order; each leaves the app runnable and tests green.

| Phase | Focus |
|-------|-------|
| M1 ✓ | Render baseline, grid tests |
| **M2-A** ✓ | `src/rules.lua`, wire `grid.computeNext(world, rules)` |
| **M2-B** ✓ | `patterns/`, loader, remove `seedGlider` |
| **M2-C** ✓ | Read-only status bar |
| **M3-A** ✓ | `src/playback.lua`, `love.update` |
| **M3-B** | Status bar controls, README |

See `PLAN.md` for checkpoints and file-level detail.

## Product Direction
- Build a configurable board of square tiles representing world state.
- Cell states: alive, dead.
- Toroidal universe (edges wrap).
- Visuals use named **themes** (colors only, not sizes).
- Built-in themes: `classic`, `zenburn`, `solarized`.
- Default active theme: `classic`.

## Rulestrings
- Life rulestrings use the form `Bx/Sy`:
  - `B` digits = neighbor counts that birth a dead cell (exact match).
  - `S` digits = neighbor counts that let a live cell survive (exact match).
- Named **rule presets** in `src/rules.lua`, selected by `activeRule` in config (like themes).
- Built-in presets:
  - `conway` — `B3/S23` (default): dead cell with exactly 3 live neighbors is born; live cell with 2 or 3 neighbors survives.
  - `ant_colony` — `B3/S234`: same birth rule; live cells survive on 2, 3, or 4 neighbors (Ant Colony Life).
- Status bar shows the resolved rulestring (e.g. `B3/S23`).
- **M2-A** ✓: parser + wire to `grid.computeNext`; unit tests in `tests/rules_spec.lua`.

## Patterns (initial states)
- Curated patterns live in `patterns/*.lua` (repo-native format).
- RLE import planned as follow-up for community patterns.
- Default load pattern: `glider` (configurable via `defaultPattern`).
- **M2-B** ✓ catalog tiers:
  - Core: glider, blinker, beacon
  - Extended: pulsar, random_soup
  - Deferred: gosper_glider_gun (large board)

## Status bar and playback
- **M2-C** ✓: bottom status bar shows rulestring, `rows×cols`, theme, step interval (read-only).
- **M3-A** ✓: playback state + `love.update` auto-step. Temporary keyboard controls in `main.lua` (`space` toggle, `s` play, `p` pause, `n` step).
- **M3-B:** status bar play/pause/step controls + finalized keyboard shortcuts/docs.
- `stepInterval` = seconds between auto-generations when playing.
- **Step backward:** deferred; future **history stack** (needs `grid.clone`).

## Next-State Preview Requirement
- Maintain both `current` and `next` generation buffers.
- Render preview markers on the board (colors from active theme):
  - dead → alive: `alive`-colored center dot on dead tile
  - alive → dead: `dead`-colored center dot on alive tile
  - unchanged: no center dot
- Preview dot sizing in config: `previewDotScale`, `previewDotMinRadiusPx`, `previewDotMaxRadiusPx`.

## Conway Rules Reference
- Default preset `conway` (`B3/S23`); alternate `ant_colony` (`B3/S234`) via `activeRule` in config.
- Universe: 2D square grid with **toroidal wrap** at edges.
- Neighborhood: Moore neighborhood (8 neighbors).
- Conway (`B3/S23`):
  - live cell with <2 neighbors dies
  - live cell with 2 or 3 survives
  - live cell with >3 dies
  - dead cell with exactly 3 becomes alive
- Updates must be simultaneous (compute from previous generation, not in-place mutation).

## Planned Runtime/Code Shape
- `conf.lua`: window/app configuration (resizable).
- `main.lua`: LÖVE entry, input, lifecycle.
- `src/config.lua`: board dimensions, theme, `activeRule`, `defaultPattern`, `stepInterval`, status bar height.
- `src/themes.lua`: named theme registry.
- `src/rules.lua`: named rulestring presets and `Bx/Sy` parser.
- `src/grid.lua`: world buffers, toroidal neighbor logic, `computeNext(world, rules)`, `step(world, rules)`.
- `src/patterns.lua`: load/apply `patterns/*.lua`.
- `src/renderer.lua`: theme-driven board render (viewport above status bar).
- `src/ui/statusbar.lua`: bottom stats + playback controls (**M2-C** display, **M3-B** controls).
- `src/playback.lua`: play/pause/step-forward state (**M3-A**).
- `patterns/`: one Lua file per initial state.
- `README.md`: usage and scope docs.
- `tests/`: plain Lua unit tests (`lua tests/run.lua`).

## Testing
- Run `lua tests/run.lua` from repo root (stdlib Lua, no LÖVE).
- **Today:** `src/grid.lua`, `src/rules.lua`, `src/patterns.lua`, `src/ui/statusbar.lua`, `src/playback.lua` — Conway/Ant Colony rules, toroidal wrap, parser/presets, core pattern loader, read-only status bar, playback stepping.
- **M2-A** ✓: `tests/rules_spec.lua` — parser, presets, Ant Colony behavior.
- Defer renderer/LÖVE integration tests until playback UI exists.

## Working Agreement For This Repo
- Keep this `AGENTS.md` updated with active context, constraints, and decisions.
- Keep `PLAN.md` updated as implementation progresses.
- Preserve historical intent in `PLAN.md` by marking items complete rather than deleting sections.
