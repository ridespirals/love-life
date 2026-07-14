# Userspace persistence (Phase 3)

Covers saving/loading user-created rules, themes, and (later) patterns to the LÖVE save directory, and merging them with built-in catalogs.

See [`README.md`](README.md) for the cross-area roadmap. Depends on [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md) (Save/Delete UI lands on the existing rule/theme panes) and [`01-simulation-and-patterns.md`](01-simulation-and-patterns.md) (catalog merge extends `src/rules.lua`/`src/patterns.lua`). Feeds [`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md) (Phase 4 pattern save).

**Status:** ✓ shipped — built-ins are read-only; Save slugs a unique id from the Name field; Delete only for user entries; no Discard button (reopen resets drafts).

## Development order

1. **3a — `src/userdata.lua`**: persistence API + catalog merge + unit tests. ✓
2. **3b — Save UI**: Save / Delete buttons on rule + theme panes (theme has no Apply — Save persists the live-applied draft; rule still Apply then Save). ✓

---

### Phase 3 — Userspace save/load for rules and themes ✓

**Delivers:** Save custom rule/theme to save directory; merged catalogs.

| File | Work |
|------|------|
| `src/userdata.lua` | IO + serialization ✓ |
| `src/rules.lua` / `src/themes.lua` | Load user presets ✓ |
| Rule/Theme panes | Save / Delete buttons, name field ✓ |
| `tests/userdata_spec.lua` | Round-trip serialize tests ✓ |

**Checkpoint:** create custom theme, quit, relaunch, still listed. ✓

## Design details

### Userspace layout

All user-created assets live under the LÖVE save directory (shareable, outside the `.love` bundle):

```
<saveDirectory>/
  patterns/<id>.lua      # { id, name, cells = {{col,row}, ...} } (Phase 4)
  rules/<id>.lua         # { id, name, rulestring = "B3/S23" }
  themes/<id>.lua        # { id, name, alive, dead, grid, background, accent? } hex strings
```

Module: `src/userdata.lua`
- `slugify`, `serialize`, `deserialize`, `validate`
- `ensureDirs()`, `list(type)`, `load(type, id)`, `save(type, id, data)`, `delete(type, id)`
- Pure-Lua serialization helpers (testable without LÖVE) + thin `love.filesystem` IO wrapper

**Catalog merge:** `rules.loadUser` / `themes.loadUser`:
- Built-ins first, then user entries from save dir
- Built-in ids never overwritten by user files
- `list()` returns merged ids; `get(id)` checks built-in → user → fallback

### Save/Discard semantics

- **Save** — write the currently applied draft to userspace; assign stable `id` via `slugify(name)`. Theme Save persists live-applied colors (including optional `accent`). Refuses empty or built-in ids.
- **Delete** — only when `isUser(id)`; falls back to `conway` / `classic`.
- **Discard** — not a button; closing a pane alone does not Discard; reopening resets drafts from applied state via `syncDraftForPane`.

## Testing strategy for this area

- `userdata` serialize/parse — pure Lua unit tests (no LÖVE), same pattern as `rules`/`patterns` specs. See [`11-testing-and-ci.md`](11-testing-and-ci.md).

## Planned files

| File | Status | Phase |
|------|--------|-------|
| `src/userdata.lua` | exists | Phase 3 ✓ |
| `tests/userdata_spec.lua` | exists | Phase 3 ✓ |

## TODO tracking

### Phase 3 ✓
- [x] **Phase 3** — Userspace save/load (`src/userdata.lua`; merged catalogs)
- [x] Add more built-in rule presets beyond `conway`, `ant_colony` → userspace covers custom presets instead of expanding built-ins
