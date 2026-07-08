# AGENTS

## Project Context
- Project: `love-life`
- Purpose: Conway's Game of Life in Lua using LÖVE.
- Current phase: initial rendering baseline (before full simulation loop).

## Product Direction
- Build a configurable board of square tiles representing world state.
- Cell states: alive, dead.
- Toroidal universe (edges wrap).
- Visuals use named **themes** (colors only, not sizes).
- Built-in themes: `classic`, `zenburn`, `solarized`.
- Default active theme: `classic`.

## Patterns (initial states)
- Curated patterns live in `patterns/*.lua` (repo-native format).
- RLE import planned as follow-up for community patterns.
- Default load pattern: `glider` (configurable via `defaultPattern`).
- Initial catalog: glider, blinker, beacon, pulsar, random_soup (gosper gun when board is large enough).

## Status bar and playback
- **Bottom status bar** shows: rulestring, `rows×cols`, theme, step interval.
- **Milestone 3 controls**: play, pause, step forward.
- `stepInterval` = seconds between auto-generations when playing.
- **Step backward**: deferred; future **history stack** of generation snapshots.

## Next-State Preview Requirement
- Maintain both:
  - `currentState` (current generation)
  - `nextState` (computed next generation)
- Render preview markers directly on the board (colors from active theme):
  - dead -> alive: draw an `alive`-colored center dot on dead tile
  - alive -> dead: draw a `dead`-colored center dot on alive tile
  - unchanged: no center dot
- Preview dot **sizing** lives in config, not in theme:
  - `rawRadius = tileSize * previewDotScale`
  - `dotRadius = clamp(rawRadius, previewDotMinRadiusPx, previewDotMaxRadiusPx)`
  - defaults: `previewDotScale=0.18`, `previewDotMinRadiusPx=2`, `previewDotMaxRadiusPx=8`

## Conway Rules Reference
- Universe: 2D square grid with **toroidal wrap** at edges.
- Neighborhood: Moore neighborhood (8 neighbors).
- B3/S23:
  - live cell with <2 neighbors dies
  - live cell with 2 or 3 survives
  - live cell with >3 dies
  - dead cell with exactly 3 becomes alive
- Updates must be simultaneous (compute from previous generation, not in-place mutation).

## Planned Runtime/Code Shape
- `conf.lua`: window/app configuration (resizable).
- `main.lua`: LÖVE entry, input, lifecycle.
- `src/config.lua`: board dimensions, theme, pattern id, step interval, status bar height.
- `src/themes.lua`: named theme registry.
- `src/grid.lua`: world buffers, toroidal neighbor logic, next-state computation.
- `src/patterns.lua`: load/apply `patterns/*.lua` (RLE later).
- `src/renderer.lua`: theme-driven board render (viewport above status bar).
- `src/ui/statusbar.lua`: bottom stats + playback controls.
- `src/playback.lua`: play/pause/step-forward state (Milestone 3).
- `patterns/`: one Lua file per initial state.
- `README.md`: usage and scope docs.

## Working Agreement For This Repo
- Keep this `AGENTS.md` updated with active context, constraints, and decisions.
- Keep `PLAN.md` updated as implementation progresses.
- Preserve historical intent in `PLAN.md` by marking items complete rather than deleting sections.
