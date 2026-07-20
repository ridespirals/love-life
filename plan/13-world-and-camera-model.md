# World & camera model (Phases W1–W3)

Decouples simulation world size from the window: a large finite dense board, camera pan/zoom with pixel-snapped visual tiles, and viewport-culled rendering.

See [`README.md`](README.md) for the cross-area roadmap. Supersedes the open “forced vs camera” overlap in [`07-grid-settings.md`](07-grid-settings.md) and [`08-camera-and-viewport.md`](08-camera-and-viewport.md). Related: [`02-rendering-and-animation.md`](02-rendering-and-animation.md) (anim gate on visual tile size).

**Status:** ✓ shipped — W1–W3.

## Decision (locked)

| Topic | Choice |
|-------|--------|
| Architecture | Large **fixed dense** board + camera scale |
| Topology | **Toroidal** simulation on the finite board |
| Past-edge view | **Clamp** camera so the void is not shown |
| Settings `tileSize` | Removed; **zoom** carries visual cell size |
| Default world | **512×512** (raise toward 1024+ after perf check) |
| Sparse / HashLife | Deferred (see alternatives below) |

## Option survey (historical)

1. **Large fixed dense + camera** (chosen) — smallest migration from `grid.current[row][col]`.
2. **Sparse live-cell set** — good for infinite empty space; conflicts with torus; large rewrite.
3. **Hybrid expand/crop** — later if patterns outgrow the fixed board.
4. **Chunked sparse** — middle ground; not needed yet.
5. **HashLife** — poor fit for interactive paint + gen-by-gen morphs.
6. **Forced + camera only** — insufficient until auto-fit stops resizing the sim.

## Target model

- World size = `config.rows` × `config.cols` (fixed until Settings Apply).
- World unit = **1 cell**. Screen tile = integer `visualTile` from `baseVisualTile * zoom` (snapped).
- Window resize **does not** change `rows`/`cols` — only camera clamp/refit.
- Auto-fit grid mode **removed**; Settings exposes world rows/cols + Animate On/Off.
- Animations skipped when `visualTile < stepAnimMinTileSize`.
- Renderer draws only cells visible in the viewport; LOD skips extrusion/preview/grid when tiles are small.

## Development checklist

### Phase W1 — Freeze world; camera owns viewport ✓

- [x] Stop resize from changing sim dimensions
- [x] Default world 512×512
- [x] Camera pan + zoom-out clamp to board (cover mode)
- [x] Anim gate on screen/visual tile size
- [x] Docs: auto-fit no longer owns world size

### Phase W2 — Zoom-as-tile-size ✓

- [x] World unit = 1 cell; `baseVisualTile` for default density
- [x] Remove tile size / Auto/Forced from Settings
- [x] Integer-snapped visual tiles

### Phase W3 — Render budget ✓

- [x] Viewport culling in renderer (`camera.visibleCellRange`)
- [x] LOD when visual tiles are small (flat fill, no grid/extrusion/preview)
- [x] Default **512×512**; path to 1024: set `rows`/`cols` in config or Settings after play+draw stress check

### Later

- [ ] W4 expand/crop hybrid
- [ ] W5 sparse/open mode (optional torus toggle)

## Perf note (512 vs 1024)

| Size | Cells | Notes |
|------|-------|-------|
| **512²** (default) | ~262k | Comfortable for dense Lua tables + culled draw |
| 1024² | ~1M | Viable after W3 culling; sim `computeNext` still O(N²) — try via Settings before making default |

## Config keys

| Key | Default | Phase |
|-----|---------|-------|
| `rows`, `cols` | `512` | W1 |
| `baseVisualTile` | `24` | W2 |
| `stepAnimMinTileSize` | `6` | W1 (applies to visual tile) |
| `cameraZoomMin` / `Max` / `Step` / `DefaultZoom` | `0.05` / `8` / `1.25` / `1` | W1–W2 |

## Files

| File | Role |
|------|------|
| `src/camera.lua` | Cell-unit board, visual tile snap, clamp, visible range |
| `src/renderer.lua` | Culled draw + LOD |
| `src/step_animation.lua` | `effectiveEnabled(config, visualTile)` |
| `src/ui/panes/settings_pane.lua` | World rows/cols + Animate; no Auto/Forced/tile |
| `main.lua` | No auto-fit resize; clamp after pan/zoom |
| `tests/camera_spec.lua` | Clamp + visual tile + culling range |
