# AGENTS

## Project Context
- Project: `love-life`
- Purpose: Conway's Game of Life in Lua using LÖVE.
- **Current phase:** Phase 5 ✓ (grid settings); **Phase 6** (camera/viewport, backlog) is next unless resequenced. v1.4.0 ready to tag.
- **Active branch:** `main`
- **Last merge:** PR #3 `phase-2-rule-theme` (rule/theme pickers + swatches + `layoutGrid`).
- **Backlog captured (not started, not sequenced):** camera/viewport, floating toolbar (pan/draw/zoom), controller input layer, reusable button transition fx — see "Backlog: camera, toolbar, controller" below and `plan/08-camera-and-viewport.md`, `plan/09-toolbar-and-drawing-tools.md`, `plan/10-controller-input.md`.
- A separate `moonscript` experiment branch exists (full logic port to MoonScript); the evaluation doc lived on that branch and is **not** part of the primary Lua roadmap — ignore unless explicitly revisited.

## Handoff (start here after restart)
- **Run:** `lua tests/run.lua` (16 specs) · `love .` (visual smoke)
- **Shipped UI shell (Phase 1):** `src/ui/pane.lua` (pane docked above opener, full-window dim spotlight), clickable status-bar chips, `Settings` button, `src/session.lua` scaffold; grid does not shift when a pane opens.
- **Shipped pickers (Phase 2):** `src/ui/panes/rule_pane.lua`, `theme_pane.lua` — rule pane has preset buttons, text field, Apply; theme pane auto-applies on preset click or valid hex edit (live swap, pane stays open) with **color swatches** beside each draft field; `src/ui/pane_widgets.lua` shared controls including `layoutGrid`.
- **Shipped persistence (Phase 3):** `src/userdata.lua` (serialize/save/load under LÖVE save dir); `rules`/`themes`/`patterns` merge user presets; Rule/Theme/Pattern panes have Name + Save / Delete (built-ins read-only).
- **Shipped pattern picker + drawing (Phase 4):** `src/ui/panes/pattern_pane.lua` — catalog grid, Apply/Clear/Save/Delete; `src/input/board.lua` — paused left-drag toggle / right-drag erase; `patterns.fromWorld` export; unsaved edits tracked as `custom` applied id.
- **Color model:** canonical colors are LÖVE RGB tables with channels in `[0, 1]` (`src/color.lua`). Hex is interchange for UI fields and builtin theme definitions; userspace theme files store float RGB (legacy hex still loads). HSV color picker dialog (`src/ui/color_picker.lua`) opens from theme pane hex fields/swatches.
- **Shipped animation (Phase 0):** `src/step_animation.lua` (preview → commit phases), `src/renderer.lua` (square morph + 3D extrusion + idle markers), wired in `main.lua`.
- **Config knobs:** `src/config.lua` — `paneWidth`, `paneHeight`, `paneBackdropAlpha`, `stepAnimPreviewSec`, …
- **Do not re-litigate Phase 0 visuals** without explicit ask — settled after circle → square → 3D + idle-preview iterations.
- **Shipped grid settings (Phase 5):** `src/ui/panes/settings_pane.lua` — Auto/Forced mode, tile/rows/cols fields, Apply; `layout.computeBoardLayout` letterbox centering; auto resize refits grid, forced resize only recenters.
- **Phase 6+ scope:** Camera/viewport, floating toolbar, controller input — backlog. See `plan/08-camera-and-viewport.md`.
- **Avoid parallelizing** large renderer/main.lua work with unrelated features on one branch.

## Execution Order
Complete phases in order; each leaves the app runnable and tests green.

