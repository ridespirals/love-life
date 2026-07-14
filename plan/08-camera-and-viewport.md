# Camera & viewport (Phase 6, backlog)

Decouples the simulated world from the on-screen viewport: pan/zoom, world ≠ visible area.

See [`README.md`](README.md) for the cross-area roadmap. Depends on / interacts with [`02-rendering-and-animation.md`](02-rendering-and-animation.md) (replaces the static layout offset math), [`07-grid-settings.md`](07-grid-settings.md) (open overlap with forced/letterbox mode), [`09-toolbar-and-drawing-tools.md`](09-toolbar-and-drawing-tools.md) (Phase 7 depends on this phase's coordinate transforms), [`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md) (board drawing needs the same `screenToCell` math).

**Status:** backlog — not started; sequencing relative to Phases 4–5 is an open question (see sequencing note in [`README.md`](README.md)).

## Development order

1. Build `src/camera.lua` in isolation (pure Lua, unit-testable) — no rendering changes yet.
2. Swap `src/renderer.lua`'s static `getLayout` offset math for camera-driven per-tile transforms, verifying the load-time view is unchanged.
3. Add temporary debug keys for pan/zoom to validate before Phase 7 ships a real UI.

---

**Motivation:** decouples the simulated world from the on-screen viewport. Some patterns (spaceships, guns, rakes) grow well beyond a window-sized board; a camera lets the world be arbitrarily large while the view pans/zooms independently. **Hard constraint:** the initial view (load-time render) must look pixel-identical to today's centered, zoom = 1 board — this is a regression requirement, not just a nice-to-have.

**Delivers:** `src/camera.lua` (pure Lua, unit-testable) with world↔screen coordinate transforms; renderer (and later, input code) read through the camera instead of raw `layout.getLayout` offsets.

| File | Work |
|------|------|
| `src/camera.lua` | Camera state (`x`, `y` world-space center, `zoom`); `worldToScreen`, `screenToWorld`, `pan(dx, dy)`, `zoomBy(factor, anchor)`, `reset()` |
| `src/renderer.lua` | Replace static `getLayout` offset math with camera-driven transform per tile |
| `src/config.lua` | `cameraZoomMin`, `cameraZoomMax`, `cameraZoomStep`, `cameraDefaultZoom` (`1.0`) |
| `tests/camera_spec.lua` | Round-trip `worldToScreen`/`screenToWorld`; zoom clamping; pan accumulation |

**Mechanics:**
- Camera starts centered on the board at `zoom = 1`, matching current `renderer.getLayout` output exactly.
- Pan moves the camera center in world-space pixels; zoom scales tile render size around a chosen anchor (view center for the Phase 7 toolbar buttons — cursor-anchored scroll-wheel zoom is a **future stretch**, not requested/in scope here; see [`12-deferred-and-backlog.md`](12-deferred-and-backlog.md)).
- World stays toroidal for simulation purposes; how the camera renders past the board edges (if it can see "past" a finite toroidal world) is an open rendering question — flag rather than resolve now.

**Checkpoint:** `love .` at load looks unchanged from today; pan and zoom (temporary debug keys are fine before Phase 7 ships a UI) move/scale the view without altering simulation state; `camera_spec` green.

## Open design considerations
- **Camera vs. Phase 5 forced/letterbox grid mode:** unresolved whether letterbox centering is still needed once a camera can pan — see [`07-grid-settings.md`](07-grid-settings.md).
- **Camera + toroidal rendering at the edges:** how the camera should render a finite toroidal world when panned/zoomed past its bounds is unresolved.
- **Zoom anchor policy:** toolbar +/− buttons (Phase 7) anchor on view center per the current request; cursor-anchored scroll-wheel zoom is an adjacent idea, not yet requested/scoped — see [`12-deferred-and-backlog.md`](12-deferred-and-backlog.md).

## Config keys (this area)

| Key | Default | Phase |
|-----|---------|-------|
| `cameraZoomMin`, `cameraZoomMax`, `cameraZoomStep`, `cameraDefaultZoom` | TBD (`cameraDefaultZoom = 1.0`) | Phase 6 (backlog) |

## Planned files

| File | Status | Phase |
|------|--------|-------|
| `src/camera.lua` | planned (backlog) | Phase 6 |
| `tests/camera_spec.lua` | planned (backlog) | Phase 6 |

## Validation
- Initial view matches current output at zoom=1/pan=0; pan/zoom render correctly; `camera_spec` round-trips `worldToScreen`/`screenToWorld`.

## TODO tracking

### Phase 6 (backlog, not started)
- [ ] **Phase 6** — Camera & viewport (backlog; pan/zoom, world ≠ visible area, `src/camera.lua`)
