# Rendering, themes & animation

Covers how world state becomes pixels: the theme registry (colors), the renderer (board layout + drawing), the Phase 0 generation step animation, and the reusable button transition effect that grew out of the same "phase timer" shape.

See [`README.md`](README.md) for the cross-area roadmap. Related: [`01-simulation-and-patterns.md`](01-simulation-and-patterns.md) (produces the `world` this doc draws), [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md) (Phase 2 theme picker applies themes chosen here), [`08-camera-and-viewport.md`](08-camera-and-viewport.md) (backlog — will replace the static layout offset math described below with a camera transform).

## Development order

1. **M1** — theme registry + static renderer (done, historical).
2. **Window layout / coordinate conventions** — locked early, still in effect.
3. **Phase 0** — generation step animation (square preview → commit morph, idle markers, pseudo-3D tiles). ✓ shipped.
4. **Button fx** (backlog, independent, small) — extract Phase 0's phase-timer shape into a reusable component for Play/Pause button feedback.

---

## Themes (named color schemes)
- A theme is a named table of **colors only** — no sizes, spacing, or layout.
- Themes are registered in `src/themes.lua` and selected by name from config.
- **21 built-in themes:** original three (`classic`, `zenburn`, `solarized`) plus vim-derived presets (`monokai`, `gruvbox`, `dracula`, `nord`, `onedark`, `tomorrow_night`, `oceanic_next`, `synthwave`, …). Use `themes.list()` for the full sorted catalog.
- Each theme defines `alive`, `dead`, `grid`, `background` (defaults to `dead`), and optional `accent` — a signature syntax color from the vim palette, blended into pseudo-3D extrusion shadows (`config.accentBlendAlive` / `accentBlendDead`).
- Renderer and preview markers read draw colors from the active theme.
- Theme **selection/editing UI** (preset buttons, hex fields, live swatches) lives in the Phase 2 theme pane — see [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md). This doc covers the color model and rendering only.

### Original built-in themes (still shipped)
| name | alive | dead | grid | accent |
|------|-------|------|------|--------|
| `classic` | `#FFFFFF` | `#000000` | `#808080` | `#00AAAA` |
| `zenburn` | `#DCDCCC` | `#4D4D4D` | `#3F3F3F` | `#8CD0D3` |
| `solarized` | `#fdf6e3` | `#002b36` | `#073642` | `#2AA198` |

### `src/themes.lua`
- Export: `get(name)`, `list()`, `next(name)`, `prev(name)`, `skipped()`, `colorFromHex(hex)`, `extrusionShadow(theme, face, alive)`

## `src/renderer.lua`
- Accept active theme + size config + layout (board area excludes status bar).
- Compute board offset: centered in viewport **above** status bar.
- Draw extruded alive tiles, idle next-state square markers, step morph squares, grid lines.

## Design decisions (locked)

### Window layout
- **Resizable window** with the board **centered** in the viewport above the status bar.
- **Auto-fit grid:** at load and on every resize, `rows` and `cols` are recomputed as `floor(viewport / tileSize)` (minimum `1×1`), where viewport height excludes `statusBarHeight`. (Layout math itself lives in `src/layout.lua`; forced/letterbox mode is Phase 5, see [`07-grid-settings.md`](07-grid-settings.md).)
- Board pixel size = `cols * tileSize` × `rows * tileSize`.
- Renderer computes board offset from `love.graphics.getDimensions()` so centering survives resize.
- **Resize restarts simulation:** rebuild world, reapply `defaultPattern`, reset generation and playback (tradeoff: no cell-state preservation on resize).
- **Hard constraint for Phase 6 (camera, backlog):** the load-time view must remain pixel-identical to this behavior at zoom = 1 — see [`08-camera-and-viewport.md`](08-camera-and-viewport.md).

