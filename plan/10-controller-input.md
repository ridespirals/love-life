# Controller input layer (Phase 8, backlog)

An abstraction between raw input events and game actions, so mouse, keyboard, and gamepad can all drive the same behavior (play/pause, step, restart, pan, zoom, tool select) without duplicating logic per device.

See [`README.md`](README.md) for the cross-area roadmap. Sits behind [`03-playback.md`](03-playback.md), [`08-camera-and-viewport.md`](08-camera-and-viewport.md), and [`09-toolbar-and-drawing-tools.md`](09-toolbar-and-drawing-tools.md) — this phase doesn't add new capability, it unifies dispatch to the capabilities those phases already expose.

**Status:** backlog — not started; deliberately its own phase per explicit request ("a separate phase of development to add controller support") — mouse-driven status bar/toolbar UI is comparatively easy and should not block on this.

## Development order

1. Define the named-action surface (`playPause`, `step`, `restart`, `panCamera`, `zoomIn`, `zoomOut`, `selectTool`, …) in `src/input/controller.lua`.
2. Rewire existing `love.keypressed` / `love.mousepressed` handlers in `main.lua` to call the same action functions (no behavior change yet).
3. Add `love.gamepadpressed` / `love.gamepadaxis` handlers that call the same actions.
4. Add config-driven bindings + deadzone handling.

---

**Delivers:** `src/input/controller.lua` — named actions dispatched from mouse/keyboard/gamepad handlers.

| File | Work |
|------|------|
| `src/input/controller.lua` | Named actions (`playPause`, `step`, `restart`, `panCamera(dx, dy)`, `zoomIn`, `zoomOut`, `selectTool(id)`, …) dispatched from mouse/keyboard/gamepad handlers |
| `main.lua` | `love.gamepadpressed` / `love.gamepadaxis` wired to the same action functions used by `love.keypressed` / `love.mousepressed` |
| `src/config.lua` | `gamepadDeadzone`, `gamepadPanSpeed`, button/axis-to-action bindings |
| `tests/controller_spec.lua` | Action dispatch given mocked input events (no real `love.joystick` needed) |

**Mechanics (initial mapping, tune later):**
- Left stick / d-pad → pan camera.
- Shoulder buttons or right stick → zoom in/out.
- One face button → play/pause; another → step.
- Bindings live in config so they're remappable without code changes.

**Checkpoint:** connecting a gamepad drives pan/zoom/play-pause/step identically to mouse+keyboard; `controller_spec` green; no regression to existing mouse/keyboard behavior.

## Config keys (this area)

| Key | Default | Phase |
|-----|---------|-------|
| `gamepadDeadzone`, `gamepadPanSpeed` | TBD | Phase 8 (backlog) |

## Planned files

| File | Status | Phase |
|------|--------|-------|
| `src/input/controller.lua` | planned (backlog) | Phase 8 |
| `tests/controller_spec.lua` | planned (backlog) | Phase 8 |

## Validation
- Gamepad button/stick mappings drive the same actions as mouse/keyboard; deadzone respected; `controller_spec` green.

## TODO tracking

### Phase 8 (backlog, not started)
- [ ] **Phase 8** — Controller input layer (backlog; unified mouse/keyboard/gamepad actions, `src/input/controller.lua`)
