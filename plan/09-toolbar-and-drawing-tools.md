# Floating toolbar: pan & draw tools, zoom controls (Phase 7)

An always-visible floating panel — upper-left, configurable position/margin — separate from the docked-pane system ([`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md), `src/ui/pane.lua`): it never dims the background and isn't opened/closed by a status bar chip; it's simply always on screen.

See [`README.md`](README.md) for the cross-area roadmap. Depends on [`08-camera-and-viewport.md`](08-camera-and-viewport.md) (drag-to-pan and hover-to-cell both need camera transforms). Supersedes part of [`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md) (Phase 4's originally-planned always-on board click-to-draw).

**Status:** ✓ shipped — toolbar frame, Pan/Draw tools, Zoom +/−; temporary Phase 6 debug keys removed.

## Development order

1. Ship the toolbar frame + Pan tool first (simplest — pure camera pan, no world mutation). ✓
2. Add the Draw tool (needs cell interpolation for fast drags, and the pause-on-select behavior). ✓
3. Add Zoom +/− last (thin wrapper over `camera.zoomBy`, already exercised by Phase 6 debug keys). ✓

---

**Delivers:** an always-visible floating panel with tool buttons (Pan, Draw) and Zoom +/−; active-tool highlight.

| File | Work |
|------|------|
| `src/ui/toolbar.lua` | Draw + hit-test for tool buttons (Pan, Draw) and Zoom +/−; glyph icons ✓ |
| `src/session.lua` | `activeTool` field (`nil` / `"pan"` / `"draw"`) ✓ |
| `main.lua` | Route board mouse input through the active tool; zoom actions; draw hover ✓ |
| `src/config.lua` | `toolbarMargin`, `toolbarButtonSize`; shared `cameraZoomStep` ✓ |
| `tests/toolbar_spec.lua` | Hit-test regions ✓ |

**Tools:**
- **Pan (crosshair/arrows glyph):** click-and-drag on the board moves the camera by the drag delta (screen px ÷ zoom). Does **not** pause playback.
- **Draw (pencil glyph):** hover highlights the cell under the cursor. **Left-click** / drag paints alive; **right-click** / drag paints dead (interpolated strokes via `board.continueStroke`). **Selecting Draw pauses the simulation.** Clicking the active tool again deselects it.
- **Zoom +/−:** adjust `camera.zoom` by `cameraZoomStep`, clamped, anchored on the **current view center**.

**Icon rendering:** drawn glyphs via `love.graphics` primitives (no sprite sheet).

**Supersedes:** Phase 4 always-on paused board drawing — drawing now requires the Draw tool. Phase 6 temporary Shift+Arrow / `=`/`-`/`0` debug keys removed in favor of the toolbar.

**Checkpoint:** ✓ toolbar visible at all times; Pan drag moves the view; Draw left/right click and drag paint cells and pause on select; Zoom +/− scales around view center.

## Open design considerations
- **Toolbar icon strategy:** drawn glyphs now; optional future sprite sheet.
- **Zoom anchor policy:** toolbar +/− use view center; scroll-wheel zoom uses cursor anchor ✓ — see [`08-camera-and-viewport.md`](08-camera-and-viewport.md).

## Config keys (this area)

| Key | Default | Phase |
|-----|---------|-------|
| `toolbarMargin` | `12` | Phase 7 ✓ |
| `toolbarButtonSize` | `32` | Phase 7 ✓ |

## Planned files

| File | Status | Phase |
|------|--------|-------|
| `src/ui/toolbar.lua` | exists | Phase 7 ✓ |
| `tests/toolbar_spec.lua` | exists | Phase 7 ✓ |

## Validation
- Toolbar visible at all times independent of panes; Pan drag moves view; Draw left/right click+drag paints cells and pauses sim; Zoom +/− centers on current view. ✓

## TODO tracking

### Phase 7 ✓
- [x] **Phase 7** — Floating toolbar: pan & draw tools, zoom +/− (`src/ui/toolbar.lua`)
