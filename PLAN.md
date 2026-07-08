# PLAN

## Plan Status
- Current stage: **Milestone 1 complete** on branch `milestone-1`.
- Source plan: configurable grid renderer with next-state preview, themes, patterns, status bar, and playback controls.
- Implementation split into milestones (see below); complete in order.

## Goal
Create a playable Conway's Game of Life in LÖVE: configurable toroidal grid, theme-driven rendering with next-generation preview markers, loadable initial patterns, bottom status bar, and play/pause/step controls.

## Milestones

### Milestone 1 — Render baseline
- Configurable grid, themes, toroidal `nextState` preview, centered board in resizable window.
- No playback UI yet (static preview only).

### Milestone 2 — Patterns + status bar (read-only)
- Repo pattern files in `patterns/` (Lua format).
- Pattern loader + apply-to-world (centered placement).
- Bottom status bar displays: rulestring, rows×cols, theme, step interval (display only).

### Milestone 3 — Playback controls
- Play / pause / step forward.
- `stepInterval` drives auto-advance in `love.update`.
- Step forward swaps `current` ← `next`, recomputes preview.

### Future (planned, not Milestone 1–3)
- RLE (`.rle`) pattern import
- Step backward via generation **history stack**
- Click-to-toggle cells, rulestring parser (`Bx/Sy`), theme hotkeys, video export

## Scope (Milestone 1)
- Implement rendering-only board visualization.
- Include board-size and tile-size configuration.
- Load initial state from default pattern (once Milestone 2 lands) or inline demo seed for M1.
- Add parallel `nextState` for preview markers.
- Toroidal neighbor rules in `computeNextState` (B3/S23).

## Planned Files
- Add `main.lua`
- Add `conf.lua`
- Add `src/config.lua`
- Add `src/themes.lua`
- Add `src/grid.lua`
- Add `src/renderer.lua`
- Add `src/ui/statusbar.lua` (Milestone 2+)
- Add `src/patterns.lua` (Milestone 2+)
- Add `patterns/*.lua` (Milestone 2+)
- Add `src/playback.lua` (Milestone 3+)
- Update `README.md`

## Design Decisions (locked before implementation)

### Board boundaries
- **Toroidal wrap**: the grid edges connect; out-of-bounds neighbors wrap around (left↔right, top↔bottom).
- Neighbor lookup in `grid.lua` must use modular arithmetic on row/col indices.

### Window layout
- **Resizable window** with the board **centered** in the viewport.
- Board pixel size = `cols * tileSize` × `rows * tileSize`.
- Renderer computes board offset from `love.graphics.getDimensions()` so centering survives resize.
- `love.resize` should trigger redraw (no sim logic needed in baseline).

### Coordinate conventions
- **1-based** row/col indexing in Lua tables (idiomatic Lua).
- Screen mapping: `col` → x, `row` → y; origin top-left (matches LÖVE).
- Mouse-to-cell conversion (future input) uses the same offset math as renderer.

### Grid data model
- Prefer a small **world** object bundling:
  - `rows`, `cols`
  - `current` (2D boolean table)
  - `next` (2D boolean table, same dimensions)
- Keeps dimensions and buffers together for step/preview/render.

### Grid line rendering
- Draw filled cell rects first, then grid lines on top.
- Use half-pixel alignment (`+ 0.5`) where needed for crisp 1px lines on integer tile sizes.

### Demo seed / initial patterns
- **Milestone 1**: optional inline demo seed (glider) until pattern loader exists.
- **Milestone 2+**: ship curated patterns as repo files under `patterns/`.
- Patterns are placed **centered** on the current board (toroidal wrap applies after placement).
- Built-in catalog (initial set):
  - `glider` — classic spaceship
  - `blinker` — period-2 oscillator
  - `beacon` — period-2 oscillator
  - `pulsar` — period-3 oscillator (needs ≥13×13 board)
  - `gosper_glider_gun` — large pattern (needs large board; optional / later in catalog)
  - `random_soup` — pseudo-random fill for smoke testing

#### Pattern file format (repo-native Lua, Milestone 2)
- One file per pattern: `patterns/<id>.lua`
- Returns a table:
```lua
return {
  id = "glider",
  name = "Glider",
  -- cells as {col, row} offsets from pattern origin (1-based deltas)
  cells = {
    { 1, 0 }, { 2, 1 }, { 0, 2 }, { 1, 2 }, { 2, 2 },
  },
}
```
- `src/patterns.lua`:
  - `list()` — discover/load catalog entries
  - `get(id)` — load one pattern
  - `apply(world, patternId)` — clear world, stamp pattern centered on board

