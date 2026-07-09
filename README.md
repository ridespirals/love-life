# Love Life

[![Tests](https://github.com/ridespirals/love-life/actions/workflows/test.yml/badge.svg)](https://github.com/ridespirals/love-life/actions/workflows/test.yml)

Cellular Automata in Lua LÖVE

## Run

From the repo root:

```bash
love .
```

Requires [LÖVE 11.x](https://love2d.org/).

## Releases

Pre-built downloads are published on [GitHub Releases](https://github.com/ridespirals/love-life/releases).

| Asset | How to run |
|-------|------------|
| `love-life.love` | `love love-life.love` (requires LÖVE 11.x installed) |
| `love-life_win32.zip` / `love-life_win64.zip` | Unzip and run `love-life.exe` |
| `love-life_macos.zip` | Unzip and open `love-life.app` |
| `love-life_linux_x86_64.zip` | Unzip and run `love-life-x86_64.AppImage` |

**Maintainers:** after merging to `main`, tag and push to trigger the release workflow:

```bash
git tag v1.1.0
git push origin v1.1.0
```

CI runs tests, builds packages via [`.github/workflows/release.yml`](.github/workflows/release.yml), and publishes assets with [action-gh-release](https://github.com/softprops/action-gh-release).

## Test

Pure Lua tests for simulation logic (no LÖVE required):

```bash
lua tests/run.lua
```

Coverage: `src/grid.lua`, `src/rules.lua`, `src/patterns.lua`, `src/patterns/rle.lua`, `src/playback.lua`, `src/layout.lua`, `src/step_animation.lua`, and `src/ui/statusbar.lua` — toroidal wrap, rulestring parsing, Lua/RLE pattern loading, playback timer state, auto-fit resize math, step morph timing, and status bar layout.

CI runs the same command on every push to `main` and on pull requests via [`.github/workflows/test.yml`](.github/workflows/test.yml).

## Configuration

Edit `src/config.lua` (values like `activeTheme` and `defaultPattern` are user-editable; shipped defaults may differ from examples below):

| Key | Purpose |
|-----|---------|
| `rows`, `cols`, `tileSize` | Cell pixels (`tileSize`) and starting grid hints; `rows`/`cols` are recomputed at runtime to fill the window (shipped `tileSize`: `24`) |
| `activeTheme` | `classic`, `zenburn`, or `solarized` |
| `activeRule` | Rule preset: `conway` (default) or `ant_colony` |
| `defaultPattern` | Pattern id to load on start (`.lua` first, then `.rle` fallback by same id) |
| `stepInterval` | Default auto-step interval (`0.10`) |
| `statusBarHeight` | Bottom bar reserve (pixels) |
| `paneWidth` | Minimum docked pane width (pixels; default `360`; grows with content) |
| `paneHeight` | Minimum docked pane height when open (pixels; default `120`; grows with content) |
| `paneBackdropAlpha` | Dim overlay strength over the full window when a pane is open (0–1; default `0.55`) |
| `paneScreenMargin` | Minimum inset from window edges when positioning panes (default `8`) |
| `stepAnimEnabled` | Enable step morph animation (`true`) |
| `stepAnimPreviewSec` | Preview-marker phase duration (seconds; default `0.08`) |
| `stepAnimCommitSec` | Square grow/shrink commit phase (seconds; default `0.12`) |
| `previewDotScale` | Preview square size as fraction of tile face (default `0.15`) |
| `previewDotMinPx` | Minimum preview square side length in pixels (default `4`) |
| `tileDepthAlivePx` | Pseudo-3D extrusion depth for alive tiles in pixels (default `3`; `0` disables) |
| `tileDepthDeadPx` | Pseudo-3D extrusion for dead tiles (default `0` = flat) |

See `PLAN.md` for the full implementation roadmap.

## Status

**Milestone 1 complete** — grid render, themes, configurable rules, and next-generation preview foundation.

**Milestone 2-A/B/C complete** — rulestring presets, pattern loader, and status bar stats display (`src/rules.lua`, `src/patterns.lua`, `src/ui/statusbar.lua`).

**Milestone 3-A/B/C complete** — playback engine, interactive status bar controls, and RLE import are wired.

**Post-M3 polish** — auto-fit grid on load and resize; generation counter on status bar; fast mode (`f` hold); Restart control.

**v1.0** — first tagged release with `.love` and platform packages via GitHub Actions.

**v1.1.0** — square preview→commit step animation, idle next-state markers, pseudo-3D alive tiles; fullscreen (F11 / Alt+Enter).

**v1.2 (in progress)** — Phase 1 settings UI shell (clickable chips, docked panes).

**Next:** Phase 2 rule/theme pickers — see [`PLAN.md`](PLAN.md).

Deferred: history stack (step backward), RLE export, import UI, **pattern grouping by type** (still lifes, oscillators, spaceships, linear growth, …), external RLE repo sync, video export.

## Status bar

**Clickable chips (left):** `Rule`, `Theme`, `Pattern`, `Size` — open a pane docked above the chip; the rest of the screen dims. `Gen` is read-only.

**Buttons (right):** `Settings`, `Play`, `Pause`, `Step`, `Restart` (mouse click). Play shows `Play +` while fast mode is held (`f` or mouse held on Play).

While a pane is open, playback keyboard shortcuts are disabled; press `Esc` or click × to close.

## Controls

- `space`: toggle play/pause (disabled while a pane is open)
- `s`: play
- `p`: pause
- `n` or `Right Arrow`: step forward one generation
- `r`: restart (reload `defaultPattern`, pause playback)
- `Esc`: close open settings pane
- Hold `f` or hold **Play** (mouse): temporary fast mode (`Play +`, uses `0.05` while held)
- `F11` or `Alt+Enter`: toggle fullscreen (restarts simulation, same as window resize)
- `q`: quit app
- Status bar chips: open Rule / Theme / Pattern / Settings panes (mouse click)
- Status bar buttons: `Settings`, `Play`, `Pause`, `Step`, `Restart` (mouse click)

Resizing the window or toggling fullscreen recomputes grid dimensions to fill the viewport and restarts the simulation from `defaultPattern` (generation resets to 0, playback pauses).

## RLE Support

- `defaultPattern` now resolves in order:
  1. `patterns/<id>.lua`
  2. `patterns/<id>.rle`
  3. fallback to `glider`
- Shipped patterns: 3 Lua (`glider`, `blinker`, `beacon`) and 16 `.rle` assets (spaceships, oscillators, guns/rakes, methuselahs, etc.). Set `defaultPattern` to any catalog id from `patterns.list()`.
- RLE `rule = ...` headers are parsed, but simulation still uses `activeRule` from config.

## Features

1. Auto-fit board size to window (`tileSize` fixed; `rows`/`cols` derived on load and resize)
2. **Step animation** — idle preview dots for next state; on step, square preview → commit morph with pseudo-3D tiles
3. Multiple color schemes (themes)
4. Alternate rule strings (`Bx/Sy`)
  - `B` digits: neighbor counts that birth a dead cell
  - `S` digits: neighbor counts that let a live cell survive
  - Classic: `B3/S23` — birth on 3; survive on 2 or 3
  - Ant Colony: `B3/S234` — birth on 3; survive on 2, 3, or 4
5. In-game settings UI, pattern editor, and userspace save/load (Phases 1–5 — see `PLAN.md`)
6. Video export (deferred)

### Attribution

The idea for this came from the youtube video [The Conway Multiverse](https://www.youtube.com/watch?v=QK_KZv-YyOc&pp=ygURY29ud2F5IG11bHRpdmVyc2U%3D) by user [carykh](https://www.youtube.com/@carykh)
