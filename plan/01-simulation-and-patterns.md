# Simulation engine & patterns

Covers the Game of Life core: the toroidal grid, configurable rulestrings, and pattern loading (repo-native Lua + RLE import). This is the dependency root for every other area — rendering, playback, and all UI panes read/write through `src/grid.lua`, `src/rules.lua`, and `src/patterns.lua`.

See [`README.md`](README.md) for the cross-area roadmap. Related: [`02-rendering-and-animation.md`](02-rendering-and-animation.md) (draws the world this doc produces), [`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md) (Phase 4 picker UI + deferred catalog grouping).

## Development order

1. **M1** — render baseline with hard-coded rules/pattern (done, historical).
2. **M2-A** — extract rulestrings (`src/rules.lua`), parameterize `grid.computeNext`/`grid.step`.
3. **M2-B** — extract patterns (`src/patterns.lua`, `patterns/*.lua`), remove `grid.seedGlider`.
4. **M3-C** — add RLE import (`src/patterns/rle.lua`), shared `stamp()`, extended catalog.

All four steps are ✓ shipped on `main`.

---

### Milestone 1 — Render baseline ✓
- Configurable grid, themes, toroidal `next` preview, centered board in resizable window.
- `grid.seedGlider` inline demo until pattern loader lands (removed in M2-B).
- `grid.computeNext` hard-codes B3/S23 until M2-A.
- No playback UI (static preview only).

### Milestone 2-A — Rulestrings ✓
Pure Lua; no LÖVE changes required to finish this phase.

1. Add `src/rules.lua` — `parse(rulestring)`, presets `conway` / `ant_colony`, `get`, `list`
2. Add `tests/rules_spec.lua` — parser, presets, Ant Colony survives on 4 neighbors
3. Add `activeRule` to `src/config.lua` (default `"conway"`)
4. Refactor `grid.computeNext(world, rules)` and `grid.step(world, rules)` — replace hard-coded B3/S23
5. Update `tests/grid_spec.lua` to pass explicit Conway rules (keep behavior identical)

**Checkpoint:** `lua tests/run.lua` green; swapping `activeRule` to `ant_colony` changes simulation (config-only check until status bar — see [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md)).

### Milestone 2-B — Patterns ✓
1. Add `defaultPattern` to `src/config.lua` (default `"glider"`)
2. Add `patterns/glider.lua`, `patterns/blinker.lua`, `patterns/beacon.lua` (core catalog)
3. Add `src/patterns.lua` — `list`, `get`, `apply` (centered placement on world)
4. Wire `main.lua`: `patterns.apply(world, config.defaultPattern)` + `computeNext` with active rules
5. Remove `grid.seedGlider` (logic moves to `patterns/glider.lua`)

**Extended catalog** (same phase or immediately after core works):
- `patterns/pulsar.rle` (needs board ≥ 13×13; current 40×60 is fine)
- `patterns/random_soup.lua` (smoke test; good with `ant_colony`)

**Deferred catalog:** `random_soup` — optional procedural seed for smoke tests (see [`12-deferred-and-backlog.md`](12-deferred-and-backlog.md)).

**Checkpoint:** `love .` loads glider (or other `defaultPattern`) from `patterns/`; no `seedGlider` in codebase.

### Milestone 3-C — RLE import ✓
1. Refactor `src/patterns.lua` with shared `stamp(world, pattern)` for all formats
2. Add `src/patterns/rle.lua` parser (`x/y/rule` header, run counts, `$`, `!`, comments)
3. Extend pattern resolution to load `patterns/<id>.rle` through `love.filesystem.read`
4. Add shipped `.rle` assets (`pulsar`, `gosper_glider_gun`, `lifeview`)
5. Add parser and integration tests (`tests/rle_spec.lua`, expanded `patterns_spec`)

**Checkpoint:** `lua tests/run.lua` green; existing Lua patterns still load; `.rle` patterns load by `defaultPattern` id.

---

## Design decisions (locked)

### Board boundaries
- **Toroidal wrap**: the grid edges connect; out-of-bounds neighbors wrap around (left↔right, top↔bottom).
- Neighbor lookup in `grid.lua` must use modular arithmetic on row/col indices.

### Grid data model
- Prefer a small **world** object bundling:
  - `rows`, `cols`
  - `current` (2D boolean table)
  - `next` (2D boolean table, same dimensions)
- Keeps dimensions and buffers together for step/preview/render.
- `grid.clone(world)` — **deferred** to history-stack work (see [`12-deferred-and-backlog.md`](12-deferred-and-backlog.md)); not required for M2–M3.

### Demo seed / initial patterns
- **Milestone 1**: `grid.seedGlider` inline demo (temporary).
- **Milestone 2-B**: repo files under `patterns/`; remove `seedGlider`.
- Patterns are placed **centered** on the current board (toroidal wrap applies after placement).

#### Pattern file format (repo-native Lua)
- One file per pattern: `patterns/<id>.lua`
- Returns a table:
```lua
return {
  id = "glider",
  name = "Glider",
  -- cells as {col, row} offsets from pattern origin (0-based deltas)
  cells = {
    { 1, 0 }, { 2, 1 }, { 0, 2 }, { 1, 2 }, { 2, 2 },
  },
}
```
- `src/patterns.lua`:
  - `list()` — discover/load catalog entries
  - `get(id)` — load one pattern
  - `apply(world, patternId)` — clear world, stamp pattern centered on board

#### Pattern catalog tiers
| Tier | Patterns | When |
|------|----------|------|
| Core (M2-B) | `glider`, `blinker`, `beacon` | Required for phase complete |
| Extended (M3-C) | `pulsar.rle`, `gosper_glider_gun.rle`, `lifeview.rle`, plus spaceships (`copperhead`, `fireship`, `loafer`, `sidecar`), guns/rakes (`backrake_1`, `bomber`, `circle_of_fire`), methuselahs (`cottonmouth`, `moose_antlers`, `noahs_ark`, `diamond`), hybrids (`pulsar_on_pentadecathlon_i`, `still_life_tagalong`) | Loaded via RLE parser |
| Deferred | `random_soup` | Optional procedural seed |

#### RLE import (M3-C implementation)
- Supports standard Life **RLE** (`.rle`) for shipped and community patterns.
- Parser lives in `src/patterns/rle.lua` and returns normalized `{ id, name, rulestring, cells }`.
- `src/patterns.lua` resolves ids in order: Lua module → `.rle` file → fallback `glider`.
- RLE `rule = ...` is parsed and exposed, but simulation rule selection still uses config `activeRule`.
- Deferred RLE features:
  - honoring `#P` offsets
  - multiple patterns per file
  - runtime file picker / import UI
  - **pattern type metadata** and grouped picker UI (still lifes, oscillators, spaceships, linear growth, etc.) — see [`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md) deferred follow-up
  - sync from a **public RLE pattern repository** (community catalog + category index)

### Rule engine and rulestrings (Milestone 2-A)
- Life **rulestrings** have the form `Bx/Sy`:
  - `B` digits = neighbor counts that **birth** a dead cell (exact match).
  - `S` digits = neighbor counts that let a **live** cell survive (exact match).
  - Any other neighbor count kills a live cell or leaves a dead cell dead.
- Example: `B3/S23` (classic Conway) — a dead cell with exactly 3 live neighbors is born; a live cell with exactly 2 or 3 live neighbors survives.
- Example: `B3/S234` (**Ant Colony**) — same birth rule; live cells survive on 2, 3, or 4 neighbors.
- Named presets (like themes), selected by `activeRule` in config.
- Built-in presets:

| name | rulestring | notes |
|------|------------|-------|
| `conway` | `B3/S23` | classic Conway's Game of Life (default) |
| `ant_colony` | `B3/S234` | Ant Colony Life — expanding edges, settling center |

- Status bar displays the resolved rulestring (e.g. `B3/S23`), not the preset id — see [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md).

### `src/rules.lua` (M2-A)
- Export:
  - `rules` — map of name → `{ name, rulestring, birth, survival }`
  - `get(name)` — resolve preset (fallback to `conway`)
  - `parse(rulestring)` — `Bx/Sy` → birth/survival sets
  - `list()` — optional, for future UI rule picker
- Shipped presets: `conway` (`B3/S23`), `ant_colony` (`B3/S234`).

### `src/grid.lua`
- Expose helpers:
  - `create(rows, cols)`
  - `clear(world)`, `setAlive(world, row, col, alive)`
  - `countNeighbors(world, row, col)`
  - `computeNext(world, rules)`
  - `step(world, rules)`
  - `isAlive(world, row, col)`

## Config keys (this area)

| Key | Default | Phase |
|-----|---------|-------|
| `rows` | `40` | M1 ✓ |
| `cols` | `60` | M1 ✓ |
| `activeRule` | `"conway"` | M2-A ✓ |
| `defaultPattern` | `"glider"` | M2-B ✓ |

## Planned/existing files

| File | Status | Phase |
|------|--------|-------|
| `src/config.lua` | exists | M2-A `activeRule`; M2-B `defaultPattern` |
| `src/grid.lua` | exists | M2-A ✓ rules param; M2-B ✓ removed `seedGlider` |
| `src/rules.lua` | exists | M2-A ✓ |
| `src/patterns.lua` | exists | M2-B ✓; M3-C ✓ shared stamp + RLE resolution |
| `src/patterns/rle.lua` | exists | M3-C ✓ |
| `src/util.lua` | exists | Post-M3 ✓ shared `wrap` helper |
| `patterns/*.lua` | exists (core) | M2-B ✓ |
| `patterns/*.rle` | exists (`pulsar`, `gosper_glider_gun`, `lifeview`) | M3-C ✓ |
| `tests/grid_spec.lua` | exists | M2-A update for rules param |
| `tests/rules_spec.lua` | exists | M2-A ✓ |
| `tests/patterns_spec.lua` | exists | M2-B ✓; M3-C ✓ RLE load path |
| `tests/rle_spec.lua` | exists | M3-C ✓ |

## TODO tracking

### Milestone 1 ✓
- [x] Create minimal LÖVE entry files and module layout (`main.lua`, `conf.lua`, `src/*`)
- [x] Implement world/grid model with toroidal B3/S23 `computeNext`
- [x] Wire load/draw lifecycle and resizable window defaults
- [x] Add plain Lua unit tests for `src/grid.lua` (`tests/run.lua`)

### Milestone 2-A — Rulestrings ✓
- [x] Add `src/rules.lua` — `Bx/Sy` parser and presets (`conway`, `ant_colony`)
- [x] Add `tests/rules_spec.lua`; register in `tests/run.lua`
- [x] Add `activeRule` to `src/config.lua`
- [x] Refactor `grid.computeNext(world, rules)` and `grid.step(world, rules)`
- [x] Update `tests/grid_spec.lua` for explicit rules argument

### Milestone 2-B — Patterns ✓
- [x] Add `defaultPattern` to `src/config.lua`
- [x] Add core `patterns/*.lua` (`glider`, `blinker`, `beacon`)
- [x] Add `src/patterns.lua` loader (`list`, `get`, `apply`)
- [x] Wire `main.lua` to load `defaultPattern` with active rules
- [x] Remove `grid.seedGlider`
- [x] Add extended pattern `pulsar` (via RLE in M3-C)
- [ ] Add `random_soup` — optional procedural seed

### Milestone 3-C — RLE import ✓
- [x] Extract shared `patterns.stamp(world, pattern)` and keep Lua pattern path intact
- [x] Add `src/patterns/rle.lua` parser and `tests/rle_spec.lua`
- [x] Extend `patterns.get` to resolve `patterns/<id>.rle` via `love.filesystem.read`
- [x] Add shipped `patterns/pulsar.rle`, `patterns/gosper_glider_gun.rle`, and `patterns/lifeview.rle`
- [x] Extend tests for RLE loading path and register RLE spec in `tests/run.lua`
- [x] Add `gosper_glider_gun` pattern (RLE, M3-C)
