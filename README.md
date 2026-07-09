# Love Life

[![Tests](https://github.com/ridespirals/love-life/actions/workflows/test.yml/badge.svg)](https://github.com/ridespirals/love-life/actions/workflows/test.yml)

Cellular Automata in Lua LÖVE

## Run

From the repo root:

```bash
love .
```

Requires [LÖVE 11.x](https://love2d.org/).

**Optional shortcut:** with [direnv](https://direnv.net/) installed and hooked into your shell (`eval "$(direnv hook zsh)"` / `bash`), running `direnv allow` once in this repo puts `bin/` on your `$PATH` while you're inside it. Then plain `run` and `check` work as one-word commands (see [`.envrc`](.envrc), `bin/run`, `bin/check`). `check` is used instead of `test` because `test` is a shell builtin that would always shadow a same-named script. This is purely a local convenience — `love .` and `lua tests/run.lua` always work without it.

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

Or, with direnv set up (see [Run](#run) above): `check`.

Coverage: `src/grid.lua`, `src/rules.lua`, `src/patterns.lua`, `src/patterns/rle.lua`, `src/playback.lua`, `src/layout.lua`, `src/step_animation.lua`, `src/ui/statusbar.lua`, and `src/themes.lua` — toroidal wrap, rulestring parsing, Lua/RLE pattern loading, playback timer state, auto-fit resize math, step morph timing, status bar layout, and theme registry.

CI runs the same command on every push to `main` and on pull requests via [`.github/workflows/test.yml`](.github/workflows/test.yml).

## Configuration

Edit `src/config.lua` (values like `activeTheme` and `defaultPattern` are user-editable; shipped defaults may differ from examples below):

| Key | Purpose |
|-----|---------|
| `rows`, `cols`, `tileSize` | Cell pixels (`tileSize`) and starting grid hints; `rows`/`cols` are recomputed at runtime to fill the window (shipped `tileSize`: `24`) |
| `activeTheme` | Theme preset id from `themes.list()` (default `"classic"`; shipped default may differ) |
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
| `accentBlendAlive` | Blend toward theme `accent` on alive-tile extrusion shadows (0–1; default `0.72`) |
| `accentBlendDead` | Blend toward theme `accent` on dead tiles and pane chrome (0–1; default `0.42`) |

**Themes:** 21 built-in presets in `src/themes.lua` — `classic`, `zenburn`, `solarized`, `monokai`, `gruvbox`, `dracula`, `nord`, and others mapped from [vim-colorschemes](https://github.com/flazz/vim-colorschemes). Each defines `alive`, `dead`, `grid`, and an optional vim-syntax `accent` used for colored 3D shadows. Run `lua -e 'for _,n in ipairs(require("src.themes").list()) do print(n) end'` to list ids.

See `PLAN.md` for the full implementation roadmap.

## Status

**Milestone 1 complete** — grid render, themes, configurable rules, and next-generation preview foundation.

**Milestone 2-A/B/C complete** — rulestring presets, pattern loader, and status bar stats display (`src/rules.lua`, `src/patterns.lua`, `src/ui/statusbar.lua`).

**Milestone 3-A/B/C complete** — playback engine, interactive status bar controls, and RLE import are wired.

**Post-M3 polish** — auto-fit grid on load and resize; generation counter on status bar; fast mode (`f` hold); Restart control.

**v1.0** — first tagged release with `.love` and platform packages via GitHub Actions.

**v1.1.0** — square preview→commit step animation, idle next-state markers, pseudo-3D alive tiles; fullscreen (F11 / Alt+Enter).

**v1.2 (in progress)** — Phase 1 settings UI shell + Phase 2 rule/theme pickers (Apply).

**Next:** Phase 3 userspace save/load — see [`PLAN.md`](PLAN.md).

Deferred: history stack (step backward), RLE export, import UI, **pattern grouping by type** (still lifes, oscillators, spaceships, linear growth, …), external RLE repo sync, video export.

## Status bar

**Clickable chips (left):** `Rule`, `Theme`, `Pattern`, `Size` — open a pane docked above the chip; the rest of the screen dims. `Gen` is read-only.

**Buttons (right):** `Settings`, `Play`, `Pause`, `Step`, `Restart` (mouse click). Play shows `Play +` while fast mode is held (`f` or mouse held on Play).

While a pane is open, playback **keyboard** shortcuts are disabled; the simulation **keeps running** if it was already playing. Text input works in Rule/Theme fields. Press `Esc`, click outside the pane, or click × to close. Clicking another stat chip switches panes.

**Rule pane:** pick a preset or edit the `Bx/Sy` rulestring, then **Apply** (pauses playback and recomputes next-state preview; board cells are kept).

**Theme pane:** pick a preset or edit hex colors (`alive`, `dead`, `grid`, `background`, optional `accent`), then **Apply** (live swap while playback continues). Leave `accent` blank to fall back to plain shadow shading.

## Controls

- `space`: toggle play/pause (disabled while a pane is open — mouse Play/Pause still work)
- `s`: play
- `p`: pause
- `n` or `Right Arrow`: step forward one generation
- `r`: restart (reload `defaultPattern`, pause playback)
- `Esc` or click outside the pane: close open settings pane
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
