local assert = require("tests.assert")
local themes = require("src.themes")
local specHelper = require("tests.spec_helper")
local test = specHelper.test

test("list includes built-in vim imports", function()
  local names = themes.list()
  assert.isTrue(#names >= 20)
  assert.isTrue(names[1] < names[#names])
  local found = {}
  for _, name in ipairs(names) do
    found[name] = true
  end
  assert.isTrue(found.classic)
  assert.isTrue(found.monokai)
  assert.isTrue(found.gruvbox)
  assert.isTrue(found.synthwave)
end)

test("get returns theme with color channels and vim accent", function()
  local theme = themes.get("nord")
  assert.equal(theme.name, "nord")
  assert.equal(#theme.alive, 3)
  assert.equal(#theme.dead, 3)
  assert.equal(#theme.grid, 3)
  assert.equal(#theme.background, 3)
  assert.equal(#theme.accent, 3)
end)

test("extrusionShadow uses accent when present", function()
  local theme = themes.get("monokai")
  local tinted = themes.extrusionShadow(theme, theme.alive, true)
  local plain = themes.extrusionShadow({}, theme.alive, true)
  assert.isTrue(
    tinted[1] ~= plain[1] or tinted[2] ~= plain[2] or tinted[3] ~= plain[3]
  )
end)

test("next and prev wrap around sorted theme names", function()
  local names = themes.list()
  local first = names[1]
  local last = names[#names]
  assert.equal(themes.prev(first), last)
  assert.equal(themes.next(last), first)
  assert.equal(themes.next(themes.get("classic").name), themes.next("classic"))
end)

test("skipped notes cover non-importable popular schemes", function()
  local skipped = themes.skipped()
  assert.isTrue(#skipped >= 3)
  local names = {}
  for _, entry in ipairs(skipped) do
    names[entry.name] = entry.reason
  end
  assert.isTrue(names.ayu)
  assert.isTrue(names.desert)
end)