| Phase | Focus |
|-------|-------|
| M1 ✓ | Render baseline, grid tests |
| **M2-A** ✓ | `src/rules.lua`, wire `grid.computeNext(world, rules)` |
| **M2-B** ✓ | `patterns/`, loader, remove `seedGlider` |
| **M2-C** ✓ | Status bar stats display |
| **M3-A** ✓ | `src/playback.lua`, `love.update` |
| **M3-B** ✓ | Status bar controls, README |
| **M3-C** ✓ | RLE parser + `.rle` pattern resolution |
| **Phase 0** ✓ | Generation step animation (square preview → commit morph) |
| **Phase 1** ✓ | UI shell (pane manager, clickable chips, Settings button) |
| **Phase 2** ✓ | Rule and theme pickers (rule Apply; theme auto-apply) |
| **Phase 3** ✓ | Userspace save/load (`src/userdata.lua`) |
| **Phase 4** ✓ | Pattern picker + board drawing |
| **Phase 5** ✓ | Grid settings (auto vs forced, letterbox) |
| **Phase 6** (backlog) | Camera & viewport — pan/zoom, world ≠ visible area (`src/camera.lua`) |
| **Phase 7** (backlog) | Floating toolbar — pan tool, draw tool, zoom +/− (`src/ui/toolbar.lua`) |
| **Phase 8** (backlog) | Controller input layer — unified mouse/keyboard/gamepad actions (`src/input/controller.lua`) |

Phase 0 ✓ · Phase 1 ✓ · Phase 2 ✓ · Phase 3 ✓ · Phase 4 ✓ · Phase 5 ✓. **Next:** Phase 6 (camera/viewport, backlog) or resequence per `plan/README.md`.

See [`plan/README.md`](plan/README.md) for the plan directory overview (checkpoints, vision diagram, and file-level detail split by application area).

## Product Direction
- Build a configurable board of square tiles representing world state.
- Grid `rows`/`cols` **auto-fit** the window at load and on resize (see `src/layout.lua`); config values are starting hints for initial window sizing.
- Cell states: alive, dead.
- Toroidal universe (edges wrap).
- Visuals use named **themes** (colors only, not sizes).
- Built-in themes: 21 presets in `src/themes.lua` (`classic`, `zenburn`, `solarized`, plus vim-derived schemes such as `monokai`, `gruvbox`, `dracula`, `nord`, …). Each theme has `alive`, `dead`, `grid`, `background`, and optional `accent` (vim syntax hue for pseudo-3D extrusion shadows).
- Default active theme in shipped `src/config.lua`: `solarized` (product direction still treats `classic` as the reference preset).
- Default load pattern in shipped `src/config.lua`: `lifeview` (`patterns.lua` still falls back to `glider` for unknown ids).

## Post-1.0 Product Direction
- Status bar becomes the **primary control surface**: clickable chips open docked panes above the bar.
- **Draft vs save:** Theme drafts auto-apply while editing; Rule, Pattern, and Grid use explicit Apply. Save writes to the LÖVE save directory (`patterns/`, `rules/`, `themes/`).
- **Grid modes:** `"auto"` (current resize behavior) or `"forced"` (fixed rows/cols/tileSize with letterbox centering).
- **Fullscreen:** F11 and Alt+Enter toggle (`main.lua`); keyboard-only. Triggers `love.resize` (auto mode migrates live board; forced mode recenters only).
- Board drawing and editing require paused playback.
- **Playback continuity:** opening a pane does **not** pause the simulation. Theme selection auto-applies as a live visual swap while play continues. Rule **Apply** pauses and recomputes next-state preview (cells preserved). Pattern **Apply** pauses and reloads the board. Grid **Apply** rebuilds dimensions while preserving the live board and playback. Only block playback **keyboard** shortcuts while a pane has focus—not the timer in `love.update`.

## Backlog: camera, floating toolbar, controller input (Phases 6–8, not started)
- **Camera/viewport (Phase 6):** separate the simulated world from the visible viewport so patterns can grow beyond the window. Adds `src/camera.lua` (world↔screen transforms, pan, zoom). **Hard constraint:** the initial view at load must remain pixel-identical to today's centered zoom=1 board.
- **Floating toolbar (Phase 7):** new always-visible panel (suggested upper-left), separate from the docked-pane system — never dims the background, not opened via a status bar chip. Two tools plus zoom controls:
  - **Pan (hand icon):** click-and-drag moves the camera; does not pause playback.
  - **Draw (pencil icon):** hover + left-click/drag paints cells alive, right-click/drag paints cells dead, tracing every cell the cursor crosses while held. **Selecting this tool pauses the simulation.** The tool button is always available; choosing it is what triggers the pause. Supersedes the originally-planned always-on `src/input/board.lua` click-to-draw from Phase 4.
  - **Zoom +/−:** steps `camera.zoom` by a configurable amount, anchored on the current view center (not the cursor).
