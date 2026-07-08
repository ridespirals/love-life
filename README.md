# Love Life

Conway's Game of Life in Lua LÖVE

## Run

From the repo root:

```bash
love .
```

Requires [LÖVE 11.x](https://love2d.org/).

## Test

Pure Lua tests for simulation logic (no LÖVE required):

```bash
lua tests/run.lua
```

Coverage: `src/grid.lua`, `src/rules.lua`, `src/patterns.lua`, `src/patterns/rle.lua`, and `src/playback.lua` — B3/S23 simulation behavior, toroidal wrap, rulestring parsing, Lua/RLE pattern loading, and playback timer state transitions.

## Configuration

Edit `src/config.lua`:

| Key | Purpose |
|-----|---------|
| `rows`, `cols`, `tileSize` | Board size and cell pixels |
| `activeTheme` | `classic`, `zenburn`, or `solarized` |
| `activeRule` | Rule preset: `conway` (default) or `ant_colony` |
| `defaultPattern` | Pattern id to load on start (`.lua` first, then `.rle` fallback by same id) |
| `stepInterval` | Default auto-step interval (`0.10`) |
| `statusBarHeight` | Bottom bar reserve (pixels) |

See `PLAN.md` for the full implementation roadmap.

## Status

**Milestone 1 complete** — grid render, themes, toroidal B3/S23 preview foundation.

**Milestone 2-A/B/C complete** — configurable rulestrings, pattern loader, and read-only status bar (`src/rules.lua`, `src/patterns.lua`, `src/ui/statusbar.lua`).

**Milestone 3-A/B/C complete** — playback engine, status bar controls, and RLE import are wired.

**Next:** prioritize future features (history, picker, runtime switching, export).

## Controls

- `space`: toggle play/pause
- `s`: play
- `p`: pause
- `n` or `Right Arrow`: step forward one generation
- `r`: restart (reload `defaultPattern`, pause playback)
- Hold `f`: temporary fast mode (`Play +`, uses `0.05` while held)
- `q`: quit app
- Status bar buttons: `Play`, `Pause`, `Step`, `Restart` (mouse click)

## RLE Support

- `defaultPattern` now resolves in order:
  1. `patterns/<id>.lua`
  2. `patterns/<id>.rle`
  3. fallback to `glider`
- Shipped `.rle` assets include `pulsar`, `gosper_glider_gun`, and `lifeview`.
- RLE `rule = ...` headers are parsed, but simulation still uses `activeRule` from config.

## Features

1. Configurable board sizes
2. Animations and next-generation preview dots
3. Multiple color schemes (themes)
4. Alternate rule strings (`Bx/Sy`)
  - `B` digits: neighbor counts that birth a dead cell
  - `S` digits: neighbor counts that let a live cell survive
  - Classic: `B3/S23` — birth on 3; survive on 2 or 3
  - Ant Colony: `B3/S234` — birth on 3; survive on 2, 3, or 4
5. Video export (planned)

### Attribution

The idea for this came from the youtube video [The Conway Multiverse](https://www.youtube.com/watch?v=QK_KZv-YyOc&pp=ygURY29ud2F5IG11bHRpdmVyc2U%3D) by user [carykh](https://www.youtube.com/@carykh)
