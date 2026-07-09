local assert = require("tests.assert")
local rules = require("src.rules")
local themes = require("src.themes")
local session = require("src.session")
local rule_pane = require("src.ui.panes.rule_pane")
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