- **Controller input layer (Phase 8):** deliberately its own phase, per explicit request — mouse/keyboard UI on the status bar and toolbar is comparatively easy and should ship independently. Adds `src/input/controller.lua`, an action-dispatch layer so mouse, keyboard, and gamepad (`love.gamepadpressed`/`love.gamepadaxis`) all drive the same named actions (pan, zoom, play/pause, step, tool select).
- **Reusable button transition fx (independent, small):** Play/Pause button gets a "growing rectangle + trails" animation on state change. Must be a standalone, config-driven component (`src/ui/button_fx.lua`, shape mirrors `step_animation.lua`'s phase machine) attachable to any button rect — not hard-coded into `statusbar.lua`. Exact visual tuned later.
- **Open, not decided:** sequencing of Phases 6–8 relative to Phase 3–5; whether Phase 5's forced/letterbox grid mode is still needed once a camera exists; toolbar icon rendering strategy (glyphs/shapes vs. sprite sheet). See `plan/08-camera-and-viewport.md`, `plan/09-toolbar-and-drawing-tools.md`, and `plan/07-grid-settings.md` for detail.

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
- RLE import is supported in `patterns/*.rle` (M3-C).
- Default load pattern: `lifeview` via `defaultPattern` in shipped config (`glider` remains the loader fallback and catalog baseline).
- **M2-B** ✓ catalog tiers:
  - Core (Lua): glider, blinker, beacon
  - Extended (RLE): pulsar, gosper_glider_gun, lifeview, copperhead, fireship, loafer, sidecar, bomber, diamond, backrake_1, circle_of_fire, cottonmouth, moose_antlers, noahs_ark, pulsar_on_pentadecathlon_i, still_life_tagalong
  - Deferred: random_soup; **pattern type grouping** (still lifes, oscillators, spaceships, linear growth, etc.) for picker UI; external RLE repo sync with categories

## Status bar and playback
- **M2-C** ✓: bottom status bar shows rulestring, `rows×cols`, theme, and generation counter (`Gen: N`).
- **M3-A** ✓: playback state + `love.update` auto-step. Keyboard controls in `main.lua` (`space` toggle, `s` play, `p` pause, `n` step, `r` restart).
- **M3-B** ✓: status bar Play/Pause/Step/Restart buttons + keyboard shortcuts/docs.
- **M3-C** ✓: RLE parser and file resolution in `src/patterns.lua` (`.lua` first, then `.rle`).
- **Fast mode:** hold `f` → Play button shows `Play +`, step interval `0.05` via `playback.setStepInterval`.
- `stepInterval` = seconds between auto-generations when playing (config default `0.10`; not shown on status bar).
- **Resize:** In **auto** mode, `love.resize` refits rows/cols and migrates the live board (playback and generation continue). In **forced** mode, resize only recenters the letterboxed board; dimensions stay fixed until Settings Apply.
- **Panes open:** playback timer keeps running; only keyboard shortcuts are blocked. Theme selection auto-applies (does not pause). Rule Apply pauses and recomputes `next` under the new rulestring.
- **Step backward:** deferred; future **history stack** (needs `grid.clone`).

## Step Animation (Phase 0 ✓)
- Maintain both `current` and `next` generation buffers; `grid.computeNext` runs after each commit and on load/restart.
- **Idle / paused:** `current` on pseudo-3D tiles plus tiny square markers where `current ~= next` (unobtrusive next-state preview).
- **Step/play:** preview phase animates the marker; commit phase grows/shrinks the square to the new state; `grid.step` runs when both phases complete.
- **Rendering:** square morphs (not circles); alive tiles extruded (`tileDepthAlivePx`); dead tiles flat or shallow (`tileDepthDeadPx`).
- Config: `stepAnimEnabled`, `stepAnimMinTileSize`, `stepAnimPreviewSec`, `stepAnimCommitSec`, `previewDotScale`, `previewDotMinPx`, `tileDepthAlivePx`, `tileDepthDeadPx`. Fast mode scales morph speed and step interval. Animations are skipped when `stepAnimEnabled` is false or `tileSize` is below `stepAnimMinTileSize` (default 6); Settings pane exposes the On/Off preference.
- Shipped defaults (see `src/config.lua`): `tileSize` 24, preview min 4px / scale 0.15, alive depth 3px, dead depth 0.

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
- `src/config.lua`: board dimensions (runtime auto-fit), theme, `activeRule`, `defaultPattern`, `stepInterval`, status bar height, step animation and tile depth keys.
- `src/themes.lua`: named theme registry.
- `src/rules.lua`: named rulestring presets and `Bx/Sy` parser.
- `src/grid.lua`: world buffers, toroidal neighbor logic, `computeNext(world, rules)`, `step(world, rules)`.
- `src/patterns.lua`: load/apply patterns from `patterns/*.lua` and `patterns/*.rle`.
- `src/patterns/rle.lua`: RLE parser (`x/y/rule` header, run counts, `$`, `!`).
- `src/renderer.lua`: theme-driven board render (viewport above status bar).
- `src/ui/statusbar.lua`: bottom stats + playback controls (**M2-C** display, **M3-B** controls; **Phase 1+** clickable chips).
- `src/ui/pane.lua`: pane manager (**Phase 1** ✓).
- `src/session.lua`: draft/applied session state (**Phase 1** ✓).
- `src/ui/panes/*.lua`: rule, theme, pattern, settings panes (**Phases 2–5**).
- `src/step_animation.lua`: per-step morph timer; defers `grid.step` until complete (**Phase 0**).
- `src/color.lua`: LÖVE-native RGB 0–1 color helpers + HSV/hex conversions.
- `src/userdata.lua`: userspace save/load (**Phase 3** ✓).
- `src/ui/color_picker.lua`: modal HSV (saturation×value square + hue bar) dialog.
- `src/input/board.lua`: screen-to-cell + click drawing (**Phase 4**; behavior superseded by Phase 7 Draw tool once that lands).
- `src/playback.lua`: play/pause/step-forward state (**M3-A**; **Phase 0** defers `grid.step` until morph completes).
- `src/layout.lua`: viewport-to-grid sizing (`computeGridSize`; **Phase 5** ✓ forced letterbox via `computeBoardLayout`).
- `src/util.lua`: shared helpers (`wrap`).
- `src/camera.lua`: world↔screen transforms, pan/zoom state (**Phase 6**, backlog).
- `src/ui/toolbar.lua`: always-visible floating panel — pan/draw tool buttons, zoom +/− (**Phase 7**, backlog).
- `src/input/controller.lua`: unified mouse/keyboard/gamepad action dispatch (**Phase 8**, backlog).
- `src/ui/button_fx.lua`: reusable button transition animation, e.g. Play/Pause growing-rectangle effect (backlog, independent of Phases 6–8).
- `patterns/`: one file per initial state (`.lua` or `.rle`).
- `README.md`: usage and scope docs.
- `tests/`: plain Lua unit tests (`lua tests/run.lua`).

## Testing
- Run `lua tests/run.lua` from repo root (stdlib Lua, no LÖVE).
- GitHub Actions (`.github/workflows/test.yml`) runs the same suite on push to `main` and on pull requests.
- **Release:** `.github/workflows/release.yml` runs on tag push `v*` — tests gate, stages game files, builds `.love` + platform packages via `nhartland/love-build@v1`, publishes to GitHub Releases via `softprops/action-gh-release@v2`.
- **Specs:** `grid_spec`, `rules_spec`, `patterns_spec`, `rle_spec`, `playback_spec`, `layout_spec`, `statusbar_spec`, `step_animation_spec`, `pane_spec`, `phase2_spec`, `phase4_spec`, `phase5_spec`, `themes_spec`, `userdata_spec`, `color_spec`, `board_spec`; **Phase 6–8 backlog** will add `camera_spec`, `toolbar_spec`, `controller_spec` (mocked input dispatch), and `button_fx_spec`.
- **Covered modules:** `grid`, `rules`, `patterns`, `rle`, `playback`, `layout`, `statusbar`, `step_animation`, `pane`, `session`, `themes`, `userdata`, `color`, `board` (plus post-1.0 modules as phases land).
- Defer renderer/LÖVE integration tests.

## Working Agreement For This Repo
- Keep this `AGENTS.md` updated with active context, constraints, and decisions.
- Keep the `plan/` directory (see [`plan/README.md`](plan/README.md)) updated as implementation progresses.
- Preserve historical intent in `plan/` docs by marking items complete rather than deleting sections.
