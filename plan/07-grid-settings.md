# Grid settings pane (Phase 5)

Covers the Settings pane for tile size, rows, cols, and the auto-fit vs. forced/letterboxed grid mode toggle.

See [`README.md`](README.md) for the cross-area roadmap. Extends [`02-rendering-and-animation.md`](02-rendering-and-animation.md) window layout math and `src/layout.lua` (also touched by [`03-playback.md`](03-playback.md) auto-fit resize). Has an **open interaction** with [`08-camera-and-viewport.md`](08-camera-and-viewport.md) (Phase 6 backlog) — see below.

**Status:** ✓ shipped — Settings pane with Auto/Forced toggle, tile/rows/cols fields, Apply; `layout.computeBoardLayout` letterbox centering; auto resize refits grid, forced resize only recenters.

## Development order

1. Extend `src/layout.lua` with a forced/letterbox layout function alongside the existing auto-fit one. ✓
2. Add `gridMode`/`forcedRows`/`forcedCols`/`forcedTileSize` config keys. ✓
3. Build `src/ui/panes/settings_pane.lua` (auto/forced toggle, numeric fields, Apply). ✓
4. Split `main.lua`'s `rebuildWorldForWindow` into auto-resize vs. explicit `applyGridSettings`. ✓

---

### Phase 5 — Grid settings pane (auto vs forced) ✓

**Delivers:** Settings pane for tile size, rows, cols, auto-fit toggle.

Extend `src/layout.lua`:

```lua
-- auto: current behavior
computeGridSize(windowW, windowH, tileSize, statusBarHeight)

-- forced: user values; letterbox in viewport
computeBoardLayout(windowW, windowH, rows, cols, tileSize, statusBarHeight)
-- returns offsetX, offsetY (centered), same as renderer today
```

**Auto mode:** window resize → recompute rows/cols from `tileSize` (current `main.lua` `rebuildWorldForWindow`, see [`03-playback.md`](03-playback.md)).

**Forced mode:** resize only recenters/letterboxes; **does not** change rows/cols/tileSize. Changing forced values in Settings pane rebuilds grid (restart from active pattern; `custom` → blank board).

Config additions in `src/config.lua`: `gridMode`, `forcedRows`, `forcedCols`, `forcedTileSize` (defaults mirror current hints).

| File | Work |
|------|------|
| `src/ui/panes/settings_pane.lua` | Auto/forced toggle, numeric fields, Apply ✓ |
| `src/layout.lua` | Forced layout path; letterbox centering ✓ |
| `main.lua` | Split `rebuildWorldForWindow` vs `applyGridSettings` ✓ |
| `src/renderer.lua` | Uses `layout.computeBoardLayout` ✓ |

**Checkpoint:** force 80×80 @ 8px tile, letterboxed; toggle back to auto-fit on resize. ✓

## Open design considerations
- **Camera vs. forced/letterbox grid mode:** once Phase 6's camera exists, "forced" mode + letterboxing may partially overlap with "just pan to see the rest of the board." Decide at implementation time whether Phase 5's letterbox centering is still needed once Phase 6 ships, or whether forced mode becomes "fixed world size, camera navigates it." **Not resolved here** — see [`08-camera-and-viewport.md`](08-camera-and-viewport.md).
- This overlap is part of why Phase 6 (camera) may get pulled ahead of Phase 5 — see the sequencing note in [`README.md`](README.md).

## Config keys (this area)

| Key | Default | Phase |
|-----|---------|-------|
| `gridMode` | `"auto"` | Phase 5 ✓ |
| `forcedRows`, `forcedCols`, `forcedTileSize` | mirror hints | Phase 5 ✓ |

## Planned files

| File | Status | Phase |
|------|--------|-------|
| `src/ui/panes/settings_pane.lua` | exists | Phase 5 ✓ |
| `tests/phase5_spec.lua` | exists | Phase 5 ✓ |

## TODO tracking

### Phase 5 ✓
- [x] **Phase 5** — Grid settings pane (auto vs forced, letterbox)
- [x] `computeBoardLayout` letterbox centering
- [x] Settings pane Auto/Forced + tile/rows/cols Apply
- [x] Auto resize refits; forced resize recenters only
