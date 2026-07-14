# Playback engine

Covers the play/pause/step/restart state machine (`src/playback.lua`) that drives `love.update`, independent of how it's exposed in the UI (status bar buttons/keys live in [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md)) or animated (step morph lives in [`02-rendering-and-animation.md`](02-rendering-and-animation.md)).

See [`README.md`](README.md) for the cross-area roadmap.

## Development order

1. **M3-A** — playback engine (`src/playback.lua`), wired to `love.update`. ✓ shipped.
2. **Post-M3 polish** — generation counter, fast mode, restart control. ✓ shipped.
3. **Step backward / history stack** — deferred, not scheduled (see [`12-deferred-and-backlog.md`](12-deferred-and-backlog.md)).

---

### Milestone 3-A — Playback engine ✓
1. Add `src/playback.lua` — `running`, `accumulator`, `play` / `pause` / `stepForward` wrapping `grid.step`
2. Wire `love.update` — auto-advance when `accumulator ≥ stepInterval`
3. Resolve active rules once in `love.load`; pass to `computeNext` / `step` / playback

**Checkpoint (M3-A, superseded by Phase 0):** play/pause/step advances generations; idle next-state markers while paused.

### Post-M3 polish ✓
- **Generation counter** ✓ — status bar shows `Gen: N` (display lives in [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md)).
- **Fast mode** ✓ — hold `f` for `Play +` label and `0.05` step interval via `playback.setStepInterval`.
- **Restart control** ✓ — `r` key and status bar Restart button.
- **Auto-fit grid on load and resize** ✓ — `src/layout.lua` computes `rows`/`cols` from window size and `tileSize`; `love.load` and `love.resize` rebuild world and restart from `defaultPattern` (generation and playback reset). See [`07-grid-settings.md`](07-grid-settings.md) for the Phase 5 forced-mode alternative.
- **Deferred (superseded by Phase 5):** `Shift+Up`/`Shift+Down` tile-size hotkeys — grid settings pane replaces ad-hoc hotkeys.

## Design decisions (locked)

### Playback (Milestone 3)
- State: `running` (bool), `stepInterval` (seconds), `accumulator` (dt).
- **Play**: set `running = true`; `love.update` advances when accumulator ≥ `stepInterval`.
- **Pause**: set `running = false`.
- **Step forward**: single generation regardless of `running` — delegates to `grid.step(world, rules)` (v1.0: immediate; **Phase 0**: deferred until animation completes, see [`02-rendering-and-animation.md`](02-rendering-and-animation.md)).
- While idle/paused, board shows **current** plus tiny square next-state markers; morph runs on step/play (Phase 0 ✓).
- History push on forward step — **deferred** to history stack below.

### Step backward (future — history stack)
- **Deferred** — not scheduled in Phases 0–8.
- Plan: ring buffer or stack of `current` grid snapshots per forward step.
- Requires `grid.clone(world)` helper (see [`01-simulation-and-patterns.md`](01-simulation-and-patterns.md)).
- Step back pops history → restore `current` → recompute `next`.
- Memory cost: `O(historyDepth × rows × cols)`; cap depth in config later.

## Open design considerations
- Playback timer semantics: fast mode already changes `stepInterval` at runtime via `playback.setStepInterval` while held; decide if other runtime interval changes should reset accumulator.

## Config keys (this area)

| Key | Default | Phase |
|-----|---------|-------|
| `stepInterval` | `0.10` | M2-C ✓ (display removed in post-M3; used by playback) |

## Planned/existing files

| File | Status | Phase |
|------|--------|-------|
| `src/playback.lua` | exists | M3-A ✓; Phase 0 defers `grid.step` until morph completes |
| `src/layout.lua` | exists | Post-M3 ✓ auto-fit sizing; Phase 5 adds forced layout |
| `tests/playback_spec.lua` | exists | M3-A ✓ |
| `tests/layout_spec.lua` | exists | Post-M3 ✓ resize math |

## TODO tracking

### Milestone 3-A — Playback engine ✓
- [x] Add `src/playback.lua` — play/pause/step-forward state machine
- [x] Wire `stepInterval` auto-advance in `love.update`
- [x] Pass resolved rules through playback → `grid.step`

### Deferred (not in Phases 0–8)
- [ ] Step backward via generation history stack (`grid.clone`)
