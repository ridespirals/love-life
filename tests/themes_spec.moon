assert = require "tests.assert"
themes = require "src.themes"
test = require("tests.spec_helper").test

test "list includes built-in vim imports", ->
  names = themes.list!
  assert.isTrue #names >= 20
  assert.isTrue names[1] < names[#names]
  found = {}
  for _, name in ipairs names
    found[name] = true
  assert.isTrue found.classic
  assert.isTrue found.monokai
  assert.isTrue found.gruvbox
  assert.isTrue found.synthwave

test "get returns theme with color channels and vim accent", ->
  theme = themes.get "nord"
  assert.equal theme.name, "nord"
  assert.equal #theme.alive, 3
  assert.equal #theme.dead, 3
  assert.equal #theme.grid, 3
  assert.equal #theme.background, 3
  assert.equal #theme.accent, 3

test "colorFromHex parses valid hex and rejects incomplete input", ->
  red = themes.colorFromHex "#ff0000"
  assert.equal themes.toHex(red), "#ff0000"
  assert.equal themes.colorFromHex("#ff"), nil
  assert.equal themes.colorFromHex(""), nil

test "extrusionShadow uses accent when present", ->
  theme = themes.get "monokai"
  tinted = themes.extrusionShadow theme, theme.alive, true
  plain = themes.extrusionShadow {}, theme.alive, true
  assert.isTrue tinted[1] ~= plain[1] or tinted[2] ~= plain[2] or tinted[3] ~= plain[3]

test "next and prev wrap around sorted theme names", ->
  names = themes.list!
  first = names[1]
  last = names[#names]
  assert.equal themes.prev(first), last
  assert.equal themes.next(last), first
  assert.equal themes.next(themes.get("classic").name), themes.next("classic")

test "skipped notes cover non-importable popular schemes", ->
  skipped = themes.skipped!
  assert.isTrue #skipped >= 3
  names = {}
  for _, entry in ipairs skipped
    names[entry.name] = entry.reason
  assert.isTrue names.ayu
  assert.isTrue names.desert
