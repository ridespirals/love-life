assert = require "tests.assert"
statusbar = require "src.ui.statusbar"
specHelper = require "tests.spec_helper"
test = specHelper.test
withLoveGraphicsMock = specHelper.withLoveGraphicsMock

config = statusBarHeight: 28

world = rows: 40, cols: 60
theme = name: "solarized"
activeRule = rulestring: "B3/S23"

test "getButtons returns five controls with settings first", ->
  withLoveGraphicsMock { width: 720, height: 508 }, ->
    buttons = statusbar.getButtons config, false
    assert.equal #buttons, 5
    assert.equal buttons[1].id, "settings"
    assert.equal buttons[2].id, "play"
    assert.equal buttons[3].id, "pause"
    assert.equal buttons[4].id, "step"
    assert.equal buttons[5].id, "restart"

test "fastMode changes play label only", ->
  withLoveGraphicsMock { width: 720, height: 508 }, ->
    normal = statusbar.getButtons config, false
    fast = statusbar.getButtons config, true
    assert.equal normal[2].label, "Play"
    assert.equal fast[2].label, "Play +"
    assert.equal normal[2].x, fast[2].x
    assert.equal normal[2].y, fast[2].y
    assert.equal normal[2].w, fast[2].w
    assert.equal normal[2].h, fast[2].h

test "hitTestButton returns id inside button rect", ->
  withLoveGraphicsMock { width: 720, height: 508 }, ->
    buttons = statusbar.getButtons config, false
    play = buttons[2]
    assert.equal statusbar.hitTestButton(config, play.x + 1, play.y + 1, false), "play"
    assert.equal statusbar.hitTestButton(config, 0, 0, false), nil

test "hitTestButton accepts fastMode for label parity", ->
  withLoveGraphicsMock { width: 720, height: 508 }, ->
    buttons = statusbar.getButtons config, true
    play = buttons[2]
    assert.equal statusbar.hitTestButton(config, play.x + 1, play.y + 1, true), "play"

test "getChips includes pattern and maps size to settings pane", ->
  withLoveGraphicsMock { width: 720, height: 508 }, ->
    chips = statusbar.getChips world, theme, config, activeRule, 3, "lifeview"
    assert.equal #chips, 5
    assert.equal chips[1].paneId, "rule"
    assert.equal chips[2].paneId, "theme"
    assert.equal chips[3].paneId, "pattern"
    assert.equal chips[4].paneId, "settings"
    assert.equal chips[5].paneId, nil
    assert.equal chips[5].clickable, false

test "hitTestChip returns pane id for clickable chips", ->
  withLoveGraphicsMock { width: 720, height: 508 }, ->
    chips = statusbar.getChips world, theme, config, activeRule, 0, "glider"
    rule = chips[1]
    assert.equal statusbar.hitTestChip(
      world, theme, config, activeRule, 0, "glider", rule.x + 1, rule.y + 1
    ), "rule"
    gen = chips[5]
    assert.equal statusbar.hitTestChip(
      world, theme, config, activeRule, 0, "glider", gen.x + 1, gen.y + 1
    ), nil