### Coordinate conventions
- **1-based** row/col indexing in Lua tables (idiomatic Lua).
- Screen mapping: `col` → x, `row` → y; origin top-left (matches LÖVE).
- Mouse-to-cell conversion uses the same offset math as the renderer — relevant to Phase 4 board drawing ([`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md)) and Phase 6/7 camera + toolbar ([`08-camera-and-viewport.md`](08-camera-and-viewport.md), [`09-toolbar-and-drawing-tools.md`](09-toolbar-and-drawing-tools.md)).

### Grid line rendering
- Draw filled cell rects first, then grid lines on top.
- Use half-pixel alignment (`+ 0.5`) where needed for crisp 1px lines on integer tile sizes.

### M1 visual checklist (regression)
- Expected rows/cols, aligned grid lines, theme colors; step morph on birth/death cells only (Phase 0).

---

## Phase 0 — Generation step animation ✓

Shipped on `main` (PR #1). No further Phase 0 work unless explicitly requested.

### Problem (pre-Phase 0)

`src/renderer.lua` draws **current** tiles and **preview dots** for cells where `current ~= next` at the same time. `src/playback.lua` (see [`03-playback.md`](03-playback.md)) calls `grid.step` immediately, swapping buffers with no visual transition.

### Shipped behavior (Phase 0 ✓)

Two-phase morph per generation step (`stepAnimPreviewSec` + `stepAnimCommitSec`). **Idle:** `current` on pseudo-3D tiles plus tiny square next-state markers where `current ~= next`. **Step/play:**

- **Preview:** marker eases in on changing cells (alive dot on dead tile = birth; dead dot on alive tile = death).
- **Commit:** square grows to full alive face or dead square consumes the alive face.
- Morph completes → `grid.step` + `grid.computeNext`.

Alive cells use extruded top faces (`tileDepthAlivePx`); dead cells can stay flat (`tileDepthDeadPx = 0`). Fast mode (`f` hold, see [`03-playback.md`](03-playback.md)) scales morph speed and step interval. `stepAnimEnabled = false` commits immediately.

### Historical design notes (superseded)

Early iterations: static preview dots, circle morph, two-phase circle morph, multi-generation death trail. Shipped design: **square** preview → commit with idle next-state markers and pseudo-3D alive tiles. **Do not re-litigate these visuals** without an explicit ask.

### Files (Phase 0 ✓)

| File | Role |
|------|------|
| `src/step_animation.lua` | Preview → commit timer; `getPhaseT`, `getCellChange` |
| `src/renderer.lua` | Square morph, idle preview markers, extruded tiles |
| `main.lua` | Defer `grid.step` until morph completes |
| `tests/step_animation_spec.lua` | Phase timing and cell-change detection |

**Checkpoint:** Idle shows current + next markers; step morphs squares; pseudo-3D alive tiles; fast mode works; tests green.

---

## Reusable button transition animation (Play/Pause "growing rectangle + trails")

**Status:** backlog — small and independent of Phases 6–8; can ship whenever convenient.

Visual feedback on the status bar Play/Pause button when playback starts or pauses: a rectangle grows from the button outward with fading trail copies, then settles (exact look is a later fine-tuning pass). Must be a **standalone, reusable, tunable component** — not hard-coded into `statusbar.lua` — so the same effect could decorate other buttons later.

| File | Work |
|------|------|
| `src/ui/button_fx.lua` | Generic timer/easing state machine (`create(config)`, `trigger(state)`, `update(state, dt)`, `draw(state, rect, theme)`) — same shape as `step_animation.lua`'s phase machine, but for a single UI element instead of the whole board |
| `src/config.lua` | `buttonFxEnabled`, `buttonFxDurationSec`, `buttonFxTrailCount`, `buttonFxTrailSpacingSec` |
| `src/ui/statusbar.lua` | Trigger the effect on Play/Pause state transitions (see [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md)) |
| `tests/button_fx_spec.lua` | Timer/trail math, pure Lua (mirrors `step_animation_spec.lua`) |

**Checkpoint:** toggling play/pause visibly animates the button; effect is fully config-driven and doesn't reference `statusbar` internals (could be attached to any `{x, y, w, h}` rect).

## Open design considerations
- Theme contrast policy: status bar currently uses theme colors directly; decide if accessibility overrides are needed for low-contrast themes.

## Config keys (this area)

| Key | Default | Phase |
|-----|---------|-------|
| `tileSize` | `24` | M1 ✓ |
| `activeTheme` | `"solarized"` | M1 ✓ (product-direction default is `classic`; current shipped `src/config.lua` default is `solarized`) |
| `statusBarHeight` | `28` | M1 ✓ |
| `stepAnimPreviewSec` | `0.08` | Phase 0 ✓ |
| `stepAnimCommitSec` | `0.12` | Phase 0 ✓ |
| `stepAnimEnabled` | `true` | Phase 0 ✓ |
| `previewDotScale` | `0.15` | Phase 0 ✓ |
| `previewDotMinPx` | `4` | Phase 0 ✓ |
| `tileDepthAlivePx` | `3` | Phase 0 ✓ |
| `tileDepthDeadPx` | `0` | Phase 0 ✓ |
| `accentBlendAlive` | `0.72` | vim themes ✓ |
| `accentBlendDead` | `0.42` | vim themes ✓ |
| `buttonFxEnabled`, `buttonFxDurationSec`, `buttonFxTrailCount`, `buttonFxTrailSpacingSec` | TBD | Button fx (backlog) |

## Planned/existing files

| File | Status | Phase |
|------|--------|-------|
| `src/themes.lua` | exists | — |
| `src/renderer.lua` | exists | — |
| `src/step_animation.lua` | exists | Phase 0 ✓ |
| `tests/step_animation_spec.lua` | exists | Phase 0 ✓ |
| `tests/themes_spec.lua` | exists | Phase 2 regression coverage |
| `src/ui/button_fx.lua` | planned (backlog) | Button fx (independent) |
| `tests/button_fx_spec.lua` | planned (backlog) | Button fx (independent) |

## TODO tracking

### Milestone 1 ✓
- [x] Add `src/themes.lua` with named theme registry (`classic`, `zenburn`, `solarized`)
- [x] Render theme-driven fills, preview center dots, and grid lines (centered above status bar area)
- (Full M1 checklist including grid/world model: see [`01-simulation-and-patterns.md`](01-simulation-and-patterns.md))

### Phase 0 ✓
- [x] **Phase 0** — Generation step animation (`src/step_animation.lua`; defer `grid.step`)
- [x] Add more built-in themes beyond `classic`, `zenburn`, `solarized` (21 vim-derived presets + accent shadows)

### Button fx (backlog)
- [ ] **Button fx** — Reusable Play/Pause "growing rectangle + trails" transition animation (backlog; independent of Phases 6–8, `src/ui/button_fx.lua`)
