# Deferred & backlog

Items explicitly not scheduled, historical items superseded by a phase that now covers them, and adjacent ideas surfaced during scoping but not yet requested. Kept for history rather than deleted, per the working agreement in [`README.md`](README.md).

## Explicitly deferred (post-1.0 roadmap)

- Static preview dots (replaced by step animation in Phase 0 — see [`02-rendering-and-animation.md`](02-rendering-and-animation.md))
- RLE export for user patterns (start with `.lua`; RLE export later — see [`05-persistence.md`](05-persistence.md))
- Import/share UI (file picker) — users can copy files manually from save dir
- Step backward / history stack (`grid.clone`) — see [`03-playback.md`](03-playback.md)
- Video export (gif/mp4 or equivalent)
- Custom app icon / code signing
- Tile-size hotkeys (`Shift+Up`/`Shift+Down`) — superseded by Phase 5 settings pane (see [`07-grid-settings.md`](07-grid-settings.md))
- More built-in rule presets and themes (users can save custom via Phase 3 — see [`05-persistence.md`](05-persistence.md))
- `random_soup` pattern — optional procedural seed (see [`01-simulation-and-patterns.md`](01-simulation-and-patterns.md))
- **Pattern catalog grouping by type** (still lifes, oscillators, spaceships, linear growth, methuselahs, etc.) — see [`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md)
- **External RLE repository sync** — consume a public pattern repo; category metadata drives grouped picker

## Adjacent ideas surfaced while scoping Phases 6–8 (not committed, not scoped)

- Scroll-wheel zoom anchored at the cursor (vs. the toolbar's view-center-anchored +/−) — see [`08-camera-and-viewport.md`](08-camera-and-viewport.md), [`09-toolbar-and-drawing-tools.md`](09-toolbar-and-drawing-tools.md)
- Keyboard/WASD or arrow-key camera panning (independent of gamepad stick panning) — see [`10-controller-input.md`](10-controller-input.md)
- Minimap / overview of the full world when zoomed in past 1:1

## Historical: future backlog (superseded by post-1.0 phases)

The items below remain tracked for history; implementation is covered by Phases 0–8 unless noted as deferred above.

- ~~Step backward via generation **history stack**~~ — **deferred** (needs `grid.clone` / snapshot helper, see [`03-playback.md`](03-playback.md))
- ~~Click-to-toggle cells~~ — **Phase 4** ✓ (board drawing, see [`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md); mechanism later superseded by Phase 7 Draw tool)
- ~~Pattern picker UI (cycle/load catalog at runtime)~~ — **Phase 4**
- ~~Runtime rule / theme switching (keyboard/UI picker)~~ — **Phases 2–3** (see [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md), [`05-persistence.md`](05-persistence.md))
- ~~More built-in rule presets and themes~~ — **Phase 3** userspace + optional built-in expansion
- ~~Video export (gif/mp4 or equivalent)~~ — **deferred**
- [x] Add more built-in themes beyond `classic`, `zenburn`, `solarized` (21 vim-derived presets + accent shadows) — done, see [`02-rendering-and-animation.md`](02-rendering-and-animation.md)
- [x] Add `gosper_glider_gun` pattern (RLE, M3-C) — done, see [`01-simulation-and-patterns.md`](01-simulation-and-patterns.md)
