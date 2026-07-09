# MoonScript Experiment

Branch `moonscript` — full logic conversion from Lua to idiomatic MoonScript with a compile-before-run workflow. **Not intended to merge to `main` or block Phase 3** unless evaluation is strongly positive.

## Workflow

```text
*.moon (source, committed)  →  bin/compile (moonc)  →  *.lua (generated, gitignored)
                                                              ↓
                                                    lua tests/run.lua  /  love .
```

- **Source:** `main.moon`, `conf.moon`, `src/**/*.moon`, `tests/**/*.moon`
- **Unchanged:** `patterns/*.lua` (data), `patterns/*.rle`
- **Commands:** `bin/compile` · `bin/check` (compile + 11 specs) · `bin/run` (compile + LÖVE)
- **Toolchain:** `luarocks install moonscript` (provides `moonc`); `.envrc` adds `~/.luarocks/bin` to PATH

## Readability

| Metric | Lua (`main`) | Moon (this branch) |
|--------|--------------|-------------------|
| Logic + tests LOC | ~3,400 | ~2,420 (−29%) |
| Nesting (typical module) | 2–4 levels | 1–3 levels with `unless` / early `return` |
| Module boilerplate | `local M = {}` + `return M` per file | `return { fn: fn, ... }` at bottom |

**Wins**

- **Fat arrows and `return unless`** shrink guard-heavy code (`playback.update`, pane hit tests, RLE parsing).
- **Table literals** (`rows: 40`, `phase: PHASE_IDLE`) read cleaner than Lua's `key = value` in config/session.
- **String interpolation** (`"Rule: #{activeRule.rulestring}"`) replaces `string.format` noise in status bar chips.
- **UI layout** (rule/theme panes) benefits from inline table fields for button/field structs.

**Losses / friction**

- **Multi-line table returns after assignments** are a footgun: `previewSec, commitSec = ...` followed by unbraced `phase: ...` lines compiles as separate statements, not a return table. Explicit `{ ... }` blocks are required.
- **`export` keyword** did not emit `return` tables in our `moonc 0.6` setup; explicit `return { ... }` at module end is clearer anyway.
- **List comprehensions** with `1..n` compile to invalid `for _ in 1..n` in Lua; numeric `for row = 1, rows` is safer.
- **Stack traces** point at generated `.lua` line numbers, not `.moon` sources.

## Ergonomics

| Area | Verdict |
|------|---------|
| Compile step | ~1s locally; acceptable for `check`/`run`, adds CI `luarocks install moonscript` |
| LÖVE globals | Fine with `love.load = ->` assignment style |
| Release packaging | Pre-compile is correct for `.love` zips (no moonloader at runtime) |
| Editor support | Weaker than Lua (no LÖVE stubs on `.moon` without plugins) |
| Debugging | Step through generated Lua; map back to `.moon` manually |

## Quality

Idioms reduced boilerplate without changing behavior — all **11 specs pass** unchanged semantically.

Representative comparisons:

### `src/grid.moon` — simulation core

Grid init uses explicit numeric loops (comprehensions avoided). `countNeighbors` uses `unless dRow == 0 and dCol == 0` instead of nested `if`. Toroidal logic unchanged.

### `src/ui/panes/theme_pane.moon` — UI layout

Preset grid + color fields stay readable; Moon table literals for `fields` entries match how the Lua version built dicts, with less `table.insert` ceremony.

### `main.moon` — LÖVE entry

`love.load = ->`, `love.keypressed = (key) ->`, and local helpers with `!` call syntax (`syncFastMode!`) compress the 330-line entry file noticeably. Multi-arg `statusbar.draw(...)` calls must stay on one line (no bare line continuations).

## Verdict

**Hybrid / keep Lua on `main`.**

MoonScript is pleasant for UI and config-heavy modules and trims LOC, but the compile step, debug indirection, and Moon-specific pitfalls (table return parsing, `export` behavior, range comprehensions) outweigh benefits for a small LÖVE game where plain Lua is already working well and CI/release are Lua-native.

**Cherry-pick candidates if revisiting:** `playback.moon`, `step_animation.moon`, `layout.moon` — small pure modules where Moon syntax shines without LÖVE coupling.

**Do not merge wholesale** unless the team commits to MoonScript tooling in CI, release, and editor setup long term.

## Side-by-side notes

See git history on this branch for full diffs. Pattern data (`patterns/glider.lua`, etc.) deliberately left as plain Lua per experiment scope.
