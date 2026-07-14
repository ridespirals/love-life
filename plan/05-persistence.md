# Userspace persistence (Phase 3)

Covers saving/loading user-created rules, themes, and (later) patterns to the LÖVE save directory, and merging them with built-in catalogs.

See [`README.md`](README.md) for the cross-area roadmap. Depends on [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md) (Save/Delete UI lands on the existing rule/theme panes) and [`01-simulation-and-patterns.md`](01-simulation-and-patterns.md) (catalog merge extends `src/rules.lua`/`src/patterns.lua`). Feeds [`06-pattern-picker-and-drawing.md`](06-pattern-picker-and-drawing.md) (Phase 4 pattern save).

**Status:** next up — not started.

## Development order

1. **3a — `src/userdata.lua`**: persistence API + catalog merge + unit tests.
2. **3b — Save UI**: Save / Delete buttons on rule + theme panes (theme has no Apply — Save persists the live-applied draft; rule still Apply then Save).
---

### Phase 3 — Userspace save/load for rules and themes

**Delivers:** Save custom rule/theme to save directory; merged catalogs.

| File | Work |
|------|------|
| `src/userdata.lua` | IO + serialization |
| `src/rules.lua` / `src/themes.lua` | Load user presets |
| Rule/Theme panes | Save / Delete buttons, name field |
| `tests/userdata_spec.lua` | Round-trip serialize tests |

**Checkpoint:** create custom theme, quit, relaunch, still listed.

## Design details

### Userspace layout

All user-created assets live under the LÖVE save directory (shareable, outside the `.love` bundle):

```
<saveDirectory>/
  patterns/<id>.lua      # { id, name, cells = {{col,row}, ...} }
  rules/<id>.lua         # { id, name, rulestring = "B3/S23" }
  themes/<id>.lua        # { name, alive, dead, grid, background, accent? } hex strings
```

New module: `src/userdata.lua`
- `getBasePath()` → `love.filesystem.getSaveDirectory() .. "/..."`
- `list(type)`, `load(type, id)`, `save(type, id, data)`, `delete(type, id)`
- Pure-Lua serialization helpers (testable without LÖVE) + thin `love.filesystem` IO wrapper

**Catalog merge:** extend `src/patterns.lua`, `src/rules.lua`, `src/themes.lua` (see [`01-simulation-and-patterns.md`](01-simulation-and-patterns.md), [`02-rendering-and-animation.md`](02-rendering-and-animation.md)):
- Built-ins first, then user entries from save dir
- `list()` returns merged ids; `get(id)` checks built-in → bundled RLE → user file

### Save/Discard semantics

See [`04-ui-shell-and-panes.md`](04-ui-shell-and-panes.md) "Draft vs saved state" for the full commit/Save/Discard framework this phase implements:
- **Save** — write the currently applied draft to userspace; assign stable `id` (slug from name). Theme Save persists the live-applied colors (including optional `accent`); no separate Apply step.
- **Discard** — revert draft fields to last applied/saved state (closing a pane alone does not Discard).

## Testing strategy for this area

- `userdata` serialize/parse — pure Lua unit tests (no LÖVE), same pattern as `rules`/`patterns` specs. See [`11-testing-and-ci.md`](11-testing-and-ci.md).

## Planned files

| File | Status | Phase |
|------|--------|-------|
| `src/userdata.lua` | planned | Phase 3 |
| `tests/userdata_spec.lua` | planned | Phase 3 |

## TODO tracking

### Phase 3 (not started)
- [ ] **Phase 3** — Userspace save/load (`src/userdata.lua`; merged catalogs)
- [ ] Add more built-in rule presets beyond `conway`, `ant_colony` → userspace covers custom presets instead of expanding built-ins
