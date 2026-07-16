# Camera & viewport (Phase 6)

Decouples the simulated world from the on-screen viewport: pan/zoom, world ≠ visible area.

See [`README.md`](README.md) for the cross-area roadmap. Depends on / interacts with [`02-rendering-and-animation.md`](02-rendering-and-animation.md) (replaces the static layout offset math), [`07-grid-settings.md`](07-grid-settings.md) (open overlap with forced/letterbox mode), [`09-toolbar-and-drawing-tools.md`](09-toolbar-and-drawing-tools.md) (Phase 7 depends on this phase's coordinate transforms), [`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md) (board drawing needs the same `screenToCell` math).

**Status:** ✓ shipped — `src/camera.lua` + renderer/board wiring; Phase 7 toolbar replaced temporary debug keys.

## Development order

1. Build `src/camera.lua` in isolation (pure Lua, unit-testable) — no rendering changes yet. ✓
2. Swap `src/renderer.lua`'s static `getLayout` offset math for camera-driven per-tile transforms, verifying the load-time view is unchanged. ✓
3. Add temporary debug keys for pan/zoom to validate before Phase 7 ships a real UI. ✓ (removed once Phase 7 landed)
4. Phase 7 toolbar replaces debug keys. ✓

---

**Motivation:** decouples the simulated world from the on-screen viewport. Some patterns (spaceships, guns, rakes) grow well beyond a window-sized board; a camera lets the world be arbitrarily large while the view pans/zooms independently. **Hard constraint:** the initial view (load-time render) must look pixel-identical to today's centered, zoom = 1 board — this is a regression requirement, not just a nice-to-have.

**Delivers:** `src/camera.lua` (pure Lua, unit-testable) with world↔screen coordinate transforms; renderer and board input read through the camera instead of raw letterbox offsets alone.

| File | Work |
|------|------|
| `src/camera.lua` | Camera state (`x`, `y` world-space center, `zoom`); `worldToScreen`, `screenToWorld`, `pan`, `zoomBy`, `reset`, `computeLayout` ✓ |
| `src/renderer.lua` | `getLayout(config, camera)` → camera-driven offsets + zoomed tile size ✓ |
| `src/input/board.lua` | Unchanged API; receives camera layout from `main.lua` ✓ |
| `main.lua` | Camera lifecycle; reset on grid rebuild; debug keys ✓ |
| `src/config.lua` | `cameraZoomMin/Max/Step`, `cameraDefaultZoom`, `cameraPanStepPx` ✓ |
| `tests/camera_spec.lua` | Round-trip transforms; zoom clamping; letterbox parity at zoom=1 ✓ |

**Mechanics:**
- Camera starts centered on the board at `zoom = 1`, matching `layout.computeBoardLayout` offsets exactly (`camera_spec` asserts parity).
- Pan moves the camera center in world-space pixels; zoom scales tile render size. Toolbar +/− anchors on **view center**; **scroll wheel** zooms around the **cursor** (world point under the pointer stays fixed).
- World stays toroidal for simulation; rendering past board edges is still an open question — currently empty background.

**Temporary debug keys:** removed — use the Phase 7 floating toolbar (Pan / Zoom +/−) instead.
**Checkpoint:** `love .` at load looks unchanged from today; pan and zoom move/scale the view without altering simulation state; `camera_spec` green. ✓

## Open design considerations
- **Camera vs. Phase 5 forced/letterbox grid mode:** unresolved whether letterbox centering is still needed once a camera can pan — see [`07-grid-settings.md`](07-grid-settings.md).
- **Camera + toroidal rendering at the edges:** how the camera should render a finite toroidal world when panned/zoomed past its bounds is unresolved.
- **Zoom anchor policy:** toolbar +/− buttons anchor on view center; scroll-wheel zoom anchors on the cursor. ✓

## Config keys (this area)

| Key | Default | Phase |
|-----|---------|-------|
| `cameraDefaultZoom` | `1` | Phase 6 ✓ |
| `cameraZoomMin` | `0.25` | Phase 6 ✓ |
| `cameraZoomMax` | `4` | Phase 6 ✓ |
| `cameraZoomStep` | `1.25` | Phase 6 ✓ |
| `cameraPanStepPx` | `40` | Phase 6 ✓ (debug keys) |

## Planned files

| File | Status | Phase |
|------|--------|-------|
| `src/camera.lua` | exists | Phase 6 ✓ |
| `tests/camera_spec.lua` | exists | Phase 6 ✓ |

## Validation
- Initial view matches current output at zoom=1/pan=0; pan/zoom render correctly; `camera_spec` round-trips `worldToScreen`/`screenToWorld`. ✓

## TODO tracking

### Phase 6 ✓
- [x] **Phase 6** — Camera & viewport (`src/camera.lua`, renderer/board wiring)
- [x] Phase 7 toolbar replaced temporary pan/zoom debug keys
