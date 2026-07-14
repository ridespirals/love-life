# Floating toolbar: pan & draw tools, zoom controls (Phase 7, backlog)

An always-visible floating panel — suggested upper-left, configurable position/margin — separate from the docked-pane system ([`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md), `src/ui/pane.lua`): it never dims the background and isn't opened/closed by a status bar chip; it's simply always on screen.

See [`README.md`](README.md) for the cross-area roadmap. Depends on [`08-camera-and-viewport.md`](08-camera-and-viewport.md) (drag-to-pan and hover-to-cell both need camera transforms). Supersedes part of [`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md) (Phase 4's originally-planned always-on board click-to-draw).

**Status:** backlog — not started; depends on Phase 6 for correct coordinate mapping.

## Development order

1. Ship the toolbar frame + Pan tool first (simplest — pure camera pan, no world mutation).
2. Add the Draw tool (needs cell interpolation for fast drags, and the pause-on-select behavior).
3. Add Zoom +/− last (thin wrapper over `camera.zoomBy`, already exercised by Phase 6 debug keys).

---

**Delivers:** an always-visible floating panel with tool buttons (Pan, Draw) and Zoom +/−; active-tool highlight.

| File | Work |
|------|------|
| `src/ui/toolbar.lua` | Draw + hit-test for tool buttons (Pan, Draw) and Zoom +/−; active-tool highlight |
| `src/session.lua` | `activeTool` field (`nil` / `"pan"` / `"draw"`) — extends the scaffold from [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md) |
| `main.lua` | Route board mouse input through the active tool when the cursor is over the board and no pane/toolbar hit consumes it |
| `src/config.lua` | `toolbarMargin`, `toolbarButtonSize`, `cameraZoomStep` (shared with Phase 6) |
| `tests/toolbar_spec.lua` | Hit-test regions; tool toggle state |

**Tools:**
- **Pan (hand icon):** click-and-drag on the board moves the camera by the drag delta (screen px ÷ zoom). Does **not** pause playback — it's view-only, no world mutation.
- **Draw (pencil icon):** hover highlights the cell under the cursor. **Left-click** (and left-click-drag) sets alive on every cell the cursor crosses while held; **right-click** (and right-click-drag) sets dead the same way. Drag paths need cell interpolation between mouse-move samples (e.g. Bresenham) so fast drags don't skip cells. **Selecting the Draw tool pauses the simulation** — the tool button is always available; choosing it is what triggers the pause (refines the existing "drawing requires paused playback" rule to be explicit rather than implied by pane state).
- **Zoom +/−:** adjust `camera.zoom` by `cameraZoomStep`, clamped to `cameraZoomMin`/`cameraZoomMax`, anchored on the **current view center** (not the cursor). Step size configurable now, tunable later.

**Icon rendering:** no icon/image asset pipeline exists yet. First pass can use simple drawn glyphs (like the pane's `×` close glyph) or basic vector shapes (hand/pencil silhouettes via `love.graphics` primitives); revisit if a sprite sheet is wanted later.

**Supersedes:** Phase 4's originally-planned `src/input/board.lua` "click-to-draw when paused" behavior (see [`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md)) — board drawing now lives behind this Draw tool instead of an implicit always-on click handler.

**Checkpoint:** toolbar visible at all times, independent of any open pane; Pan drag moves the view; Draw left/right click and drag toggle cells and pause playback; Zoom +/− changes scale around the current view center.

## Open design considerations
- **Toolbar icon strategy:** drawn glyphs/vector shapes vs. a future sprite sheet for Pan/Draw tool icons.
- **Zoom anchor policy:** anchors on view center per the current request; cursor-anchored scroll-wheel zoom is an adjacent idea not yet requested/scoped — see [`12-deferred-and-backlog.md`](12-deferred-and-backlog.md).

## Config keys (this area)

| Key | Default | Phase |
|-----|---------|-------|
| `toolbarMargin`, `toolbarButtonSize` | TBD | Phase 7 (backlog) |

## Planned files

| File | Status | Phase |
|------|--------|-------|
| `src/ui/toolbar.lua` | planned (backlog) | Phase 7 |
| `tests/toolbar_spec.lua` | planned (backlog) | Phase 7 |

## Validation
- Toolbar visible at all times independent of panes; Pan drag moves view; Draw left/right click+drag toggles cells and pauses sim; Zoom +/− centers on current view.

## TODO tracking

### Phase 7 (backlog, not started)
- [ ] **Phase 7** — Floating toolbar: pan & draw tools, zoom +/− (backlog; always-visible panel, `src/ui/toolbar.lua`)
