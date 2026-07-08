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

Coverage today is `src/grid.lua`: B3/S23 birth/survival/death, toroidal neighbor wrap, simultaneous update, and blinker period-2 via `grid.step`. Rulestring tests land in Milestone 2-A.

## Configuration

Edit `src/config.lua`:

| Key | Purpose |
|-----|---------|
| `rows`, `cols`, `tileSize` | Board size and cell pixels |
| `activeTheme` | `classic`, `zenburn`, or `solarized` |
| `activeRule` | Rule preset: `conway` (default) or `ant_colony` — wired in M2-A |
| `defaultPattern` | Pattern id to load on start — wired in M2-B |
| `stepInterval` | Seconds between auto-steps when playing — used in M3 |
| `statusBarHeight` | Bottom bar reserve (pixels) |

See `PLAN.md` for the full implementation roadmap.

## Status

**Milestone 1 complete** — grid render, themes, toroidal B3/S23 preview, glider demo seed.

**Next: Milestone 2-A** — configurable rulestrings (`src/rules.lua`).

Planned after that: pattern loader (M2-B), read-only status bar (M2-C), playback (M3).

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
