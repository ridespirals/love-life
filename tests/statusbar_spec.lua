local assert = require("tests.assert")
local statusbar = require("src.ui.statusbar")
local specHelper = require("tests.spec_helper")
local test = specHelper.test
local withLoveGraphicsMock = specHelper.withLoveGraphicsMock

local config = {
  statusBarHeight = 28,
}

test("getButtons returns four controls with expected ids", function()
  withLoveGraphicsMock({ width = 720, height = 508 }, function()
    local buttons = statusbar.getButtons(config, false)
    assert.equal(#buttons, 4)
    assert.equal(buttons[1].id, "play")
    assert.equal(buttons[2].id, "pause")
    assert.equal(buttons[3].id, "step")
    assert.equal(buttons[4].id, "restart")
  end)
end)

test("fastMode changes play label only", function()
  withLoveGraphicsMock({ width = 720, height = 508 }, function()
    local normal = statusbar.getButtons(config, false)
    local fast = statusbar.getButtons(config, true)

    assert.equal(normal[1].label, "Play")
    assert.equal(fast[1].label, "Play +")
    assert.equal(normal[1].x, fast[1].x)
    assert.equal(normal[1].y, fast[1].y)
    assert.equal(normal[1].w, fast[1].w)
    assert.equal(normal[1].h, fast[1].h)
  end)
end)

test("hitTestButton returns id inside button rect", function()
  withLoveGraphicsMock({ width = 720, height = 508 }, function()
    local buttons = statusbar.getButtons(config, false)
    local play = buttons[1]

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
    local play = buttons[1]

    assert.equal(
      statusbar.hitTestButton(config, play.x + 1, play.y + 1, true),
      "play"
    )
  end)
end)
