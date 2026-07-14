local assert = require("tests.assert")
local rules = require("src.rules")
local themes = require("src.themes")
local session = require("src.session")
local rule_pane = require("src.ui.panes.rule_pane")
local theme_pane = require("src.ui.panes.theme_pane")
local test = require("tests.spec_helper").test

test("fromRulestring builds custom preset", function()
  local rule = rules.fromRulestring("B3/S23")
  assert.equal(rule.name, "custom")
  assert.equal(rule.rulestring, "B3/S23")
  assert.isTrue(rule.birth[3])
end)

test("tryFromRulestring rejects invalid input", function()
  assert.equal(rules.tryFromRulestring("bad"), nil)
  assert.isTrue(rules.tryFromRulestring("B3/S234") ~= nil)
end)

test("colorsToHex round-trips preset colors", function()
  local classic = themes.get("classic")
  local hex = themes.colorsToHex(classic)
  assert.equal(hex.alive, "#ffffff")
  assert.equal(hex.dead, "#000000")
end)

test("tryBuild accepts valid hex colors", function()
  local built = themes.tryBuild({
    name = "custom",
    alive = "#ffffff",
    dead = "#000000",
    grid = "#808080",
    background = "#000000",
  })
  assert.equal(built.name, "custom")
  assert.equal(themes.toHex(built.alive), "#ffffff")
end)

test("tryBuild rejects invalid hex colors", function()
  assert.equal(themes.tryBuild({ alive = "nope", dead = "#000", grid = "#000", background = "#000" }), nil)
end)

test("resetRuleDraft copies active rule", function()
  local state = session.create({ ruleId = "conway" })
  local conway = rules.get("conway")
  session.resetRuleDraft(state, conway)
  assert.equal(state.draftRulePresetId, "conway")
  assert.equal(state.draftRuleString, "B3/S23")
end)

test("rule_pane apply uses draft rulestring", function()
  local state = session.create({ ruleId = "conway" })
  state.draftRuleString = "B3/S234"
  local rule = rule_pane.apply(state)
  assert.equal(rule.rulestring, "B3/S234")
end)

test("resetThemeDraft carries preset accent into draft colors", function()
  local state = session.create({ themeId = "monokai" })
  local monokai = themes.get("monokai")
  session.resetThemeDraft(state, monokai, themes)
  assert.equal(state.draftThemeColors.accent, themes.toHex(monokai.accent))
end)

test("theme_pane apply preserves accent from draft", function()
  local state = session.create({ themeId = "monokai" })
  session.resetThemeDraft(state, themes.get("monokai"), themes)
  local built = theme_pane.apply(state)
  assert.isTrue(built.accent ~= nil)
end)

test("theme_pane apply omits accent when draft field is blank", function()
  local state = session.create({ themeId = "classic" })
  session.resetThemeDraft(state, themes.get("classic"), themes)
  state.draftThemeColors.accent = ""
  local built = theme_pane.apply(state)
  assert.equal(built.accent, nil)
end)

test("theme_pane measure wraps the full theme catalog under a bounded width", function()
  local w, h = theme_pane.measure({ paneWidth = 360 })
  assert.isTrue(w <= 520)
  assert.isTrue(h > 0)
end)

test("theme_pane preset click returns apply_theme", function()
  local state = session.create({ themeId = "classic" })
  session.resetThemeDraft(state, themes.get("classic"), themes)
  local rect = { x = 0, y = 0, w = 480, h = 400 }
  local contentY = 10
  local action = theme_pane.mousepressed(rect, contentY, state, 20, contentY + 5)
  assert.equal(action, "apply_theme")
  assert.equal(state.draftThemePresetId, themes.list()[1])
end)

test("theme_pane color field click opens color picker", function()
  local state = session.create({ themeId = "classic" })
  session.resetThemeDraft(state, themes.get("classic"), themes)
  local rect = { x = 0, y = 0, w = 480, h = 600 }
  local contentY = 10
  local action = theme_pane.mousepressed(rect, contentY, state, 100, 160)
  assert.equal(action, "open_color_picker")
  assert.equal(state.colorPickField, "alive")
end)

test("theme_pane applyColorPick updates draft hex and marks custom", function()
  local state = session.create({ themeId = "classic" })
  session.resetThemeDraft(state, themes.get("classic"), themes)
  local color = require("src.color")
  theme_pane.applyColorPick(state, "alive", color.fromHex("#112233"))
  assert.equal(state.draftThemeColors.alive, "#112233")
  assert.equal(state.draftThemePresetId, "custom")
end)