#### RLE import (future, after Lua patterns)
- Support standard Life **RLE** (`.rle`) for community patterns.
- Keep parser in `src/patterns/rle.lua` or extend `src/patterns.lua`.
- Lua patterns remain the source of truth for shipped demos.

### Status bar (bottom)
- Fixed-height bar at **bottom** of window (`statusBarHeight` in config, not in theme).
- Board renders in remaining viewport above the bar (still centered horizontally).
- **Milestone 2** (display only): show
  - rulestring (e.g. `B3/S23`)
  - board size (`rows×cols`)
  - active theme name
  - step interval (seconds between auto-steps)
- **Milestone 3** (interactive): add controls
  - Play / Pause
  - Step forward (advance one generation)
- Text/button hit areas in `src/ui/statusbar.lua`; input wired in `main.lua`.

### Playback (Milestone 3)
- State: `running` (bool), `stepInterval` (seconds), `accumulator` (dt).
- **Play**: set `running = true`; `love.update` advances when accumulator ≥ `stepInterval`.
- **Pause**: set `running = false`.
- **Step forward**: single generation regardless of `running`:
  1. `current ← next`
  2. recompute `next` from new `current`
  3. (future) push `current` snapshot onto history stack
- While paused, preview dots still reflect pending next generation.

### Step backward (future — history stack)
- **Deferred** for Milestone 1–3.
- Plan: ring buffer or stack of `current` grid snapshots per forward step.
- Step back pops history → restore `current` → recompute `next`.
- Memory cost: `O(historyDepth × rows × cols)`; cap depth in config later.

### Rule engine (baseline vs future)
- Baseline hard-codes **B3/S23** in `computeNextState`.
- Stub a `rules` module shape early for future `Bx/Sy` parsing (README goal), but do not implement parser in baseline.

### README correction note
- README birth rule text is wrong: classic Life births on **exactly 3** neighbors, not 2. Survival is 2 **or** 3. Fix when touching README.

## Design Outline

### Themes (named color schemes)
- Use **theme** as the name (editor-style color scheme; alternatives considered: `palette`, `scheme`, `appearance`).
- A theme is a named table of **colors only** — no sizes, spacing, or layout.
- Themes are registered in `src/themes.lua` and selected by name from config.
- Baseline ships three built-in themes: `classic`, `zenburn`, `solarized`.
- Renderer and preview markers read all draw colors from the active theme.

#### Built-in themes
| name | alive | dead | grid | background |
|------|-------|------|------|------------|
| `classic` | white `#FFFFFF` | black `#000000` | gray `#808080` | `#000000` (same as dead) |
| `zenburn` | `#DCDCCC` | `#3F3F3F` | white `#FFFFFF` | `#3F3F3F` (same as dead) |
| `solarized` | `#fdf6e3` | `#002b36` | `#073642` | `#002b36` (same as dead) |

- Store colors in LÖVE as normalized RGB `{ r, g, b }` in `0..1` (convert from hex at definition time).
- `background` defaults to `dead` when not explicitly set.

#### Theme shape (per theme)
```lua
{
  name = "classic",
  alive = { 1, 1, 1 },       -- #FFFFFF
  dead = { 0, 0, 0 },        -- #000000
  grid = { 0.5, 0.5, 0.5 },  -- #808080
  background = { 0, 0, 0 },  -- window/board clear; defaults to dead
}
```
- Preview dots reuse theme colors (no separate preview color keys for baseline):
  - dead -> alive: dot uses `alive`
  - alive -> dead: dot uses `dead`

#### `src/themes.lua`
- Export:
  - `themes` — map of name -> theme table
  - `get(name)` — resolve theme by name (fallback to default if missing)
  - `list()` — optional, for future UI theme picker

### `src/config.lua`
- Central constants for:
  - `rows`, `cols`
  - `tileSize`
  - `activeTheme` (string name, default `"classic"`)
  - `defaultPattern` (string id, default `"glider"`)
  - `rulestring` (display default `"B3/S23"` until parser exists)
  - `stepInterval` (seconds, default e.g. `0.15`)
  - `statusBarHeight` (pixels, default e.g. `28`)
  - preview marker **sizing** (not part of theme):
    - `previewDotScale` (default `0.18`)
    - `previewDotMinRadiusPx` (default `2`)
    - `previewDotMaxRadiusPx` (default `8`)

