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
git tag v1.4.0
git push origin v1.4.0
```

CI runs tests, builds packages via [`.github/workflows/release.yml`](.github/workflows/release.yml), and publishes assets with [action-gh-release](https://github.com/softprops/action-gh-release).

## Test

Pure Lua tests for simulation logic (no LÖVE required):

```bash
lua tests/run.lua
```

Or, with direnv set up (see [Run](#run) above): `check`.

Coverage: `src/grid.lua`, `src/rules.lua`, `src/patterns.lua`, `src/patterns/rle.lua`, `src/playback.lua`, `src/layout.lua`, `src/step_animation.lua`, `src/ui/statusbar.lua`, `src/ui/pane.lua`, `src/ui/text_field.lua`, `src/ui/button_fx.lua`, `src/session.lua`, `src/ui/panes/*` (via `phase2_spec` / `phase4_spec` / `phase5_spec`), `src/input/board.lua`, `src/themes.lua`, `src/userdata.lua`, and `src/color.lua` — toroidal wrap, rulestring parsing, Lua/RLE pattern loading, pattern export/merge, board drawing math, auto-fit and letterbox layout, playback timer state, step morph timing, status bar/pane hit regions, session drafts, text-field editing, Play/Pause button fx math, theme registry, and userspace serialize/save round-trips.

CI runs the same command on every push to `main` and on pull requests via [`.github/workflows/test.yml`](.github/workflows/test.yml).

## Configuration

Edit `src/config.lua` (values like `activeTheme` and `defaultPattern` are user-editable; shipped defaults may differ from examples below):

| Key | Purpose |
|-----|---------|
| `rows`, `cols`, `tileSize` | Cell pixels (`tileSize`) and starting grid hints; `rows`/`cols` are recomputed at runtime to fill the window (shipped `tileSize`: `24`) |
| `activeTheme` | Theme preset id from `themes.list()` (shipped default `"solarized"`) |
| `activeRule` | Rule preset: `conway` (default) or `ant_colony` |
| `defaultPattern` | Pattern id to load on start (shipped default `"lifeview"`; `.lua` first, then `.rle` by same id) |
| `stepInterval` | Default auto-step interval (`0.10`) |
| `statusBarHeight` | Bottom bar reserve (pixels) |
| `paneWidth` | Minimum docked pane width (pixels; default `360`; grows with content) |
| `paneHeight` | Minimum docked pane height when open (pixels; default `120`; grows with content) |
| `paneBackdropAlpha` | Dim overlay strength over the full window when a pane is open (0–1; default `0.55`) |
| `paneScreenMargin` | Minimum inset from window edges when positioning panes (default `8`) |
| `gridMode` | `"auto"` (refit rows/cols on resize) or `"forced"` (fixed grid, letterboxed) |
| `forcedRows`, `forcedCols`, `forcedTileSize` | Starting hints for forced mode (defaults mirror `rows`/`cols`/`tileSize`) |
| `stepAnimEnabled` | Enable step morph animation (`true`); Settings pane On/Off |
| `stepAnimMinTileSize` | Minimum tile size (px) before morph animations run (default `6`) |
| `stepAnimPreviewSec` | Preview-marker phase duration (seconds; default `0.08`) |
| `stepAnimCommitSec` | Square grow/shrink commit phase (seconds; default `0.12`) |
| `previewDotScale` | Preview square size as fraction of tile face (default `0.15`) |
| `previewDotMinPx` | Minimum preview square side length in pixels (default `4`) |
| `tileDepthAlivePx` | Pseudo-3D extrusion depth for alive tiles in pixels (default `3`; `0` disables) |
| `tileDepthDeadPx` | Pseudo-3D extrusion for dead tiles (default `0` = flat) |
| `buttonFxEnabled` | Play/Pause expanding-outline transition (`true`) |
| `buttonFxDurationSec` | How long each trail expands/fades (default `0.4`) |
| `buttonFxTrailCount` | Number of delayed trail copies after the lead outline (default `3`) |
| `buttonFxTrailSpacingSec` | Delay between trail copies (default `0.05`) |
| `buttonFxExpandPx` | How far outlines grow outward from the button (default `10`) |
| `cameraZoomMin` | `0.25` | Zoom out floor |
| `cameraZoomMax` | `4` | Zoom in ceiling |
| `cameraZoomStep` | `1.25` | Multiplier per zoom key / future toolbar +/− |
| `cameraDefaultZoom` | `1` | Load / reset zoom |
| `cameraPanStepPx` | `40` | Screen pixels per Shift+Arrow pan (debug keys) |
| `toolbarMargin` | `12` | Floating toolbar inset from window corner |
| `toolbarButtonSize` | `32` | Toolbar button side length (px) |
| `accentBlendAlive` | Blend toward theme `accent` on alive-tile extrusion shadows (0–1; default `0.72`) |
| `accentBlendDead` | Blend toward theme `accent` on dead tiles and pane chrome (0–1; default `0.42`) |

**Themes:** 21 built-in presets in `src/themes.lua` — `classic`, `zenburn`, `solarized`, `monokai`, `gruvbox`, `dracula`, `nord`, and others mapped from [vim-colorschemes](https://github.com/flazz/vim-colorschemes). Each defines `alive`, `dead`, `grid`, and an optional vim-syntax `accent` used for colored 3D shadows. Run `lua -e 'for _,n in ipairs(require("src.themes").list()) do print(n) end'` to list ids.

See [`plan/README.md`](plan/README.md) for the full implementation roadmap, split by application area.

## Status

**Milestone 1 complete** — grid render, themes, configurable rules, and next-generation preview foundation.

**Milestone 2-A/B/C complete** — rulestring presets, pattern loader, and status bar stats display (`src/rules.lua`, `src/patterns.lua`, `src/ui/statusbar.lua`).

**Milestone 3-A/B/C complete** — playback engine, interactive status bar controls, and RLE import are wired.

**Post-M3 polish** — auto-fit grid on load and resize; generation counter on status bar; fast mode (`f` hold); Restart control.

**v1.0** — first tagged release with `.love` and platform packages via GitHub Actions.

**v1.1.0** — square preview→commit step animation, idle next-state markers, pseudo-3D alive tiles; fullscreen (F11 / Alt+Enter).

**v1.2.0** — Phase 1 settings UI shell + Phase 2 rule/theme pickers (rule Apply; theme auto-apply).

**v1.3.0** — Phase 3 userspace save/load (rules, themes, patterns); HSV color picker; Phase 4 pattern picker + paused board drawing (left-drag toggle, right-drag erase, Save to userspace).

**v1.4.0** — Phase 5 grid settings (Auto/Forced, tile/rows/cols, Animate On/Off); shared text-field editing (caret, selection); Enter applies rule/pattern/grid drafts; grid Apply and auto resize migrate the live board without pausing or resetting generation; step morphs skip when disabled or tile size is below 6 px.

**Next:** Phase 8 controller input (backlog) — see [`plan/10-controller-input.md`](plan/10-controller-input.md). Camera + floating toolbar (Phases 6–7) are on the working branch.

**Board drawing:** select the **Draw** tool on the floating toolbar (upper-left); selecting it pauses. Left-drag paints alive; right-drag erases. **Pan** tool click-drags the camera without pausing. **Zoom +/−** scale around the view center.

Deferred: history stack (step backward), RLE export, import UI, **pattern grouping by type** (still lifes, oscillators, spaceships, linear growth, …), external RLE repo sync, video export.

## Status bar

**Clickable chips (left):** `Rule`, `Theme`, `Pattern`, `Size` — open a pane docked above the chip; the rest of the screen dims. `Gen` is read-only.

**Buttons (right):** `Settings`, `Play`, `Pause`, `Step`, `Restart` (mouse click). Play shows `Play +` while fast mode is held (`f` or mouse held on Play). Play, Pause, Step, and Restart animate an expanding outline with fading trails on activation (config: `buttonFx*`).

While a pane is open, playback **keyboard** shortcuts are disabled; the simulation **keeps running** if it was already playing. Text fields support caret, selection, and clipboard-style editing. Press `Esc`, click outside the pane, or click × to close. Clicking another stat chip switches panes.

**Rule pane:** pick a preset or edit the `Bx/Sy` rulestring, then **Apply** (pauses playback and recomputes next-state preview; board cells are kept). **Enter** in a text field also applies. Enter a **Name** and **Save** to keep a custom rule in the LÖVE save directory (built-ins cannot be overwritten). **Delete** removes a user-saved rule.

**Theme pane:** pick a preset or click a color field/swatch to open the **HSV color picker** (saturation×value square + hue bar + value slider). Themes apply immediately (live swap while playback continues); the pane stays open so you can browse. Leave `accent` blank / clearable via a white default pick to fall back to plain shadow shading. **Save** / **Delete** work like the rule pane for user themes.

**Pattern pane:** pick a catalog preset, then **Apply** (pauses playback and reloads the board from that pattern). **Enter** in a text field also applies. **Clear** blanks the board for drawing. Enter a **Name** and **Save** to store the current board in the LÖVE save directory (built-ins cannot be overwritten). **Delete** removes a user-saved pattern. Unsaved edits show as `Pattern: custom` on the status bar.

**Board drawing:** select **Draw** on the floating toolbar (pauses). Left-click/drag paints alive; right-click/drag erases. Unsaved edits show as `Pattern: custom` until you Apply a catalog entry or Save.

**Floating toolbar (upper-left):** Pan (default; drag view), Draw (paint cells), Zoom + / −. Hover tooltips follow the cursor. Always visible; does not dim the board.

**Settings pane:** open via **Settings** button or **Size** chip. Choose **Auto** (refit rows/cols to window on resize) or **Forced** (fixed rows/cols/tile with letterbox centering). Edit **Tile** (both modes); **Rows** / **Cols** apply in Forced mode only. **Animate** On/Off toggles step morph animations (animations are skipped automatically when tile size is below `stepAnimMinTileSize`, default 6 px). **Apply** (or **Enter** in a text field) rebuilds the grid while preserving the live board and playback (generation counter unchanged). Fullscreen hint: F11 or Alt+Enter.

## Controls

- `space`: toggle play/pause (disabled while a pane is open — mouse Play/Pause still work)
- `s`: play
- `p`: pause
- `n` or `Right Arrow`: step forward one generation
- `r`: restart (reload applied pattern; unsaved `custom` falls back to `defaultPattern`, pause playback)
- `Esc` or click outside the pane: close open settings pane
- Hold `f` or hold **Play** (mouse): temporary fast mode (`Play +`, uses `0.05` while held)
- `F11` or `Alt+Enter`: toggle fullscreen (in auto mode, refits grid and migrates the live board; forced mode recenters only)
- `Enter` (in a pane text field): apply rule, pattern, or grid draft (same as each pane's Apply button)
- `q`: quit app
- Status bar chips: open Rule / Theme / Pattern / Settings panes (mouse click)
- Status bar buttons: `Settings`, `Play`, `Pause`, `Step`, `Restart` (mouse click)
- **Toolbar:** Pan / Draw / Zoom+/− (mouse); Draw required to paint cells

Resizing the window or toggling fullscreen: in **auto** mode, refits grid dimensions and migrates the live board (playback and generation continue). In **forced** mode, only recenters the board — dimensions unchanged.

## RLE Support

- `defaultPattern` now resolves in order:
  1. `patterns/<id>.lua`
  2. `patterns/<id>.rle`
  3. fallback to `glider`
- Shipped patterns: 3 Lua (`glider`, `blinker`, `beacon`) and 16 `.rle` assets (spaceships, oscillators, guns/rakes, methuselahs, etc.). Set `defaultPattern` to any catalog id from `patterns.list()`.
- RLE `rule = ...` headers are parsed, but simulation still uses `activeRule` from config.

## Features

1. Auto-fit board size to window (`tileSize` fixed; `rows`/`cols` derived on load and resize)
2. **Step animation** — idle preview dots for next state; on step, square preview → commit morph with pseudo-3D tiles (toggle in Settings; skipped below 6 px tile size)
3. Multiple color schemes (themes)
4. Alternate rule strings (`Bx/Sy`)
  - `B` digits: neighbor counts that birth a dead cell
  - `S` digits: neighbor counts that let a live cell survive
  - Classic: `B3/S23` — birth on 3; survive on 2 or 3
  - Ant Colony: `B3/S234` — birth on 3; survive on 2, 3, or 4
5. In-game settings UI + rule/theme/pattern pickers + userspace save/load + board drawing + grid modes (Phases 1–5 ✓); camera/toolbar backlog (Phases 6–8 — see [`plan/README.md`](plan/README.md))
6. Video export (deferred)

### Attribution

The idea for this came from the youtube video [The Conway Multiverse](https://www.youtube.com/watch?v=QK_KZv-YyOc&pp=ygURY29ud2F5IG11bHRpdmVyc2U%3D) by user [carykh](https://www.youtube.com/@carykh)
