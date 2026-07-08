# AGENTS

## Project Context
- Project: `love-life`
- Purpose: Conway's Game of Life in Lua using LÖVE.
- **Current phase:** v1.0 shipped; post-1.0 phased roadmap (Phases 0–5)
- **Active branch:** `main`

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
| **Phase 0** | Generation step animation (3-phase morph; replaces preview dots) |
| **Phase 1** | UI shell + fullscreen (pane manager, clickable chips, Settings button) |
| **Phase 2** | Rule and theme pickers (docked panes) |
| **Phase 3** | Userspace save/load (`src/userdata.lua`) |
| **Phase 4** | Pattern picker + board drawing |
| **Phase 5** | Grid settings (auto vs forced, letterbox) |

Phase 0 and Phase 1 should **not** be parallelized on one branch (shared `main.lua` / renderer / playback). Recommended sequence: **1a fullscreen → Phase 0 → Phase 1 → Phases 2–5** — see PLAN.md for release slices.

See `PLAN.md` for checkpoints, vision diagram, and file-level detail.

## Product Direction
- Build a configurable board of square tiles representing world state.
- Grid `rows`/`cols` **auto-fit** the window at load and on resize (see `src/layout.lua`); config values are starting hints for initial window sizing.
- Cell states: alive, dead.
- Toroidal universe (edges wrap).
- Visuals use named **themes** (colors only, not sizes).
- Built-in themes: `classic`, `zenburn`, `solarized`.
- Default active theme: `classic`.

## Post-1.0 Product Direction
- Status bar becomes the **primary control surface**: clickable chips open docked panes above the bar.
- **Draft vs save:** Apply uses in-memory drafts immediately; Save writes to LÖVE save directory (`patterns/`, `rules/`, `themes/`).
- **Grid modes:** `"auto"` (current resize behavior) or `"forced"` (fixed rows/cols/tileSize with letterbox centering).
- **Fullscreen:** F11 and Alt+Enter toggle (Phase 1); keyboard-only, no status bar button.
- Board drawing and editing require paused playback.

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
- Default load pattern: `glider` (configurable via `defaultPattern`).
- **M2-B** ✓ catalog tiers:
  - Core (Lua): glider, blinker, beacon
  - Extended (RLE): pulsar, gosper_glider_gun, lifeview
  - Deferred: random_soup

## Status bar and playback
- **M2-C** ✓: bottom status bar shows rulestring, `rows×cols`, theme, and generation counter (`Gen: N`).
- **M3-A** ✓: playback state + `love.update` auto-step. Keyboard controls in `main.lua` (`space` toggle, `s` play, `p` pause, `n` step, `r` restart).
- **M3-B** ✓: status bar Play/Pause/Step/Restart buttons + keyboard shortcuts/docs.
- **M3-C** ✓: RLE parser and file resolution in `src/patterns.lua` (`.lua` first, then `.rle`).
- **Fast mode:** hold `f` → Play button shows `Play +`, step interval `0.05` via `playback.setStepInterval`.
- `stepInterval` = seconds between auto-generations when playing (config default `0.10`; not shown on status bar).
- **Resize:** `love.resize` rebuilds the grid to fill the viewport and restarts from `defaultPattern` (same reset semantics as Restart).
- **Step backward:** deferred; future **history stack** (needs `grid.clone`).

## Next-State Preview / Step Animation
- Maintain both `current` and `next` generation buffers.
- **v1.0 (current):** render preview markers on the board (colors from active theme):
  - dead → alive: `alive`-colored center dot on dead tile
  - alive → dead: `dead`-colored center dot on alive tile
  - unchanged: no center dot
- Preview dot sizing in config: `previewDotScale`, `previewDotMinRadiusPx`, `previewDotMaxRadiusPx`.
- **Phase 0 (planned):** replace static preview dots with a 3-step morph (Rest → Anticipate → Resolve → commit `grid.step`). Paused board shows current gen only; next state revealed through animation on step. Config: `stepAnimAnticipateSec`, `stepAnimResolveSec`, `stepAnimEnabled`.

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
- `src/config.lua`: board dimensions (runtime auto-fit), theme, `activeRule`, `defaultPattern`, `stepInterval`, status bar height.
- `src/themes.lua`: named theme registry.
- `src/rules.lua`: named rulestring presets and `Bx/Sy` parser.
- `src/grid.lua`: world buffers, toroidal neighbor logic, `computeNext(world, rules)`, `step(world, rules)`.
- `src/patterns.lua`: load/apply patterns from `patterns/*.lua` and `patterns/*.rle`.
- `src/patterns/rle.lua`: RLE parser (`x/y/rule` header, run counts, `$`, `!`).
- `src/renderer.lua`: theme-driven board render (viewport above status bar).
- `src/ui/statusbar.lua`: bottom stats + playback controls (**M2-C** display, **M3-B** controls; **Phase 1+** clickable chips).
- `src/ui/pane.lua`: pane manager (**Phase 1**).
- `src/ui/panes/*.lua`: rule, theme, pattern, settings panes (**Phases 2–5**).
- `src/step_animation.lua`: 3-phase generation morph (**Phase 0**).
- `src/userdata.lua`: userspace save/load (**Phase 3**).
- `src/input/board.lua`: screen-to-cell + click drawing (**Phase 4**).
- `src/playback.lua`: play/pause/step-forward state (**M3-A**; **Phase 0** defers `grid.step` until morph completes).
- `src/layout.lua`: viewport-to-grid sizing (`computeGridSize`; **Phase 5** adds forced letterbox layout).
- `src/util.lua`: shared helpers (`wrap`).
- `patterns/`: one file per initial state (`.lua` or `.rle`).
- `README.md`: usage and scope docs.
- `tests/`: plain Lua unit tests (`lua tests/run.lua`).

## Testing
- Run `lua tests/run.lua` from repo root (stdlib Lua, no LÖVE).
- GitHub Actions (`.github/workflows/test.yml`) runs the same suite on push to `main` and on pull requests.
- **Release:** `.github/workflows/release.yml` runs on tag push `v*` — tests gate, stages game files, builds `.love` + platform packages via `nhartland/love-build@v1`, publishes to GitHub Releases via `softprops/action-gh-release@v2`.
- **Specs:** `grid_spec`, `rules_spec`, `patterns_spec`, `rle_spec`, `playback_spec`, `layout_spec`, `statusbar_spec`; **Phase 0+** `step_animation_spec`; **Phase 3+** `userdata_spec`.
- **Covered modules:** `src/grid.lua`, `src/rules.lua`, `src/patterns.lua`, `src/patterns/rle.lua`, `src/playback.lua`, `src/layout.lua`, `src/ui/statusbar.lua` (plus post-1.0 modules as phases land).
- Defer renderer/LÖVE integration tests.

## Working Agreement For This Repo
- Keep this `AGENTS.md` updated with active context, constraints, and decisions.
- Keep `PLAN.md` updated as implementation progresses.
- Preserve historical intent in `PLAN.md` by marking items complete rather than deleting sections.