### `src/grid.lua`
- Own board state as a 2D structure (`true` = alive, `false` = dead).
- Own second 2D structure `nextState` with identical dimensions.
- Expose helpers:
  - `create(rows, cols, defaultAlive)`
  - `setAlive(grid, row, col, alive)`
  - `clone(grid)` or `createLike(grid)`
  - `computeNextState(current, nextState)` using Conway B3/S23
  - optional `seedDemoPattern(grid)`

### `src/renderer.lua`
- Accept active theme + size config + layout (board area excludes status bar).
- Compute board offset: centered in viewport **above** status bar.
- Draw filled cells using `theme.alive` / `theme.dead`.
- Draw next-state preview center dots:
  - dead -> alive: center dot in `theme.alive`
  - alive -> dead: center dot in `theme.dead`
  - unchanged: no dot
- Dot radius:
  - `rawRadius = tileSize * previewDotScale`
  - `dotRadius = clamp(rawRadius, previewDotMinRadiusPx, previewDotMaxRadiusPx)`
- Draw gray grid lines above fills/dots.

### `main.lua`
- Wire config + grid + renderer + (M2) statusbar + (M2) patterns + (M3) playback.
- In `love.load`: initialize world, load default pattern, compute `nextState`.
- In `love.update` (M3): playback timer when running.
- In `love.draw`: clear, render board + preview, draw status bar.
- In `love.keypressed` / mouse (M3): play/pause/step shortcuts and bar buttons.
- In `love.resize`: redraw; layout recalculates each frame.

### `conf.lua`
- Set window title and initial size (can be larger than board).
- Enable `t.window.resizable = true`.
- Initial dimensions: board size + margin, or a sensible minimum.

## Behavior Baseline
- App launches to visible full board.
- Board dimensions and active theme configurable via config.
- Default theme `classic` visual contract:
  - live = white
  - dead = black
  - dead->alive preview = white center dot
  - alive->dead preview = black center dot
  - grid lines = gray

## Validation
- Run `love .` from repo root.
- Run `lua tests/run.lua` for grid unit tests (no LÖVE required).
- Verify:
  - expected rows/cols
  - aligned grid lines
  - correct alive/dead colors
  - preview dots only where `currentState ~= nextState`
  - birth/death preview dot colors are correct
  - preview dot scales with tile size and respects clamp bounds
  - changing `rows`, `cols`, `tileSize` updates rendering correctly
  - changing `activeTheme` swaps colors without affecting dot size math
  - resizing window re-centers board without changing cell layout
  - toroidal wrap: patterns crossing an edge behave correctly (e.g. glider wraps)

## TODO Tracking

### Milestone 1
- [x] Create minimal LÖVE entry files and module layout (`main.lua`, `conf.lua`, `src/*`)
- [x] Add `src/themes.lua` with named theme registry (`classic`, `zenburn`, `solarized`)
- [x] Implement world/grid model with toroidal B3/S23 `computeNextState`
- [x] Render theme-driven fills, preview center dots, and grid lines (centered above future status bar area)
- [x] Wire load/draw lifecycle and resizable window defaults
- [x] Add plain Lua unit tests for `src/grid.lua` (`tests/run.lua`)

### Milestone 2
- [ ] Add `patterns/*.lua` catalog and `src/patterns.lua` loader
- [ ] Apply centered pattern to world on load (`defaultPattern` config)
- [ ] Add `src/ui/statusbar.lua` — read-only stats row at bottom

### Milestone 3
- [ ] Add `src/playback.lua` — play/pause/step-forward state machine
- [ ] Wire `stepInterval` auto-advance in `love.update`
- [ ] Status bar play/pause/step buttons and keyboard shortcuts
- [ ] Update README (patterns, controls)

## Next Features (Do Not Delete, Mark Complete Later)
- [ ] RLE (`.rle`) pattern import
- [ ] Step backward via generation history stack
- [ ] Add click-to-toggle cell state
- [ ] Pattern picker UI (cycle/load catalog entries at runtime)
- [ ] Add alternate rulestring parser (`Bx/Sy`) wired to simulation
- [ ] Add more built-in themes beyond `classic`, `zenburn`, `solarized`
- [ ] Add runtime theme switching (keyboard/UI picker)
- [ ] Add export feature (gif/mp4 or equivalent)
