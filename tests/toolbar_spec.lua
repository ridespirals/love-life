local assert = require("tests.assert")
local toolbar = require("src.ui.toolbar")
local test = require("tests.spec_helper").test

local config = {
  toolbarMargin = 12,
  toolbarButtonSize = 32,
}

test("getButtons lays out pan draw zoom_in zoom_out", function()
  local panel = toolbar.getButtons(config)
  assert.equal(#panel.buttons, 4)
  assert.equal(panel.buttons[1].id, "pan")
  assert.equal(panel.buttons[2].id, "draw")
  assert.equal(panel.buttons[3].id, "zoom_in")
  assert.equal(panel.buttons[4].id, "zoom_out")
  assert.equal(panel.x, 12)
  assert.equal(panel.y, 12)
end)

test("hitTest returns tool id inside button", function()
  local panel = toolbar.getButtons(config)
  local pan = panel.buttons[1]
  assert.equal(toolbar.hitTest(config, pan.x + 2, pan.y + 2), "pan")
  assert.equal(toolbar.hitTest(config, pan.x + pan.w + 8, pan.y + 2), "draw")
end)

test("hitTest returns panel for chrome and nil outside", function()
  local panel = toolbar.getButtons(config)
  assert.equal(toolbar.hitTest(config, panel.x + 1, panel.y + 1), "panel")
  assert.equal(toolbar.hitTest(config, 0, 0), nil)
  assert.equal(toolbar.hitTest(config, 400, 400), nil)
end)

test("contains is true over panel bounds", function()
  local panel = toolbar.getButtons(config)
  assert.isTrue(toolbar.contains(config, panel.x + 1, panel.y + 1))
  assert.isFalse(toolbar.contains(config, 0, 0))
end)
