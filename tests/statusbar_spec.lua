local assert = require("tests.assert")
local statusbar = require("src.ui.statusbar")
local specHelper = require("tests.spec_helper")
local test = specHelper.test
local withLoveGraphicsMock = specHelper.withLoveGraphicsMock

local config = {
  statusBarHeight = 28,
}

local world = {
  rows = 40,
  cols = 60,
}

local theme = {
  name = "solarized",
}

local activeRule = {
  rulestring = "B3/S23",
}

test("getButtons returns five controls with settings first", function()
  withLoveGraphicsMock({ width = 720, height = 508 }, function()
    local buttons = statusbar.getButtons(config, false)
    assert.equal(#buttons, 5)
    assert.equal(buttons[1].id, "settings")
    assert.equal(buttons[2].id, "play")
    assert.equal(buttons[3].id, "pause")
    assert.equal(buttons[4].id, "step")
    assert.equal(buttons[5].id, "restart")
  end)
end)

test("fastMode changes play label only", function()
  withLoveGraphicsMock({ width = 720, height = 508 }, function()
    local normal = statusbar.getButtons(config, false)
    local fast = statusbar.getButtons(config, true)

    assert.equal(normal[2].label, "Play")
    assert.equal(fast[2].label, "Play +")
    assert.equal(normal[2].x, fast[2].x)
    assert.equal(normal[2].y, fast[2].y)
    assert.equal(normal[2].w, fast[2].w)
    assert.equal(normal[2].h, fast[2].h)
  end)
end)

test("hitTestButton returns id inside button rect", function()
  withLoveGraphicsMock({ width = 720, height = 508 }, function()
    local buttons = statusbar.getButtons(config, false)
    local play = buttons[2]

    assert.equal(
      statusbar.hitTestButton(config, play.x + 1, play.y + 1, false),
      "play"
    )
    assert.equal(statusbar.hitTestButton(config, 0, 0, false), nil)
  end)
end)

test("hitTestButton accepts fastMode for label parity", function()
  withLoveGraphicsMock({ width = 720, height = 508 }, function()
    local buttons = statusbar.getButtons(config, true)
    local play = buttons[2]

    assert.equal(
      statusbar.hitTestButton(config, play.x + 1, play.y + 1, true),
      "play"
    )
  end)
end)

test("getChips includes pattern and maps size to settings pane", function()
  withLoveGraphicsMock({ width = 720, height = 508 }, function()
    local chips = statusbar.getChips(world, theme, config, activeRule, 3, "lifeview")
    assert.equal(#chips, 5)
    assert.equal(chips[1].paneId, "rule")
    assert.equal(chips[2].paneId, "theme")
    assert.equal(chips[3].paneId, "pattern")
    assert.equal(chips[4].paneId, "settings")
    assert.equal(chips[5].paneId, nil)
    assert.equal(chips[5].clickable, false)
  end)
end)

test("hitTestChip returns pane id for clickable chips", function()
  withLoveGraphicsMock({ width = 720, height = 508 }, function()
    local chips = statusbar.getChips(world, theme, config, activeRule, 0, "glider")
    local rule = chips[1]
    assert.equal(
      statusbar.hitTestChip(world, theme, config, activeRule, 0, "glider", rule.x + 1, rule.y + 1),
      "rule"
    )
    local gen = chips[5]
    assert.equal(
      statusbar.hitTestChip(world, theme, config, activeRule, 0, "glider", gen.x + 1, gen.y + 1),
      nil
    )
  end)
end)
