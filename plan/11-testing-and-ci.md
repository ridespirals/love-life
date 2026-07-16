# Testing & CI

Covers the test suite strategy, GitHub Actions workflows, and the validation checklists used to confirm each phase. This is a cross-cutting reference, not a sequential build phase — apply it continuously as other areas ship.

See [`README.md`](README.md) for the cross-area roadmap.

## Testing strategy

| Layer | Approach |
|-------|----------|
| `grid`, `rules`, `patterns`, `rle`, `playback`, `layout`, `statusbar`, `step_animation`, `pane`, `session` | Pure Lua unit tests (no LÖVE) |
| `step_animation` phase machine + lerp | Pure Lua unit tests |
| `userdata` serialize/parse | Pure Lua unit tests (Phase 3, see [`05-persistence.md`](05-persistence.md)) |
| `layout` forced letterbox math | Extend `tests/layout_spec.lua` (Phase 5, see [`07-grid-settings.md`](07-grid-settings.md)) |
| `patterns.fromWorld` | Unit test (Phase 4, see [`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md)) |
| Pane hit regions | Extend `tests/statusbar_spec.lua` with mock geometry |
| `camera` world↔screen transforms | Pure Lua unit tests ✓ (Phase 6, see [`08-camera-and-viewport.md`](08-camera-and-viewport.md)) |
| `toolbar` hit-test regions | Pure Lua unit tests (Phase 7, see [`09-toolbar-and-drawing-tools.md`](09-toolbar-and-drawing-tools.md)) |
| `controller` action dispatch | Mocked input events, no real `love.joystick` (Phase 8, see [`10-controller-input.md`](10-controller-input.md)) |
| `button_fx` timer/trail math | Pure Lua unit tests ✓ (see [`02-rendering-and-animation.md`](02-rendering-and-animation.md)) |
| Full UI | Manual smoke per phase |
| Fullscreen | Manual smoke — F11 toggle, grid auto-fit, playback after exit (no unit tests; `love.window` is LÖVE-only) |

Run via `lua tests/run.lua` from repo root (stdlib Lua, no LÖVE). Currently registers 19 specs: `grid_spec`, `rules_spec`, `patterns_spec`, `rle_spec`, `playback_spec`, `layout_spec`, `statusbar_spec`, `step_animation_spec`, `pane_spec`, `phase2_spec`, `phase4_spec`, `phase5_spec`, `text_field_spec`, `button_fx_spec`, `camera_spec`, `themes_spec`, `userdata_spec`, `color_spec`, `board_spec`. Phase 7–8 backlog adds `toolbar_spec`, `controller_spec`.

Defer renderer/LÖVE integration tests.

## CI

### Tests
- Workflow: `.github/workflows/test.yml`
- Trigger: push to `main`, all pull requests
- Runner: `ubuntu-latest`, Lua 5.4 via `leafo/gh-actions-lua`
- Command: `lua tests/run.lua`

### Release
- Workflow: `.github/workflows/release.yml`
- Trigger: push tag `v*` (e.g. `v1.0.0`)
- Steps: run tests → stage game files (`main.lua`, `conf.lua`, `src/`, `patterns/`, `LICENSE`) → [nhartland/love-build](https://github.com/marketplace/actions/love-build) (LÖVE 11.5) → [softprops/action-gh-release](https://github.com/softprops/action-gh-release)
- Artifacts: `love-life.love`, Windows 32/64 zips, macOS `.app` zip, Linux x86_64 AppImage zip

**Open:** LÖVE 12 (when released) — evaluate bumping from 11.5; see cross-reference in [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md) re: `Font:setBold()`.

## Validation

### Always
- `lua tests/run.lua` — grid + rules + patterns unit tests (no LÖVE)
- `love .` — visual smoke test

### Per phase

| Phase | Verify |
|-------|--------|
| M2-A | Tests green; `activeRule = "ant_colony"` changes survival (e.g. 4 neighbors) |
| M2-B | `defaultPattern` loads from `patterns/`; `seedGlider` removed |
| M2-C | Status bar shows rulestring, size, theme, generation |
| M3-A | Generations advance on timer / step; idle next-state markers while paused |
| M3-B | Bar buttons + keys work; README accurate |
| Phase 0 ✓ | Square preview→commit morph; idle next-state markers; pseudo-3D alive tiles; tests green |
| Phase 1 ✓ | Panes open/close; clickable chips; Settings button |
| Phase 2 ✓ | Switch rules/themes via panes without config edit |
| Phase 3 ✓ | Custom theme persists across relaunch |
| Phase 4 ✓ | Draw pattern, save, reload from list |
| Phase 5 ✓ | Forced grid letterboxed; auto-fit on toggle back; grid Apply preserves board; animation toggle; `text_field_spec` green |
| Phase 6 (in progress) | Initial view matches letterbox at zoom=1/pan=0; Shift+Arrows pan; `=`/`-` zoom; `camera_spec` green |
| Phase 7 (backlog) | Toolbar visible at all times independent of panes; Pan drag moves view; Draw left/right click+drag toggles cells and pauses sim; Zoom +/− centers on current view |
| Phase 8 (backlog) | Gamepad button/stick mappings drive the same actions as mouse/keyboard; deadzone respected; `controller_spec` green |

### M1 visual checklist (regression)
- Expected rows/cols, aligned grid lines, theme colors; step morph on birth/death cells only (Phase 0) — see [`02-rendering-and-animation.md`](02-rendering-and-animation.md).

## Planned/existing files

| File | Status | Phase |
|------|--------|-------|
| `.github/workflows/test.yml` | exists | CI — Lua 5.4, `lua tests/run.lua` on push/PR |
| `.github/workflows/release.yml` | exists | v1.0 — tag-triggered build + GitHub Release |
| `tests/run.lua` | exists | registers all specs |
