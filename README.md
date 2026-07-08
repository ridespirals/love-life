# Love Life

[![Tests](https://github.com/ridespirals/love-life/actions/workflows/test.yml/badge.svg)](https://github.com/ridespirals/love-life/actions/workflows/test.yml)

Cellular Automata in Lua LÖVE

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

Coverage: `src/grid.lua`, `src/rules.lua`, `src/patterns.lua`, `src/patterns/rle.lua`, `src/playback.lua`, `src/layout.lua`, and `src/ui/statusbar.lua` — toroidal wrap, rulestring parsing, Lua/RLE pattern loading, playback timer state, auto-fit resize math, and status bar layout.

CI runs the same command on every push to `main` and on pull requests via [`.github/workflows/test.yml`](.github/workflows/test.yml).

## Configuration

Edit `src/config.lua` (values like `activeTheme` and `defaultPattern` are user-editable; shipped defaults may differ from examples below):

| Key | Purpose |
|-----|---------|
| `rows`, `cols`, `tileSize` | Cell pixels (`tileSize`) and starting grid hints; `rows`/`cols` are recomputed at runtime to fill the window |
| `activeTheme` | `classic`, `zenburn`, or `solarized` |
| `activeRule` | Rule preset: `conway` (default) or `ant_colony` |
| `defaultPattern` | Pattern id to load on start (`.lua` first, then `.rle` fallback by same id) |
| `stepInterval` | Default auto-step interval (`0.10`) |
| `statusBarHeight` | Bottom bar reserve (pixels) |
| `previewDotScale` | Preview dot radius as fraction of tile size |
| `previewDotMinRadiusPx` | Minimum preview dot radius (pixels) |
| `previewDotMaxRadiusPx` | Maximum preview dot radius (pixels) |

See `PLAN.md` for the full implementation roadmap.

## Status

**Milestone 1 complete** — grid render, themes, configurable rules, and next-generation preview foundation.

**Milestone 2-A/B/C complete** — rulestring presets, pattern loader, and status bar stats display (`src/rules.lua`, `src/patterns.lua`, `src/ui/statusbar.lua`).

**Milestone 3-A/B/C complete** — playback engine, interactive status bar controls, and RLE import are wired.

**Post-M3 polish** — auto-fit grid on load and resize; generation counter on status bar; fast mode (`f` hold); Restart control.

**Next:** prioritize future features (tile-size hotkeys, history, picker, runtime switching, export).

## Status bar

**Display:** `Rule`, `Size` (`rows×cols`), `Theme`, `Gen` (generation counter).

**Buttons:** `Play`, `Pause`, `Step`, `Restart` (mouse click). Play shows `Play +` while fast mode is held.

## Controls

- `space`: toggle play/pause
- `s`: play
- `p`: pause
- `n` or `Right Arrow`: step forward one generation
- `r`: restart (reload `defaultPattern`, pause playback)
- Hold `f`: temporary fast mode (`Play +`, uses `0.05` while held)
- `q`: quit app
- Status bar buttons: `Play`, `Pause`, `Step`, `Restart` (mouse click)

Resizing the window recomputes grid dimensions to fill the viewport and restarts the simulation from `defaultPattern` (generation resets to 0, playback pauses).

## RLE Support

- `defaultPattern` now resolves in order:
  1. `patterns/<id>.lua`
  2. `patterns/<id>.rle`
  3. fallback to `glider`
- Shipped `.rle` assets include `pulsar`, `gosper_glider_gun`, and `lifeview`.
- RLE `rule = ...` headers are parsed, but simulation still uses `activeRule` from config.

## Features

1. Auto-fit board size to window (`tileSize` fixed; `rows`/`cols` derived on load and resize)
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
