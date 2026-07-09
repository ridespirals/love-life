assert = require "tests.assert"
rules = require "src.rules"
themes = require "src.themes"
session = require "src.session"
rule_pane = require "src.ui.panes.rule_pane"
theme_pane = require "src.ui.panes.theme_pane"
test = require("tests.spec_helper").test

test "fromRulestring builds custom preset", ->
  rule = rules.fromRulestring "B3/S23"
  assert.equal rule.name, "custom"
  assert.equal rule.rulestring, "B3/S23"
  assert.isTrue rule.birth[3]

test "tryFromRulestring rejects invalid input", ->
  assert.equal rules.tryFromRulestring("bad"), nil
  assert.isTrue rules.tryFromRulestring("B3/S234") ~= nil

test "colorsToHex round-trips preset colors", ->
  classic = themes.get "classic"
  hex = themes.colorsToHex classic
  assert.equal hex.alive, "#ffffff"
  assert.equal hex.dead, "#000000"

test "tryBuild accepts valid hex colors", ->
  built = themes.tryBuild {
    name: "custom", alive: "#ffffff", dead: "#000000"
    grid: "#808080", background: "#000000"
  }
  assert.equal built.name, "custom"
  assert.equal themes.toHex(built.alive), "#ffffff"

test "tryBuild rejects invalid hex colors", ->
  assert.equal themes.tryBuild({
    alive: "nope", dead: "#000", grid: "#000", background: "#000"
  }), nil

test "resetRuleDraft copies active rule", ->
  state = session.create ruleId: "conway"
  conway = rules.get "conway"
  session.resetRuleDraft state, conway
  assert.equal state.draftRulePresetId, "conway"
  assert.equal state.draftRuleString, "B3/S23"

test "rule_pane apply uses draft rulestring", ->
  state = session.create ruleId: "conway"
  state.draftRuleString = "B3/S234"
  rule = rule_pane.apply state
  assert.equal rule.rulestring, "B3/S234"

test "resetThemeDraft carries preset accent into draft colors", ->
  state = session.create themeId: "monokai"
  monokai = themes.get "monokai"
  session.resetThemeDraft state, monokai, themes
  assert.equal state.draftThemeColors.accent, themes.toHex(monokai.accent)

test "theme_pane apply preserves accent from draft", ->
  state = session.create themeId: "monokai"
  session.resetThemeDraft state, themes.get("monokai"), themes
  built = theme_pane.apply state
  assert.isTrue built.accent ~= nil

test "theme_pane apply omits accent when draft field is blank", ->
  state = session.create themeId: "classic"
  session.resetThemeDraft state, themes.get("classic"), themes
  state.draftThemeColors.accent = ""
  built = theme_pane.apply state
  assert.equal built.accent, nil

test "theme_pane measure wraps the full theme catalog under a bounded width", ->
  w, h = theme_pane.measure paneWidth: 360
  assert.isTrue w <= 520
  assert.isTrue h > 0
