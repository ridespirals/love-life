# Pattern picker & board drawing (Phase 4)

Covers pattern selection UI and click-to-draw starting states. **Note:** the click-to-draw *mechanism* described here is superseded by Phase 7's floating-toolbar Draw tool once that backlog phase lands — see the Supersedes note below. The pattern picker/catalog/save scope is unaffected.

See [`README.md`](README.md) for the cross-area roadmap. Depends on [`05-persistence.md`](05-persistence.md) (Phase 3 save/load), [`01-simulation-and-patterns.md`](01-simulation-and-patterns.md) (pattern catalog/format). Superseded in part by [`09-toolbar-and-drawing-tools.md`](09-toolbar-and-drawing-tools.md) (Phase 7 backlog).

**Status:** ✓ shipped — pattern pane with catalog grid, Apply/Clear/Save/Delete; paused board drawing via `src/input/board.lua`; user patterns merged in `patterns.loadUser`; unsaved edits tracked as applied id `custom`.

## Development order

1. **4a — Pattern picker**: catalog list + Apply ✓
2. **4b — Board drawing**: click-to-draw + draft + Save ✓

---

### Phase 4 — Pattern picker + board drawing ✓

**Delivers:** pattern selection, click-to-draw starting state, draft pattern memory.

| File | Work |
|------|------|
| `src/ui/panes/pattern_pane.lua` | Catalog list, Apply, Clear (blank + draw mode), Save/Delete ✓ |
| `src/input/board.lua` | `screenToCell` + stroke toggle/erase ✓ |
| `src/patterns.lua` | `fromWorld`, `list` merge user patterns, `loadUser`, `isBuiltin`/`isUser`/`exists` ✓ |
| Pattern pane | Save to userspace as `.lua` ✓ |

Board drawing (`src/input/board.lua`):
- `screenToCell(x, y, layout)` — inverse of `src/renderer.lua` layout math (see [`02-rendering-and-animation.md`](02-rendering-and-animation.md) coordinate conventions) ✓
- Left-click/drag toggles cells alive; right-click/drag erases — only when `playback` paused and no pane/color picker consuming clicks ✓
- Unsaved board edits set `appliedPatternId` to `"custom"`; Restart/resize fall back to `defaultPattern` when `custom` ✓

Pattern export: `patterns.fromWorld(world)` → `{ cells = {{col,row}, ...} }` for draft/save ✓

**Phase 4a scope:** flat catalog list (built-in + user). **Deferred follow-up:** group patterns by **type** in the picker UI (see below).

**Checkpoint:** draw shape on board, save as `my_pattern`, reload from list ✓

**Supersedes note (partial — Phase 6/7 backlog):** the always-on click-to-draw behavior described above for `src/input/board.lua` is superseded by Phase 7's floating-toolbar **Draw tool** (hover + left/right click-drag, explicit tool selection pauses playback) once that phase lands — see [`09-toolbar-and-drawing-tools.md`](09-toolbar-and-drawing-tools.md). Phase 4a's pattern picker/catalog/save scope is unaffected; only the "how do clicks become drawing" mechanism moves.

---

## Pattern type grouping (deferred — post Phase 4)

When the catalog grows — especially if loading from a **public RLE repository** — the pattern pane should group entries by **LifeWiki-style category**, not only a flat id list.

**Proposed categories (initial set):**

| Category | Examples |
|----------|----------|
| Still lifes | block, beehive, loaf |
| Oscillators | blinker, beacon, pulsar |
| Spaceships | glider, lwss |
| Linear growth | puffer, rake, gun |
| Methuselahs | diehard, r-pentomino |
| Other / uncategorized | fallback when type unknown |

**Data model (future):**
- Extend pattern metadata: `{ id, name, cells, category?, period?, tags? }`
- Built-in Lua/RLE: optional `category` field in module table or RLE comment header (e.g. `#C category: oscillator`)
- External repo import: map filename, sidecar `.json`, or community index to `category`
- `patterns.listByCategory()` or `patterns.listGrouped()` for pane UI (collapsible sections)

**UI (future):** Pattern pane shows category headers with scrollable sub-lists; search/filter across all types. User-saved patterns default to `Other` or user-assigned type on Save.

**Not in Phase 4 MVP** — ship flat list first; add grouping when catalog size or external RLE sync justifies it. Tracked in [`12-deferred-and-backlog.md`](12-deferred-and-backlog.md).

## Open design considerations
- Pattern discovery strategy: keep `patterns.list()` as explicit curated ids, or move to dynamic directory discovery when catalog grows.
- Pattern fallback UX: current loader falls back silently to `glider`; decide whether to log/warn in-app for unknown `defaultPattern`.

## Planned files

| File | Status | Phase |
|------|--------|-------|
| `src/ui/panes/pattern_pane.lua` | exists | Phase 4 ✓ |
| `src/input/board.lua` | exists | Phase 4 ✓ (superseded by Phase 7 Draw tool — see notes above) |
| `tests/board_spec.lua` | exists | Phase 4 ✓ |
| `tests/phase4_spec.lua` | exists | Phase 4 ✓ |

## TODO tracking

### Phase 4 ✓
- [x] **Phase 4** — Pattern picker + board drawing (draft patterns, click-to-draw)
- [x] Add click-to-toggle cell state (left-drag toggle, right-drag erase while paused)
- [x] Pattern picker UI (catalog list + Apply at runtime)
- [x] `patterns.fromWorld`, `loadUser`, user pattern Save/Delete

### Deferred (post Phase 4)
- [ ] **Pattern catalog grouping by type** (still lifes, oscillators, spaceships, linear growth, methuselahs, etc.) for pattern pane UI
- [ ] **External RLE repository sync** — consume a public pattern repo; category metadata drives grouped picker
